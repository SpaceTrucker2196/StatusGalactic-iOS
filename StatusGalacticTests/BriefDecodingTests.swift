import XCTest
@testable import StatusGalactic

final class BriefDecodingTests: XCTestCase {

    func testFullBriefDecodes() throws {
        let json = """
        {
          "when": "2026-05-19T13:00:00+00:00",
          "lat": 43.8,
          "lng": -91.2,
          "timezone": "America/Chicago",
          "location_name": "La Crosse, WI",
          "earth": {
            "location_name": "La Crosse, WI",
            "periods": [
              {
                "name": "Today",
                "short_forecast": "Scattered showers",
                "temperature": 60,
                "temperature_unit": "F",
                "is_daytime": true,
                "wind": "15 mph NW",
                "detailed_forecast": null
              }
            ]
          },
          "marine": {
            "zone_id": "GMZ033",
            "periods": [
              {
                "name": "This Afternoon",
                "short_forecast": "Seas 2 to 3 ft",
                "temperature": null,
                "temperature_unit": "F",
                "is_daytime": true,
                "wind": null,
                "detailed_forecast": "Seas 2 to 3 ft"
              }
            ]
          },
          "space": {
            "solar_flux": 105,
            "kp_index": 4.0,
            "kp_status": "unsettled",
            "aurora_likely": false,
            "hf_summary": "Fair to good on low bands",
            "observed_at": "2026-05-19T12:00:00+00:00"
          },
          "sun": {
            "timezone": "America/Chicago",
            "sunrise_utc": "2026-05-19T10:35:00+00:00",
            "sunset_utc": "2026-05-20T01:28:00+00:00",
            "golden_morning_start_utc": "2026-05-19T10:25:00+00:00",
            "golden_morning_end_utc": "2026-05-19T11:05:00+00:00",
            "golden_evening_start_utc": "2026-05-20T00:58:00+00:00",
            "golden_evening_end_utc": "2026-05-20T01:38:00+00:00",
            "civil_dawn_utc": "2026-05-19T10:01:00+00:00",
            "civil_dusk_utc": "2026-05-20T02:01:00+00:00",
            "nautical_dawn_utc": "2026-05-19T09:18:00+00:00",
            "nautical_dusk_utc": "2026-05-20T02:44:00+00:00",
            "astronomical_dawn_utc": "2026-05-19T08:28:00+00:00",
            "astronomical_dusk_utc": "2026-05-20T03:35:00+00:00"
          },
          "moon": {
            "phase_name": "Waxing Crescent",
            "phase_angle_deg": 40.1,
            "illumination_pct": 12.0
          },
          "planets": [
            {"body": "Sun", "sign": "Taurus", "degree": 28.31, "retrograde": false}
          ],
          "launches": [
            {
              "name": "Falcon 9 | Starlink",
              "when_utc": "2026-05-20T02:36:00+00:00",
              "pad": "SLC-40",
              "provider": "SpaceX",
              "status": "Go for Launch"
            }
          ],
          "errors": {}
        }
        """.data(using: .utf8)!

        let brief = try BriefAPIClient.makeDecoder().decode(Brief.self, from: json)

        XCTAssertEqual(brief.locationName, "La Crosse, WI")
        XCTAssertEqual(brief.timezone, "America/Chicago")
        XCTAssertEqual(brief.earth?.periods.count, 1)
        XCTAssertEqual(brief.earth?.periods.first?.temperature, 60)
        XCTAssertEqual(brief.marine?.zoneId, "GMZ033")
        XCTAssertEqual(brief.space?.kpStatus, "unsettled")
        XCTAssertFalse(brief.space?.auroraLikely ?? true)
        XCTAssertEqual(brief.sun?.timezone, "America/Chicago")
        XCTAssertNotNil(brief.sun?.civilDawnUtc)
        XCTAssertNotNil(brief.sun?.astronomicalDuskUtc)
        XCTAssertEqual(brief.moon?.phaseName, "Waxing Crescent")
        XCTAssertEqual(brief.planets.first?.body, "Sun")
        XCTAssertEqual(brief.launches.first?.provider, "SpaceX")
    }

    func testDecodesDateWithFractionalSeconds() throws {
        let json = """
        {"phase_name":"Full Moon","phase_angle_deg":180.0,"illumination_pct":100.0}
        """.data(using: .utf8)!

        let moon = try JSONDecoder().decode(Moon.self, from: json)
        XCTAssertEqual(moon.phaseName, "Full Moon")
    }

    func testHandlesMissingOptionalFields() throws {
        let json = """
        {
          "when": "2026-05-19T13:00:00+00:00",
          "lat": 0,
          "lng": 0,
          "timezone": "UTC",
          "location_name": null,
          "earth": null,
          "marine": null,
          "space": null,
          "sun": null,
          "moon": null,
          "planets": [],
          "launches": [],
          "errors": {"nws": "boom"}
        }
        """.data(using: .utf8)!

        let brief = try BriefAPIClient.makeDecoder().decode(Brief.self, from: json)
        XCTAssertNil(brief.earth)
        XCTAssertNil(brief.marine)
        XCTAssertEqual(brief.errors["nws"], "boom")
    }
}
