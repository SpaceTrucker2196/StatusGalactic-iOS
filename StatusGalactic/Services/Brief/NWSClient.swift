import Foundation

/// api.weather.gov client. Two-step: GET /points/{lat},{lng} → discover
/// forecast URL + relative location → GET that forecast.
struct NWSClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let base = URL(string: "https://api.weather.gov")!

    func fetchEarthWeather(lat: Double, lng: Double, periods: Int = 6) async throws -> EarthWeather {
        let coord = String(format: "%.4f,%.4f", lat, lng)
        let pointsURL = Self.base.appendingPathComponent("points/\(coord)")
        let pointsData = try await session.getData(from: pointsURL, userAgent: userAgent)
        let pointsResp = try Self.decoder.decode(PointsResponse.self, from: pointsData)

        guard let forecastURL = URL(string: pointsResp.properties.forecast) else {
            throw HTTPError.invalidURL
        }
        let rel = pointsResp.properties.relativeLocation?.properties
        let city = rel?.city
        let state = rel?.state
        let locationName = [city, state].compactMap { $0 }.joined(separator: ", ").nonEmpty

        let fcData = try await session.getData(from: forecastURL, userAgent: userAgent)
        let fcResp = try Self.decoder.decode(ForecastResponse.self, from: fcData)

        let mapped = fcResp.properties.periods.prefix(periods).map { p -> WeatherPeriod in
            let wind = [p.windSpeed, p.windDirection].compactMap { $0 }.joined(separator: " ").nonEmpty
            return WeatherPeriod(
                name: p.name,
                shortForecast: p.shortForecast ?? "",
                temperature: p.temperature,
                temperatureUnit: p.temperatureUnit ?? "F",
                isDaytime: p.isDaytime ?? true,
                wind: wind,
                detailedForecast: p.detailedForecast
            )
        }

        return EarthWeather(
            locationName: locationName,
            city: city,
            state: state,
            periods: Array(mapped)
        )
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Wire types

    private struct PointsResponse: Codable {
        let properties: PointsProperties
    }
    private struct PointsProperties: Codable {
        let forecast: String
        let relativeLocation: RelativeLocation?
    }
    private struct RelativeLocation: Codable {
        let properties: RelativeLocationProperties
    }
    private struct RelativeLocationProperties: Codable {
        let city: String?
        let state: String?
    }

    private struct ForecastResponse: Codable {
        let properties: ForecastProperties
    }
    private struct ForecastProperties: Codable {
        let periods: [ForecastPeriod]
    }
    private struct ForecastPeriod: Codable {
        let name: String
        let shortForecast: String?
        let detailedForecast: String?
        let temperature: Int?
        let temperatureUnit: String?
        let isDaytime: Bool?
        let windSpeed: String?
        let windDirection: String?
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
