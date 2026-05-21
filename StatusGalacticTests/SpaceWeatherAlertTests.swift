import XCTest
@testable import StatusGalactic

final class SpaceWeatherAlertTests: XCTestCase {

    func testScaleLevelExtraction() {
        XCTAssertNil(NotificationManager.scaleLevel(nil))
        XCTAssertNil(NotificationManager.scaleLevel("R0"))
        XCTAssertNil(NotificationManager.scaleLevel("G0"))
        XCTAssertNil(NotificationManager.scaleLevel(""))
        XCTAssertNil(NotificationManager.scaleLevel("X"))
        XCTAssertEqual(NotificationManager.scaleLevel("R1"), 1)
        XCTAssertEqual(NotificationManager.scaleLevel("R3"), 3)
        XCTAssertEqual(NotificationManager.scaleLevel("S5"), 5)
        XCTAssertEqual(NotificationManager.scaleLevel("G2"), 2)
    }
}
