import XCTest
@testable import StatusGalactic

final class SOTAParserTests: XCTestCase {

    func testParsesTypicalSpot() {
        let raw: [String: Any] = [
            "id": 4242,
            "activatorCallsign": "K1ABC",
            "summitCode": "W4V/CT-001",
            "summitDetails": "Mount Mitchell, 2037m",
            "frequency": "14.062",
            "mode": "CW",
            "timeStamp": "2026-05-21T18:30:00",
            "comments": "spotting himself"
        ]
        let spot = try? XCTUnwrap(SOTAClient.parse(raw))
        XCTAssertEqual(spot?.activator, "K1ABC")
        XCTAssertEqual(spot?.summitCode, "W4V/CT-001")
        XCTAssertEqual(spot?.frequencyKHz ?? 0, 14062.0, accuracy: 0.001)
        XCTAssertEqual(spot?.mode, "CW")
        XCTAssertEqual(spot?.summitDetails, "Mount Mitchell, 2037m")
    }

    func testReturnsNilWithoutCallsign() {
        XCTAssertNil(SOTAClient.parse([
            "summitCode": "W4V/CT-001",
            "frequency": "14.062",
            "timeStamp": "2026-05-21T18:30:00",
        ]))
    }
}

final class DXClusterParserTests: XCTestCase {

    func testParsesArrayShape() {
        let raw: [String: Any] = [
            "dx_call": "VP6/W9XYZ",
            "spotter": "K1ABC",
            "frequency": 14025.0,
            "info": "CQ DX",
            "time": "2026-05-21T18:30:00Z",
        ]
        let spot = try? XCTUnwrap(DXClusterClient.parse(raw))
        XCTAssertEqual(spot?.dxCallsign, "VP6/W9XYZ")
        XCTAssertEqual(spot?.spotter, "K1ABC")
        XCTAssertEqual(spot?.frequencyKHz, 14025)
        XCTAssertEqual(spot?.info, "CQ DX")
    }

    func testAcceptsAlternateKeyNames() {
        let raw: [String: Any] = [
            "dxCall": "FT8WW",
            "de_call": "JA1ABC",
            "frequency": "21074",
            "comment": "FT8 -12",
            "spot_time": "2026-05-21T18:30:00Z",
        ]
        let spot = try? XCTUnwrap(DXClusterClient.parse(raw))
        XCTAssertEqual(spot?.dxCallsign, "FT8WW")
        XCTAssertEqual(spot?.spotter, "JA1ABC")
        XCTAssertEqual(spot?.frequencyKHz, 21074)
        XCTAssertEqual(spot?.info, "FT8 -12")
    }

    func testReturnsNilWithoutCallsigns() {
        XCTAssertNil(DXClusterClient.parse(["frequency": 14000]))
    }
}
