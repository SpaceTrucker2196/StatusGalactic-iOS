import XCTest
@testable import StatusGalactic

final class WeatherAlertsParserTests: XCTestCase {

    func testParsesAndSortsBySeverity() throws {
        let json = """
        {
          "features": [
            {
              "id": "urn:oid:1",
              "properties": {
                "id": "urn:oid:1",
                "event": "Flood Advisory",
                "severity": "Moderate",
                "certainty": "Likely",
                "urgency": "Expected",
                "headline": "Flood Advisory issued ...",
                "areaDesc": "La Crosse County",
                "onset": "2026-05-21T18:00:00Z",
                "expires": "2026-05-22T00:00:00Z",
                "senderName": "NWS La Crosse",
                "instruction": "Turn around, don't drown."
              }
            },
            {
              "id": "urn:oid:2",
              "properties": {
                "id": "urn:oid:2",
                "event": "Tornado Warning",
                "severity": "Extreme",
                "urgency": "Immediate",
                "areaDesc": "La Crosse, Vernon",
                "expires": "2026-05-21T19:00:00Z"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let alerts = WeatherAlertsClient.parse(json)
        XCTAssertEqual(alerts.count, 2)
        XCTAssertEqual(alerts[0].event, "Tornado Warning")
        XCTAssertEqual(alerts[0].severityLevel, 4)
        XCTAssertEqual(alerts[1].event, "Flood Advisory")
        XCTAssertEqual(alerts[1].severityLevel, 2)
        XCTAssertEqual(alerts[1].instruction, "Turn around, don't drown.")
    }

    func testEmptyFeed() {
        let json = #"{"features": []}"#.data(using: .utf8)!
        XCTAssertEqual(WeatherAlertsClient.parse(json), [])
    }

    func testGarbageReturnsEmpty() {
        XCTAssertEqual(WeatherAlertsClient.parse(Data("not json".utf8)), [])
    }
}
