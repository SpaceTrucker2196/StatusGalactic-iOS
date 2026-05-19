import XCTest
@testable import StatusGalactic

final class CallsignStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "io.river.statusgalactic.tests"

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

    func testAddNormalizesToUppercase() {
        let store = CallsignStore(defaults: defaults)
        let entry = store.add("w9fjc")
        XCTAssertEqual(entry?.call, "W9FJC")
        XCTAssertEqual(store.callsigns.count, 1)
    }

    func testAddIsIdempotent() {
        let store = CallsignStore(defaults: defaults)
        _ = store.add("W9FJC")
        let again = store.add("w9fjc")
        XCTAssertNil(again, "duplicate add should return nil")
        XCTAssertEqual(store.callsigns.count, 1)
    }

    func testEmptyAddRejected() {
        let store = CallsignStore(defaults: defaults)
        XCTAssertNil(store.add(""))
        XCTAssertNil(store.add("   "))
        XCTAssertTrue(store.callsigns.isEmpty)
    }

    func testRemoveByCall() {
        let store = CallsignStore(defaults: defaults)
        _ = store.add("W9FJC")
        _ = store.add("KJ7CMR")
        store.remove(call: "w9fjc")
        XCTAssertEqual(store.callsigns.map(\.call), ["KJ7CMR"])
    }

    func testRemoveByOffsets() {
        let store = CallsignStore(defaults: defaults)
        _ = store.add("W9FJC")
        _ = store.add("KJ7CMR")
        _ = store.add("N0CALL")
        store.remove(at: IndexSet(integer: 1))
        XCTAssertEqual(store.callsigns.map(\.call), ["W9FJC", "N0CALL"])
    }

    func testPersistsAcrossInstances() {
        let first = CallsignStore(defaults: defaults)
        _ = first.add("W9FJC", label: "Jeff", notes: "Base")

        let second = CallsignStore(defaults: defaults)
        XCTAssertEqual(second.callsigns.count, 1)
        XCTAssertEqual(second.callsigns.first?.call, "W9FJC")
        XCTAssertEqual(second.callsigns.first?.label, "Jeff")
        XCTAssertEqual(second.callsigns.first?.notes, "Base")
    }
}
