import Foundation
import UserNotifications
import CoreLocation

@Observable
final class NotificationManager {
    static let goldenHourIdPrefix = "io.river.statusgalactic.goldenHour"
    static let astronomicalDuskIdPrefix = "io.river.statusgalactic.astroDusk"

    private static let goldenEnabledKey = "io.river.statusgalactic.notif.goldenEnabled"
    private static let astroEnabledKey = "io.river.statusgalactic.notif.astroEnabled"
    private static let scheduleDays = 14

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var goldenHourEnabled: Bool {
        didSet { UserDefaults.standard.set(goldenHourEnabled, forKey: Self.goldenEnabledKey) }
    }
    var astronomicalDuskEnabled: Bool {
        didSet { UserDefaults.standard.set(astronomicalDuskEnabled, forKey: Self.astroEnabledKey) }
    }
    var nextGoldenHour: Date?
    var nextAstroDusk: Date?

    init() {
        let defaults = UserDefaults.standard
        self.goldenHourEnabled = defaults.bool(forKey: Self.goldenEnabledKey)
        self.astronomicalDuskEnabled = defaults.bool(forKey: Self.astroEnabledKey)
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
