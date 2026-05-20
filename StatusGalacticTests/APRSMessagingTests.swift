import XCTest
@testable import StatusGalactic

final class APRSPasscodeTests: XCTestCase {

    /// Reference values from the Raven workspace (TOOLS.md):
    ///   W9FJC  → 8593
    ///   KJ7CMR → 17081
    func testKnownCallsigns() {
        XCTAssertEqual(APRSMessaging.passcode(for: "W9FJC"),  8593)
        XCTAssertEqual(APRSMessaging.passcode(for: "KJ7CMR"), 17081)
    }

    func testStripsSSID() {
        XCTAssertEqual(
            APRSMessaging.passcode(for: "W9FJC-7"),
            APRSMessaging.passcode(for: "W9FJC")
        )
    }

    func testCaseInsensitive() {
        XCTAssertEqual(
            APRSMessaging.passcode(for: "w9fjc"),
            APRSMessaging.passcode(for: "W9FJC")
        )
    }
}
