import Foundation

/// api.weather.gov client. Two-step: GET /points/{lat},{lng} discovers the
/// 12-hourly and hourly forecast URLs, then both are fetched in parallel.
struct NWSClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let base = URL(string: "https://api.weather.gov")!

    func fetchEarthWeather(
        lat: Double,
        lng: Double,
        periods: Int = 6,
        hourlySampleCount: Int = 72
    ) async throws -> EarthWeather {
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

        // Fetch 12-hourly periods and hourly samples in parallel.
        async let twelveHourly: ForecastResponse = {
            let data = try await self.session.getData(from: forecastURL, userAgent: self.userAgent)
            return try Self.decoder.decode(ForecastResponse.self, from: data)
        }()
        async let hourlyTask: HourlyForecastResponse? = {
            guard let urlStr = pointsResp.properties.forecastHourly,
                  let url = URL(string: urlStr)
            else { return nil }
            let data = try await self.session.getData(from: url, userAgent: self.userAgent)
            return try Self.decoder.decode(HourlyForecastResponse.self, from: data)
        }()

        let fcResp = try await twelveHourly
        // Hourly is best-effort. A failure here shouldn't break the brief.
        let hourlyResp = try? await hourlyTask

        let mappedPeriods = fcResp.properties.periods.prefix(periods).map { p -> WeatherPeriod in
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

        let hourlySamples = Self.parseHourly(
            hourlyResp?.properties.periods ?? [],
            limit: hourlySampleCount
        )

        return EarthWeather(
            locationName: locationName,
            city: city,
            state: state,
            periods: Array(mappedPeriods),
            hourly: hourlySamples
        )
    }

    private static func parseHourly(
        _ raw: [HourlyForecastPeriod],
        limit: Int
    ) -> [HourlySample] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plainFormatter = ISO8601DateFormatter()
        plainFormatter.formatOptions = [.withInternetDateTime]

        func parseDate(_ s: String?) -> Date? {
            guard let s else { return nil }
            return formatter.date(from: s) ?? plainFormatter.date(from: s)
        }
        func parseWindSpeed(_ s: String?) -> Double? {
            guard let s else { return nil }
            // NWS hourly typically returns "15 mph" or "10 to 20 mph".
            let digits = s.split(separator: " ")
                .compactMap { Double($0) }
            return digits.last
        }

        return raw.prefix(limit).compactMap { p -> HourlySample? in
            guard let t = parseDate(p.startTime) else { return nil }
            return HourlySample(
                time: t,
                temperatureF: p.temperature.map(Double.init),
                dewpointC: p.dewpoint?.value,
                humidityPct: p.relativeHumidity?.value,
                windSpeedMph: parseWindSpeed(p.windSpeed),
                windDirection: p.windDirection,
                precipChancePct: p.probabilityOfPrecipitation?.value,
                shortForecast: p.shortForecast,
                isDaytime: p.isDaytime ?? true
            )
        }
    }

    private static let decoder: JSONDecoder = {
        JSONDecoder()
    }()

    // MARK: - Wire types

    private struct PointsResponse: Codable {
        let properties: PointsProperties
    }
    private struct PointsProperties: Codable {
        let forecast: String
        let forecastHourly: String?
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

    private struct HourlyForecastResponse: Codable {
        let properties: HourlyForecastProperties
    }
    private struct HourlyForecastProperties: Codable {
        let periods: [HourlyForecastPeriod]
    }
    private struct HourlyForecastPeriod: Codable {
        let startTime: String?
        let temperature: Int?
        let temperatureUnit: String?
        let isDaytime: Bool?
        let windSpeed: String?
        let windDirection: String?
        let shortForecast: String?
        let dewpoint: NumericValue?
        let relativeHumidity: NumericValue?
        let probabilityOfPrecipitation: NumericValue?
    }
    private struct NumericValue: Codable {
        let value: Double?
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
