import XCTest
@testable import StatusGalactic

final class APRSBulletinClassificationTests: XCTestCase {

    func testCallsignsAreNotBulletins() {
        XCTAssertFalse(makeMessage(to: "W9FJC").isBulletin)
        XCTAssertFalse(makeMessage(to: "KJ7CMR").isBulletin)
        XCTAssertFalse(makeMessage(to: "K0ABC-7").isBulletin)
    }

    func testStandardBulletinDestinations() {
        XCTAssertTrue(makeMessage(to: "BLN1").isBulletin)
        XCTAssertTrue(makeMessage(to: "BLN23").isBulletin)
        XCTAssertTrue(makeMessage(to: "BLNFIRE").isBulletin)
        XCTAssertTrue(makeMessage(to: "ARL001").isBulletin)
        XCTAssertTrue(makeMessage(to: "ARL015").isBulletin)
        XCTAssertTrue(makeMessage(to: "NWS-LSX").isBulletin)
        XCTAssertTrue(makeMessage(to: "ALL").isBulletin)
    }

    func testCaseInsensitive() {
        XCTAssertTrue(makeMessage(to: "bln1").isBulletin)
        XCTAssertTrue(makeMessage(to: "arl001").isBulletin)
        XCTAssertTrue(makeMessage(to: "all").isBulletin)
    }

    private func makeMessage(to: String) -> APRSMessage {
        APRSMessage(
            messageID: "test-\(to)",
            from: "ANYONE",
            to: to,
            text: "test",
            sentAt: Date(),
            direction: .incoming,
            acknowledged: false
        )
    }
}

final class APRSMessageStoreThreadingTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "io.river.statusgalactic.tests.aprs"

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

    func testBulletinsExcludedFromThreads() {
        let store = APRSMessageStore(defaults: defaults)
        store.upsert(message(from: "KJ7CMR", to: "W9FJC", text: "hi", offset: 0))
        store.upsert(message(from: "N0ABC", to: "BLN1", text: "bulletin one", offset: 100))
        store.upsert(message(from: "W9FJC", to: "KJ7CMR", text: "hi back", offset: 200))

        let threads = store.threads(myCallsign: "W9FJC")
        XCTAssertEqual(threads.count, 1)
        XCTAssertEqual(threads.first?.partner, "KJ7CMR")
        XCTAssertEqual(threads.first?.messages.count, 2)
    }

    func testBulletinsSortedNewestFirst() {
        let store = APRSMessageStore(defaults: defaults)
        store.upsert(message(from: "N0ABC", to: "BLN1", text: "old",    offset: 0))
        store.upsert(message(from: "N0ABC", to: "BLN1", text: "newer",  offset: 100))
        store.upsert(message(from: "N0ABC", to: "BLN2", text: "newest", offset: 200))

        let bulletins = store.bulletins
        XCTAssertEqual(bulletins.count, 3)
        XCTAssertEqual(bulletins[0].text, "newest")
        XCTAssertEqual(bulletins[1].text, "newer")
        XCTAssertEqual(bulletins[2].text, "old")
    }

    func testThreadsSortedByLastActivity() {
        let store = APRSMessageStore(defaults: defaults)
        store.upsert(message(from: "PARTNER1", to: "W9FJC", text: "old",    offset: 0))
        store.upsert(message(from: "PARTNER2", to: "W9FJC", text: "newer",  offset: 100))
        store.upsert(message(from: "PARTNER3", to: "W9FJC", text: "newest", offset: 200))

        let threads = store.threads(myCallsign: "W9FJC")
        XCTAssertEqual(threads.map(\.partner), ["PARTNER3", "PARTNER2", "PARTNER1"])
    }

    private func message(from: String, to: String, text: String, offset: TimeInterval) -> APRSMessage {
        APRSMessage(
            messageID: "\(from)-\(to)-\(offset)",
            from: from,
            to: to,
            text: text,
            sentAt: Date(timeIntervalSince1970: 1_700_000_000 + offset),
            direction: from == "W9FJC" ? .outgoing : .incoming,
            acknowledged: false
        )
    }
}
