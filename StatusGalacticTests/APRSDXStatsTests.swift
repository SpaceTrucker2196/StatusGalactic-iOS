import XCTest
@testable import StatusGalactic

final class HaversineTests: XCTestCase {

    /// La Crosse, WI to Key West, FL is ~2,300 km / ~1,430 mi (haversine).
    func testLaCrosseToKeyWest() {
        let km = haversineKm(
            lat1: 43.80, lng1: -91.20,
            lat2: 24.55, lng2: -81.78
        )
        XCTAssertEqual(km, 2_300, accuracy: 50)
    }

    /// Same point returns zero.
    func testZeroForSamePoint() {
        XCTAssertEqual(haversineKm(lat1: 0, lng1: 0, lat2: 0, lng2: 0), 0, accuracy: 0.001)
    }

    /// Halfway around the equator is ~20,000 km.
    func testAntipode() {
        let km = haversineKm(lat1: 0, lng1: 0, lat2: 0, lng2: 180)
        XCTAssertEqual(km, 20_015, accuracy: 100)
    }
}

final class APRSDXStatsTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "io.river.statusgalactic.tests.dx"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testBucketingByDay() {
        let store = APRSMessageStore(defaults: defaults)
        // Pick a reference on day 20 of some month so "5 days ago" stays in
        // the same calendar month.
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 6
        comps.day = 20
        comps.hour = 14
        let cal = Calendar(identifier: .gregorian)
        let reference = cal.date(from: comps)!

        store.upsertForTest(message(text: "today", from: "ABC", at: reference.addingTimeInterval(-3600),                       km: 500))
        store.upsertForTest(message(text: "month", from: "DEF", at: cal.date(byAdding: .day, value: -5, to: reference)!,       km: 1500))
        store.upsertForTest(message(text: "year",  from: "GHI", at: cal.date(byAdding: .month, value: -3, to: reference)!,     km: 3000))

        let stats = store.dxStats(myCallsign: "W9FJC", reference: reference, calendar: cal)
        XCTAssertEqual(stats.today?.callsign, "ABC")
        XCTAssertEqual(stats.month?.callsign, "DEF")
        XCTAssertEqual(stats.year?.callsign,  "GHI")
    }

    func testTodayWinsOverMonthOnSameDay() throws {
        let store = APRSMessageStore(defaults: defaults)
        let now = Date()

        store.upsertForTest(message(text: "near", from: "NEAR", at: now.addingTimeInterval(-1800), km: 100))
        store.upsertForTest(message(text: "far",  from: "FAR",  at: now.addingTimeInterval(-1000), km: 2500))

        let stats = store.dxStats(myCallsign: "W9FJC", reference: now)
        let today = try XCTUnwrap(stats.today)
        XCTAssertEqual(today.callsign, "FAR")
        XCTAssertEqual(today.distanceKm, 2500, accuracy: 0.001)
    }

    func testBulletinsIgnored() {
        let store = APRSMessageStore(defaults: defaults)
        store.upsertForTest(message(text: "huge bulletin", from: "ANY", to: "BLN1", at: Date(), km: 9999))
        XCTAssertNil(store.dxStats(myCallsign: "W9FJC").today)
    }

    func testOutgoingMessageCountsForDX() throws {
        let store = APRSMessageStore(defaults: defaults)
        let now = Date()

        // Outgoing W9FJC -> KJ7CMR at 2500 km. Should count as DX.
        store.upsertForTest(message(
            text: "test",
            from: "W9FJC",
            to: "KJ7CMR",
            at: now.addingTimeInterval(-1800),
            km: 2500,
            direction: .outgoing
        ))

        let stats = store.dxStats(myCallsign: "W9FJC", reference: now)
        let today = try XCTUnwrap(stats.today)
        XCTAssertEqual(today.callsign, "KJ7CMR")
        XCTAssertEqual(today.distanceKm, 2500, accuracy: 0.001)
    }

    private func message(
        text: String,
        from: String,
        to: String = "W9FJC",
        at: Date,
        km: Double,
        direction: APRSMessage.Direction = .incoming
    ) -> APRSMessage {
        APRSMessage(
            messageID: "test-\(from)-\(at.timeIntervalSince1970)",
            from: from,
            to: to,
            text: text,
            sentAt: at,
            direction: direction,
            acknowledged: false,
            partyLat: 0,
            partyLng: 0,
            distanceKm: km
        )
    }
}

// Test-only helper to upsert without going through the network path.
extension APRSMessageStore {
    func upsertForTest(_ msg: APRSMessage) { upsert(msg) }
}
