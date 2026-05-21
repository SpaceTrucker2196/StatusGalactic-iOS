import XCTest
@testable import StatusGalactic

final class MagneticDeclinationParserTests: XCTestCase {

    func testParsesNCEIPayload() {
        let json = """
        {
          "model": "WMM-2025",
          "result": [
            {
              "declination": 1.85,
              "inclination": 70.2,
              "totalintensity": 53500.4,
              "date": 2026.5
            }
          ]
        }
        """.data(using: .utf8)!

        let mag = MagneticDeclinationClient.parse(json, lat: 43.8, lng: -91.2)
        XCTAssertEqual(mag?.declinationDeg, 1.85)
        XCTAssertEqual(mag?.inclinationDeg, 70.2)
        XCTAssertEqual(mag?.totalFieldNT, 53500.4)
        XCTAssertEqual(mag?.model, "WMM-2025")
        XCTAssertEqual(mag?.formatted, "1.9°E")
    }

    func testWestDeclinationFormatting() {
        let json = """
        { "result": [ { "declination": -7.2 } ] }
        """.data(using: .utf8)!
        let mag = MagneticDeclinationClient.parse(json, lat: 60, lng: -150)
        XCTAssertEqual(mag?.formatted, "7.2°W")
    }

    func testZeroDeclinationFormatting() {
        let json = """
        { "result": [ { "declination": 0.02 } ] }
        """.data(using: .utf8)!
        let mag = MagneticDeclinationClient.parse(json, lat: 0, lng: 0)
        XCTAssertEqual(mag?.formatted, "0.0°")
    }

    func testGarbageReturnsNil() {
        XCTAssertNil(MagneticDeclinationClient.parse(Data("not json".utf8), lat: 0, lng: 0))
    }
}
