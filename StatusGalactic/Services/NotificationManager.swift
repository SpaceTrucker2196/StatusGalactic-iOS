import Foundation
import UserNotifications
import CoreLocation

@Observable
final class NotificationManager {
    static let goldenHourIdPrefix = "io.river.statusgalactic.goldenHour"
    static let astronomicalDuskIdPrefix = "io.river.statusgalactic.astroDusk"
    static let spaceWeatherIdPrefix = "io.river.statusgalactic.spaceWX"

    private static let goldenEnabledKey = "io.river.statusgalactic.notif.goldenEnabled"
    private static let astroEnabledKey = "io.river.statusgalactic.notif.astroEnabled"
    private static let scheduleDays = 14

    private static let auroraAlertsEnabledKey = "io.river.statusgalactic.notif.auroraEnabled"
    private static let stormAlertsEnabledKey = "io.river.statusgalactic.notif.stormEnabled"
    private static let auroraThresholdKey = "io.river.statusgalactic.notif.auroraThreshold"
    private static let stormMinLevelKey = "io.river.statusgalactic.notif.stormMinLevel"

    /// Per-alert "last fired" timestamp store. Keeps us from re-pinging a
    /// user every 5 minutes for the same ongoing storm.
    private static let lastFiredPrefix = "io.river.statusgalactic.notif.lastFired."
    private static let alertCooldown: TimeInterval = 90 * 60

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var goldenHourEnabled: Bool {
        didSet { UserDefaults.standard.set(goldenHourEnabled, forKey: Self.goldenEnabledKey) }
    }
    var astronomicalDuskEnabled: Bool {
        didSet { UserDefaults.standard.set(astronomicalDuskEnabled, forKey: Self.astroEnabledKey) }
    }
    var nextGoldenHour: Date?
    var nextAstroDusk: Date?

    /// Fire when local aurora probability crosses this value.
    var auroraAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(auroraAlertsEnabled, forKey: Self.auroraAlertsEnabledKey) }
    }
    var auroraThresholdPct: Int {
        didSet { UserDefaults.standard.set(auroraThresholdPct, forKey: Self.auroraThresholdKey) }
    }

    /// Fire when R/S/G storm scale (digit 1..5) reaches at least this level.
    var stormAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(stormAlertsEnabled, forKey: Self.stormAlertsEnabledKey) }
    }
    var stormMinLevel: Int {
        didSet { UserDefaults.standard.set(stormMinLevel, forKey: Self.stormMinLevelKey) }
    }

    init() {
        let defaults = UserDefaults.standard
        self.goldenHourEnabled = defaults.bool(forKey: Self.goldenEnabledKey)
        self.astronomicalDuskEnabled = defaults.bool(forKey: Self.astroEnabledKey)
        self.auroraAlertsEnabled = defaults.bool(forKey: Self.auroraAlertsEnabledKey)
        self.stormAlertsEnabled = defaults.bool(forKey: Self.stormAlertsEnabledKey)
        // Defaults: 30% aurora, G2/R2/S2 storm.
        let storedAurora = defaults.integer(forKey: Self.auroraThresholdKey)
        self.auroraThresholdPct = storedAurora == 0 ? 30 : storedAurora
        let storedStorm = defaults.integer(forKey: Self.stormMinLevelKey)
        self.stormMinLevel = storedStorm == 0 ? 2 : storedStorm
    }

    func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorization()
            return granted
        } catch {
            await refreshAuthorization()
            return false
        }
    }

    /// Re-plan notifications for the next 14 days at the given coordinates.
    func reschedule(latitude: Double, longitude: Double, timezone: TimeZone = .current) async {
        await refreshAuthorization()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            return
        }

        let center = UNUserNotificationCenter.current()

        // Clear any of our prior requests; leave third-party ones alone.
        let pending = await center.pendingNotificationRequests()
        let ours = pending.filter {
            $0.identifier.hasPrefix(Self.goldenHourIdPrefix)
                || $0.identifier.hasPrefix(Self.astronomicalDuskIdPrefix)
        }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ours)

        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())

        var soonestGolden: Date?
        var soonestAstro: Date?

        for offset in 0..<Self.scheduleDays {
            guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            let (_, sunset) = SunEvents.sunriseAndSunset(
                on: day,
                latitude: latitude,
                longitude: longitude,
                timezone: timezone
            )
            guard let sunset else { continue }

            // Golden hour evening: 30 min before sunset.
            if goldenHourEnabled {
                let goldenStart = sunset.addingTimeInterval(-30 * 60)
                if goldenStart > Date() {
                    let req = makeRequest(
                        id: "\(Self.goldenHourIdPrefix).\(offset)",
                        title: "Golden hour",
                        body: "Sun drops in about 30 minutes. Worth a look.",
                        fireDate: goldenStart
                    )
                    try? await center.add(req)
                    if soonestGolden == nil { soonestGolden = goldenStart }
                }
            }

            // Astronomical dusk: ~78 minutes after sunset (sun at -18°) at mid latitudes.
            // We compute this client-side as sunset + dynamic offset based on latitude.
            // For scheduling-only accuracy this is fine; precise events come from the
            // backend in the brief.
            if astronomicalDuskEnabled {
                let astroOffset = approximateAstronomicalDuskOffset(latitudeAbs: abs(latitude))
                let astroDusk = sunset.addingTimeInterval(astroOffset)
                if astroDusk > Date() {
                    let req = makeRequest(
                        id: "\(Self.astronomicalDuskIdPrefix).\(offset)",
                        title: "Astronomical dusk",
                        body: "Sky is fully dark. Set up the lens.",
                        fireDate: astroDusk
                    )
                    try? await center.add(req)
                    if soonestAstro == nil { soonestAstro = astroDusk }
                }
            }
        }

        nextGoldenHour = soonestGolden
        nextAstroDusk = soonestAstro
    }

    // MARK: - Space-weather alerts

    /// Inspect the latest brief and fire immediate notifications when the
    /// user's configured thresholds are crossed. Per-alert cooldown stops
    /// repeat firings of the same ongoing storm.
    func evaluateSpaceWeather(brief: Brief) async {
        await refreshAuthorization()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            return
        }

        if auroraAlertsEnabled, let aurora = brief.aurora,
           aurora.localProbabilityPct >= auroraThresholdPct {
            await fireIfCooled(
                key: "aurora",
                title: "Aurora at your location",
                body: "OVATION shows \(aurora.localProbabilityPct)% probability right now — peak \(aurora.globalMaxPct)% on the oval."
            )
        }

        if stormAlertsEnabled {
            // R-scale (radio blackout)
            if let level = Self.scaleLevel(brief.xRay?.rScale), level >= stormMinLevel {
                await fireIfCooled(
                    key: "radio_blackout",
                    title: "Radio blackout: R\(level)",
                    body: "Peak X-ray class \(brief.xRay?.peakClass24h ?? "?"). HF degraded on the sunlit side."
                )
            }
            // S-scale (solar radiation)
            if let level = Self.scaleLevel(brief.proton?.sScale), level >= stormMinLevel {
                await fireIfCooled(
                    key: "solar_radiation",
                    title: "Solar radiation storm: S\(level)",
                    body: String(format: "Proton flux %.0f pfu ≥10 MeV.", brief.proton?.fluxPfu ?? 0)
                )
            }
            // G-scale (geomagnetic) — derive from Kp.
            if let kp = brief.space?.kpIndex {
                let gString = SpaceWeatherForecastClient.gScaleString(forKp: kp)
                if let level = Self.scaleLevel(gString), level >= stormMinLevel {
                    await fireIfCooled(
                        key: "geomag",
                        title: "Geomagnetic storm: G\(level)",
                        body: String(format: "Kp %.1f. HF noisy; aurora pushing south.", kp)
                    )
                }
            }
        }
    }

    /// Extract the numeric severity from a NOAA scale string like "R3" / "G2".
    /// Returns nil for "X0" / unknown — we only alert on actual storms.
    static func scaleLevel(_ scale: String?) -> Int? {
        guard let scale, scale.count >= 2,
              let digit = scale.last.flatMap({ Int(String($0)) }),
              digit >= 1
        else { return nil }
        return digit
    }

    private func fireIfCooled(key: String, title: String, body: String) async {
        let defaults = UserDefaults.standard
        let storeKey = Self.lastFiredPrefix + key
        let lastFiredEpoch = defaults.double(forKey: storeKey)
        let now = Date().timeIntervalSince1970
        if lastFiredEpoch > 0 && (now - lastFiredEpoch) < Self.alertCooldown {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: "\(Self.spaceWeatherIdPrefix).\(key).\(Int(now))",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        do {
            try await UNUserNotificationCenter.current().add(req)
            defaults.set(now, forKey: storeKey)
        } catch {
            // Drop silently — alert delivery is best-effort.
        }
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ours = requests.filter {
                $0.identifier.hasPrefix(Self.goldenHourIdPrefix)
                    || $0.identifier.hasPrefix(Self.astronomicalDuskIdPrefix)
            }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ours)
        }
        nextGoldenHour = nil
        nextAstroDusk = nil
    }

    private func makeRequest(id: String, title: String, body: String, fireDate: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    /// Coarse approximation: time from sunset to sun at -18° (astronomical dusk).
    /// ~70-90 min at mid latitudes, longer near poles. Linear approximation good
    /// enough for scheduling — the brief shows the precise time.
    private func approximateAstronomicalDuskOffset(latitudeAbs: Double) -> TimeInterval {
        let baseMinutes = 78.0
        let extra = max(0, (latitudeAbs - 40) * 0.6) // grows toward poles
        return (baseMinutes + extra) * 60
    }
}
