import Foundation

/// Fetches a 90-day daily binning of world M4.5+ earthquakes (USGS) and
/// solar flares (NASA DONKI), used by the seismic↔solar correlation
/// chart. Both feeds are hit in parallel and merged into one
/// `SeismicSolarCorrelation` keyed by UTC midnight.
///
/// Both upstreams are free and unauthenticated, except DONKI which
/// accepts `DEMO_KEY` (rate-limited to ~30 req/hr). When a user has
/// supplied their own NASA key in Settings we pass it through.
struct SeismicSolarCorrelationClient {
    let session: URLSession
    let userAgent: String
    let apiKey: String
    /// Window length in days. Default 90 matches the chart label; pulled
    /// out as a parameter so tests can shrink the window.
    let windowDays: Int

    init(session: URLSession = .shared,
         userAgent: String,
         apiKey: String,
         windowDays: Int = 90) {
        self.session = session
        self.userAgent = userAgent
        self.apiKey = apiKey.isEmpty ? "DEMO_KEY" : apiKey
        self.windowDays = windowDays
    }

    static let usgsQueryBase = "https://earthquake.usgs.gov/fdsnws/event/1/query"
    static let donkiBase = "https://api.nasa.gov/DONKI/FLR"

    /// Returns nil on total failure; partial successes still return a
    /// result with whichever series came back.
    func fetch() async -> SeismicSolarCorrelation? {
        let (start, end) = Self.window(days: windowDays, now: Date())

        async let quakeEvents: [(time: Date, magnitude: Double)] =
            (try? await fetchQuakes(start: start, end: end)) ?? []
        async let flares: [(time: Date, fluxLog10: Double)] = (try? await fetchFlares(
            start: start, end: end
        )) ?? []

        let quakes = await quakeEvents
        let flareEvents = await flares
        if quakes.isEmpty && flareEvents.isEmpty { return nil }

        let bins = Self.bin(
            quakes: quakes,
            flareEvents: flareEvents,
            start: start,
            end: end
        )
        return SeismicSolarCorrelation(fetchedAt: Date(), days: bins)
    }

    // MARK: - USGS

    /// Returns (event time, magnitude). Magnitude is needed to color the
    /// chart bar by the day's strongest event; counts alone would lose
    /// that information.
    func fetchQuakes(start: Date, end: Date)
    async throws -> [(time: Date, magnitude: Double)] {
        let df = ISO8601DateFormatter()
        var c = URLComponents(string: Self.usgsQueryBase)!
        c.queryItems = [
            URLQueryItem(name: "format", value: "geojson"),
            URLQueryItem(name: "starttime", value: df.string(from: start)),
            URLQueryItem(name: "endtime", value: df.string(from: end)),
            URLQueryItem(name: "minmagnitude", value: "4.5"),
            URLQueryItem(name: "orderby", value: "time"),
        ]
        guard let url = c.url else { throw HTTPError.invalidURL }
        let data = try await session.getData(
            from: url, userAgent: userAgent, timeout: 20
        )
        guard
            let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let features = payload["features"] as? [[String: Any]]
        else { return [] }
        return features.compactMap { f -> (Date, Double)? in
            guard let props = f["properties"] as? [String: Any],
                  let ms = props["time"] as? Double,
                  let mag = props["mag"] as? Double else { return nil }
            return (Date(timeIntervalSince1970: ms / 1000), mag)
        }
    }

    // MARK: - DONKI flares

    func fetchFlares(start: Date, end: Date)
    async throws -> [(time: Date, fluxLog10: Double)] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")
        df.locale = Locale(identifier: "en_US_POSIX")
        var c = URLComponents(string: Self.donkiBase)!
        c.queryItems = [
            URLQueryItem(name: "startDate", value: df.string(from: start)),
            URLQueryItem(name: "endDate", value: df.string(from: end)),
            URLQueryItem(name: "api_key", value: apiKey),
        ]
        guard let url = c.url else { throw HTTPError.invalidURL }
        let data = try await session.getData(
            from: url, userAgent: userAgent, timeout: 20
        )
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return rows.compactMap { row -> (Date, Double)? in
            // peakTime when present, else beginTime — every flare has
            // at least one of the two.
            let raw = (row["peakTime"] as? String) ?? (row["beginTime"] as? String)
            guard let raw, let t = Self.parseTime(raw),
                  let cls = row["classType"] as? String,
                  let flux = Self.flux(forClassType: cls), flux > 0
            else { return nil }
            // Earth-directed filter: drop flares whose source region is
            // outside the ±45° geoeffective cone of the central meridian,
            // and drop entries with no usable source location at all.
            // X-rays from limb flares technically reach Earth but the
            // associated CME / proton flux that "hits" us only comes from
            // Earth-facing eruptions.
            guard let loc = row["sourceLocation"] as? String,
                  Self.isEarthDirected(sourceLocation: loc)
            else { return nil }
            return (t, log10(flux))
        }
    }

    /// Returns true when the heliographic source location is on the
    /// Earth-facing side of the disk and within ±45° of the central
    /// meridian. Accepts the standard DONKI/NOAA notation
    /// (e.g. "N15W30", "S08E12", "C00W05"). Returns false for empty
    /// strings, off-disk events, or unparseable values.
    static func isEarthDirected(sourceLocation: String,
                                maxLongitudeDeg: Int = 45) -> Bool {
        guard let lon = parseLongitudeDeg(sourceLocation) else { return false }
        return abs(lon) <= maxLongitudeDeg
    }

    /// Pulls the signed longitude degrees out of a heliographic string
    /// like "S12E70" → -70 (east is negative by convention) or
    /// "N15W30" → +30. "C00W05" → +5. nil when the format doesn't match.
    static func parseLongitudeDeg(_ raw: String) -> Int? {
        let s = raw.uppercased().trimmingCharacters(in: .whitespaces)
        // Expect "<lat-letter><digits><lon-letter><digits>".
        // Find the longitude letter (E or W) — sometimes preceded by a
        // central "C" marker we can ignore.
        guard let lonIdx = s.firstIndex(where: { $0 == "E" || $0 == "W" })
        else { return nil }
        let lonLetter = s[lonIdx]
        let digits = s[s.index(after: lonIdx)...]
        guard let mag = Int(digits) else { return nil }
        return lonLetter == "E" ? -mag : mag
    }

    // MARK: - Binning

    static func bin(
        quakes: [(time: Date, magnitude: Double)],
        flareEvents: [(time: Date, fluxLog10: Double)],
        start: Date,
        end: Date
    ) -> [SeismicSolarCorrelation.DayBin] {
        let dayCount = max(1, Int(end.timeIntervalSince(start) / 86400) + 1)
        var quakeCounts = Array(repeating: 0, count: dayCount)
        var peakMag = Array(repeating: -Double.infinity, count: dayCount)
        var flareCounts = Array(repeating: 0, count: dayCount)
        var peakFlux = Array(repeating: -Double.infinity, count: dayCount)

        let startUTC = Self.utcMidnight(of: start)

        @inline(__always) func index(for t: Date) -> Int? {
            let i = Int(t.timeIntervalSince(startUTC) / 86400)
            return (0..<dayCount).contains(i) ? i : nil
        }

        for (t, mag) in quakes {
            if let i = index(for: t) {
                quakeCounts[i] += 1
                if mag > peakMag[i] { peakMag[i] = mag }
            }
        }
        for (t, logFlux) in flareEvents {
            if let i = index(for: t) {
                flareCounts[i] += 1
                if logFlux > peakFlux[i] { peakFlux[i] = logFlux }
            }
        }

        var bins: [SeismicSolarCorrelation.DayBin] = []
        bins.reserveCapacity(dayCount)
        for i in 0..<dayCount {
            let date = startUTC.addingTimeInterval(Double(i) * 86400)
            let mag: Double? = peakMag[i].isFinite ? peakMag[i] : nil
            let flux: Double? = peakFlux[i].isFinite ? peakFlux[i] : nil
            bins.append(SeismicSolarCorrelation.DayBin(
                date: date,
                quakeCount: quakeCounts[i],
                peakMagnitude: mag,
                flareCount: flareCounts[i],
                peakFlareFluxLog10: flux
            ))
        }
        return bins
    }

    // MARK: - Helpers

    static func window(days: Int, now: Date) -> (start: Date, end: Date) {
        let end = now
        let start = end.addingTimeInterval(-Double(days) * 86400)
        return (start, end)
    }

    static func utcMidnight(of date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.startOfDay(for: date)
    }

    /// GOES soft X-ray classification → peak flux (W/m², 1–8 Å).
    /// "M2.3" → 2.3e-5; "X1.0" → 1e-4; "C9.5" → 9.5e-6, etc.
    static func flux(forClassType classType: String) -> Double? {
        let s = classType.uppercased()
        guard let first = s.first else { return nil }
        let base: Double
        switch first {
        case "A": base = 1e-8
        case "B": base = 1e-7
        case "C": base = 1e-6
        case "M": base = 1e-5
        case "X": base = 1e-4
        default:  return nil
        }
        let rest = s.dropFirst()
        let mult = Double(rest) ?? 1.0
        return mult * base
    }

    private static let isoParser: ISO8601DateFormatter = {
        let p = ISO8601DateFormatter()
        p.formatOptions = [.withInternetDateTime]
        return p
    }()

    static func parseTime(_ s: String) -> Date? {
        if let d = isoParser.date(from: s) { return d }
        // DONKI sometimes emits "2026-05-19T12:48Z" without seconds.
        let alt = DateFormatter()
        alt.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        alt.timeZone = TimeZone(identifier: "UTC")
        alt.locale = Locale(identifier: "en_US_POSIX")
        if let d = alt.date(from: s) { return d }
        let altNoZ = DateFormatter()
        altNoZ.dateFormat = "yyyy-MM-dd'T'HH:mmX"
        altNoZ.timeZone = TimeZone(identifier: "UTC")
        altNoZ.locale = Locale(identifier: "en_US_POSIX")
        return altNoZ.date(from: s)
    }
}
