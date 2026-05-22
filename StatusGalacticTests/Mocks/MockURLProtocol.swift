import Foundation

/// Route-aware mock URL protocol. Tests register response handlers keyed
/// by request matchers; everything else 404s.
///
/// Failure modes the brief refresh needs to survive:
///   • empty 200 body
///   • garbage / not-JSON 200 body
///   • HTTP 4xx, 5xx
///   • outright connection failure (NSURLError)
///   • slow responses (timeouts)
///
/// All of those can be expressed by composing a `(URLRequest) -> (HTTPURLResponse, Data?)`
/// handler with a delay and/or a thrown `URLError`.
final class MockURLProtocol: URLProtocol {

    struct Route {
        let matcher: (URLRequest) -> Bool
        let delay: TimeInterval
        let handler: (URLRequest) throws -> (HTTPURLResponse, Data?)
    }

    nonisolated(unsafe) static var routes: [Route] = []
    nonisolated(unsafe) static var fallback: Route? = nil

    /// Reset between tests so prior registrations don't leak.
    static func reset() {
        routes.removeAll()
        fallback = nil
    }

    /// Register a route that matches when `predicate(request)` is true.
    static func register(
        when predicate: @escaping (URLRequest) -> Bool,
        delay: TimeInterval = 0,
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data?)
    ) {
        routes.append(Route(matcher: predicate, delay: delay, handler: handler))
    }

    /// Convenience: match every request by host substring.
    static func register(
        hostContaining substring: String,
        status: Int = 200,
        body: Data = Data(),
        headers: [String: String] = ["Content-Type": "application/json"],
        delay: TimeInterval = 0
    ) {
        register(when: { ($0.url?.host ?? "").contains(substring) }, delay: delay) { req in
            let r = HTTPURLResponse(
                url: req.url ?? URL(string: "https://mock.test")!,
                statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers
            )!
            return (r, body)
        }
    }

    /// Catch-all for routes nothing else matched. Useful for "every endpoint
    /// returns 200 empty" or "every endpoint times out" tests.
    static func setFallback(
        delay: TimeInterval = 0,
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data?)
    ) {
        fallback = Route(matcher: { _ in true }, delay: delay, handler: handler)
    }

    // MARK: - URLProtocol overrides

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let req = request
        let route = Self.routes.first(where: { $0.matcher(req) }) ?? Self.fallback
        guard let route else {
            // Default to 404 empty so unhandled URLs are visible failures.
            let resp = HTTPURLResponse(
                url: req.url ?? URL(string: "https://mock.test")!,
                statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let handler = route.handler
        let delay = route.delay
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            do {
                let (resp, data) = try handler(req)
                self.client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
                if let data, !data.isEmpty { self.client?.urlProtocol(self, didLoad: data) }
                self.client?.urlProtocolDidFinishLoading(self)
            } catch {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}
}

extension URLSession {
    /// Ephemeral session that routes every request through `MockURLProtocol`.
    /// Caller is responsible for registering routes / setting fallback.
    static func mock(timeoutInterval: TimeInterval = 4) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval
        return URLSession(configuration: config)
    }
}
