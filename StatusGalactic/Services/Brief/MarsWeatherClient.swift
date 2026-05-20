import Foundation

/// Current Mars weather, scraped from JPL by the community-maintained MAAS2
/// proxy at maas2.apollorion.com.
///
/// Returns Curiosity's most recent Mars Science Laboratory REMS sol report.
/// The endpoint occasionally goes down; callers should treat failure as
/// "no Mars weather available" and continue.
struct MarsWeatherClient {
    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    static let url = URL(string: "https://maas2.apollorion.com/")!

    func fetchLatest() async throws -> MarsWeather {
        // Aggressively short timeout: this endpoint has gone offline more than
        // once, and we'd rather show no Mars card than hang the brief.
        let data = try await session.getData(from: Self.url, userAgent: userAgent, timeout: 5)
        do {
            return try JSONDecoder().decode(MAAS2Response.self, from: data).toMarsWeather()
        } catch {
            throw HTTPError.decoding(error)
        }
    }

    // MARK: - Wire format

    private struct MAAS2Response: Decodable {
        let sol: Int?
        let season: String?
        let terrestrial_date: String?
        let min_temp: Double?
        let max_temp: Double?
        let pressure: Double?
        let atmo_opacity: String?
        let sunrise: String?
        let sunset: String?

        func toMarsWeather() -> MarsWeather {
            MarsWeather(
                sol: sol ?? 0,
                season: season,
                terrestrialDate: terrestrial_date,
                minTempC: min_temp,
                maxTempC: max_temp,
                pressurePa: pressure,
                atmoOpacity: atmo_opacity,
                sunrise: sunrise,
                sunset: sunset
            )
        }
    }
}
