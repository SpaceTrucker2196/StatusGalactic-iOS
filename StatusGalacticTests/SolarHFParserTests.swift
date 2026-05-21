import XCTest
@testable import StatusGalactic

/// Parser coverage for the SolarHam-style HF data layer. Each block uses a
/// real-shaped fixture pasted from the live NOAA / NASA endpoints.

final class XRayClassifierTests: XCTestCase {

    func testClassifyKnownBoundaries() {
        XCTAssertEqual(GOESParticleClient.classify(flux: 1.0e-7), "B1.0")
        XCTAssertEqual(GOESParticleClient.classify(flux: 5.0e-7), "B5.0")
        XCTAssertEqual(GOESParticleClient.classify(flux: 1.2e-6), "C1.2")
        XCTAssertEqual(GOESParticleClient.classify(flux: 1.0e-5), "M1.0")
        XCTAssertEqual(GOESParticleClient.classify(flux: 5.5e-5), "M5.5")
        XCTAssertEqual(GOESParticleClient.classify(flux: 1.4e-4), "X1.4")
    }

    func testRScaleThresholds() {
        XCTAssertEqual(GOESParticleClient.rScale(forPeakFlux: 1e-7), "R0")
        XCTAssertEqual(GOESParticleClient.rScale(forPeakFlux: 1e-5), "R1")
        XCTAssertEqual(GOESParticleClient.rScale(forPeakFlux: 5e-5), "R2")
        XCTAssertEqual(GOESParticleClient.rScale(forPeakFlux: 1e-4), "R3")
        XCTAssertEqual(GOESParticleClient.rScale(forPeakFlux: 1e-3), "R4")
        XCTAssertEqual(GOESParticleClient.rScale(forPeakFlux: 2e-3), "R5")
    }

    func testSScaleThresholds() {
        XCTAssertEqual(GOESParticleClient.sScale(forFlux: 0.5), "S0")
        XCTAssertEqual(GOESParticleClient.sScale(forFlux: 25), "S1")
        XCTAssertEqual(GOESParticleClient.sScale(forFlux: 500), "S2")
        XCTAssertEqual(GOESParticleClient.sScale(forFlux: 5000), "S3")
        XCTAssertEqual(GOESParticleClient.sScale(forFlux: 50_000), "S4")
        XCTAssertEqual(GOESParticleClient.sScale(forFlux: 1_500_000), "S5")
    }
}

final class WWVParserTests: XCTestCase {

    func testParsesIndicesAndSummaries() {
        let sample = """
        :Product: Geophysical Alert Message wwv.txt
        :Issued: 2026 May 20 1205 UTC
        #
        #          Geophysical Alert Message
        #
        Solar-terrestrial indices for 20 May follow.
        Solar flux 114 and estimated planetary A-index 5.
        The estimated planetary K-index at 1200 UTC on 20 May was 2.
        Space weather for the past 24 hours has been minor.
        No space weather storms are predicted for the next 24 hours.
        """
        let parsed = WWVClient.parse(sample)
        XCTAssertEqual(parsed.solarFlux, 114)
        XCTAssertEqual(parsed.aIndex, 5)
        XCTAssertEqual(parsed.kIndex, 2)
        XCTAssertNotNil(parsed.geomagSummary)
        XCTAssertNotNil(parsed.propagationSummary)
        XCTAssertEqual(parsed.rawText, sample)
    }
}

final class SpaceWeatherForecastTests: XCTestCase {

    func testGScaleMapping() {
        XCTAssertEqual(SpaceWeatherForecastClient.gScaleString(forKp: 3.2), "G0")
        XCTAssertEqual(SpaceWeatherForecastClient.gScaleString(forKp: 5.0), "G1")
        XCTAssertEqual(SpaceWeatherForecastClient.gScaleString(forKp: 5.7), "G1")
        XCTAssertEqual(SpaceWeatherForecastClient.gScaleString(forKp: 6.4), "G2")
        XCTAssertEqual(SpaceWeatherForecastClient.gScaleString(forKp: 8.0), "G4")
        XCTAssertEqual(SpaceWeatherForecastClient.gScaleString(forKp: 9.0), "G5")
    }

    func testFlareAndKpParsedFromBulletin() {
        let sample = """
        :Product: 3-Day Forecast
        :Issued: 2026 May 20 1230 UTC
        #
        NOAA Geomagnetic Activity Observation and Forecast

        NOAA Kp index breakdown May 21-May 23
                     May 21    May 22    May 23
        00-03UT      3.00       2.67      2.00
        03-06UT      3.33       2.33      2.00
        06-09UT      3.00       2.00      2.00
        09-12UT      2.67       2.00      2.00
        12-15UT      2.67       2.00      2.00
        15-18UT      2.67       2.00      2.00
        18-21UT      4.00       2.67      3.00
        21-00UT      3.00       2.33      2.67

        Rationale: ...

        NOAA Solar Radiation Activity Observation and Forecast
        Solar Radiation Storm Forecast for May 21-May 23
                   May 21  May 22  May 23
        S1 or greater   5%     5%     5%

        NOAA Radio Blackout Activity and Forecast

        Radio Blackout Forecast for May 21-May 23
                   May 21  May 22  May 23
        Class M    25%     20%     15%
        Class X     5%      5%      5%
        """
        let result = SpaceWeatherForecastClient.parse(sample)
        XCTAssertEqual(result.kpDays.count, 3)
        XCTAssertEqual(result.kpDays[0].maxKp, 4.0)
        XCTAssertEqual(result.kpDays[0].gScale, "G0")
        let flares = try? XCTUnwrap(result.flares)
        XCTAssertEqual(flares?.mClassPct, 25)
        XCTAssertEqual(flares?.xClassPct, 5)
        XCTAssertEqual(flares?.protonEventPct, 5)
    }
}

final class SolarOutlookParserTests: XCTestCase {

    func testParsesRows() {
        let sample = """
        :Product: 27-day Space Weather Outlook Table 27DO.txt
        :Issued: 2026 May 20 0000 UTC
        #
        #      27-day Space Weather Outlook Table
        #                Issued 2026-05-20
        #
        #   UTC      Radio Flux   Planetary   Largest
        #  Date     10.7 cm        A Index    Kp Index
        2026 May 21      115            8         3
        2026 May 22      114           10         4
        2026 May 23      113           12         4
        """
        let parsed = SolarOutlookClient.parse(sample)
        XCTAssertEqual(parsed.count, 3)
        XCTAssertEqual(parsed[0].radioFlux, 115)
        XCTAssertEqual(parsed[1].aIndex, 10)
        XCTAssertEqual(parsed[2].largestKp, 4)
    }
}

final class OVATIONParserTests: XCTestCase {

    func testPicksNearestGridCell() {
        // Three coordinates: a far point, viewer-adjacent point, peak elsewhere.
        let payload: [String: Any] = [
            "Observation Time": "2026-05-21T18:30:00Z",
            "Forecast Time": "2026-05-21T19:00:00Z",
            "coordinates": [
                [10.0, 60.0, 5],
                [269.0, 44.0, 18],   // ≈ 269°E = -91°W; near La Crosse
                [120.0, 70.0, 80],
            ]
        ]
        let forecast = OVATIONClient.parse(payload: payload, lat: 43.80, lng: -91.20)
        XCTAssertEqual(forecast?.localProbabilityPct, 18)
        XCTAssertEqual(forecast?.globalMaxPct, 80)
    }
}

final class BandConditionsTests: XCTestCase {

    func testStormDegradesAllBands() {
        let bands = BandConditions.evaluate(sfi: 130, kp: 7.5, rScale: nil, mufMHz: 22)
        for b in bands {
            XCTAssertTrue(["Poor", "Closed"].contains(b.dayStatus),
                          "Expected G3 storm to degrade \(b.band)")
        }
    }

    func testHighBandsNeedSFI() {
        let bands = BandConditions.evaluate(sfi: 72, kp: 2, rScale: "R0", mufMHz: 18)
        let tenMeters = bands.first { $0.band == "10m" }!
        XCTAssertNotEqual(tenMeters.dayStatus, "Good")
    }

    func testRadioBlackoutMarksLowBandsPoor() {
        let bands = BandConditions.evaluate(sfi: 110, kp: 2, rScale: "R3", mufMHz: 22)
        let twenty = bands.first { $0.band == "20m" }!
        XCTAssertEqual(twenty.dayStatus, "Poor")
        XCTAssertEqual(twenty.reason, "R3 radio blackout")
    }
}
