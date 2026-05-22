import Foundation

/// NOAA SWPC client: planetary Kp + 10.7 cm flux.
struct SWPCClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let kpURL = URL(string: "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json")!
    static let fluxURL = URL(string: "https://services.swpc.noaa.gov/products/summary/10cm-flux.json")!

    func fetchSpaceWeather() async throws -> SpaceWeather {
        async let kpTask = fetchKp()
        async let fluxTask = fetchFlux()
        let (kpAndTime, flux) = try await (kpTask, fluxTask)
        let (kp, observedAt) = kpAndTime

        // Treat a fully-empty result the same as a failed fetch — surfacing
        // a hollow SpaceWeather card with every number missing is worse
        // than hiding the section entirely.
        guard kp != nil || flux != nil else {
            throw HTTPError.decoding(NSError(
                domain: "swpc", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "no SWPC data"]
            ))
        }

        return SpaceWeather(
            solarFlux: flux,
            kpIndex: kp,
            kpStatus: kp.map(Self.kpStatus(_:)),
            auroraLikely: (kp ?? 0) >= 5,
            hfSummary: Self.hfSummary(flux: flux),
            observedAt: observedAt
        )
    }

    private func fetchKp() async throws -> (Double?, Date?) {
        let data = try await session.getData(from: Self.kpURL, userAgent: userAgent)
        let rows = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
        guard let last = rows.last else { return (nil, nil) }
        let kp = last["Kp"].flatMap { Self.parseDouble($0) }
        let tsString = last["time_tag"] as? String
        let date = tsString.flatMap { Self.parseSWPCDate($0) }
        return (kp, date)
    }

    private func fetchFlux() async throws -> Double? {
        let data = try await session.getData(from: Self.fluxURL, userAgent: userAgent)
        let parsed = try? JSONSerialization.jsonObject(with: data)
        if let arr = parsed as? [[String: Any]], let last = arr.last {
            return last["flux"].flatMap { Self.parseDouble($0) }
                ?? last["Flux"].flatMap { Self.parseDouble($0) }
        }
        if let dict = parsed as? [String: Any] {
            return dict["flux"].flatMap { Self.parseDouble($0) }
                ?? dict["Flux"].flatMap { Self.parseDouble($0) }
        }
        return nil
    }

    private static func parseDouble(_ any: Any) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) }
        return nil
    }

    private static func parseSWPCDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.date(from: s)
    }

    private static func kpStatus(_ kp: Double) -> String {
        switch kp {
        case ..<4:  return "quiet"
        case ..<5:  return "unsettled"
        case ..<6:  return "minor storm"
        case ..<7:  return "moderate storm"
        case ..<8:  return "strong storm"
        default:    return "severe storm"
        }
    }

    private static func hfSummary(flux: Double?) -> String? {
        guard let f = flux else { return nil }
        switch f {
        case 150...: return "Good across HF, 10-15m open during daylight"
        case 100..<150: return "Fair to good on low bands, marginal on 10-15m"
        case 80..<100: return "Workable on 80-20m, weak on higher bands"
        default: return "Poor: low bands only, MUF low"
        }
    }
}
