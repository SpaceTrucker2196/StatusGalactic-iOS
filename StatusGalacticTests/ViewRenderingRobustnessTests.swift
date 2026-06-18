import XCTest
import SwiftUI
import UIKit
@testable import StatusGalactic

/// Force SwiftUI to evaluate every panel's `body` with empty / sparse /
/// degenerate data. A precondition failure or force-unwrap inside body
/// surfaces here as a test failure rather than a runtime crash in the
/// hands of a user with a flaky network.
///
/// `UIHostingController(rootView:).view.layoutIfNeeded()` is the smallest
/// hammer that reliably exercises body(). Each test materializes one
/// panel, lays it out at a phone-sized frame, and asserts that the
/// process didn't trap.
@MainActor
final class ViewRenderingRobustnessTests: XCTestCase {

    // MARK: - Harness

    private func render<V: View>(_ view: V, height: CGFloat = 844) {
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: height)
        host.view.layoutIfNeeded()
        // Touching intrinsic content size forces one more body() eval on
        // SwiftUI views that haven't drawn yet.
        _ = host.view.intrinsicContentSize
    }

    // MARK: - Test data factories

    /// Brief with every optional nil and every array empty. Pure-compute
    /// panels (planets, sun, moon) still populate; everything else is
    /// the "nothing came back from the network" path.
    private func emptyBrief() -> Brief {
        Brief(
            when: Date(),
            lat: 43.86, lng: -91.23,
            timezone: "America/Chicago",
            locationName: nil,
            earth: nil, marine: nil, space: nil,
            sun: nil, moon: nil,
            planets: [],
            launches: [],
            errors: [:]
        )
    }

    /// A brief carrying every field at minimum-shape values. Useful for
    /// exercising the "data present" branches without depending on
    /// real network responses.
    private func minimalPopulatedBrief() -> Brief {
        let now = Date()
        return Brief(
            when: now,
            lat: 43.86, lng: -91.23,
            timezone: "America/Chicago",
            locationName: "Test, ZZ",
            earth: EarthWeather(
                locationName: "Test, ZZ",
                periods: [
                    WeatherPeriod(
                        name: "Today", shortForecast: "Clear",
                        temperature: 68, temperatureUnit: "F",
                        isDaytime: true, wind: "5 mph", detailedForecast: nil
                    )
                ]
            ),
            marine: nil,
            space: SpaceWeather(
                solarFlux: 114, kpIndex: 3.0, kpStatus: "unsettled",
                auroraLikely: false, hfSummary: "fair", observedAt: now
            ),
            sun: nil, moon: nil, planets: [],
            launches: [],
            xRay: XRayState(
                currentFlux: 5e-7, currentClass: "B5.0",
                peakFlux24h: 1.2e-5, peakClass24h: "M1.2",
                rScale: "R1", observedAt: now,
                history: (0..<60).map { i in
                    XRaySample(
                        time: now.addingTimeInterval(TimeInterval(-i * 60)),
                        flux: pow(10.0, -7 + Double(i % 5) * 0.4)
                    )
                }
            ),
            proton: ProtonState(fluxPfu: 0.5, sScale: "S0", observedAt: now),
            ionosondes: [],
            aurora: AuroraForecast(
                observedAt: now, forecastFor: now,
                localProbabilityPct: 24, globalMaxPct: 60
            ),
            bandConditions: BandConditions.evaluate(
                sfi: 114, kp: 3.0, rScale: "R1", mufMHz: 18
            ),
            errors: [:]
        )
    }

    private func config() -> ClientConfig { ClientConfig() }

    private func vm(with brief: Brief?) -> BriefViewModel {
        let m = BriefViewModel()
        if let brief {
            m.state = .loaded(brief, fetchedAt: Date(), isStale: false)
        }
        return m
    }

    // MARK: - Top-of-brief widgets

    func testStormScaleRowRendersEmpty() {
        render(StormScaleRow(brief: emptyBrief()))
    }

    func testStormScaleRowRendersPopulated() {
        render(StormScaleRow(brief: minimalPopulatedBrief()))
    }

    func testAnimatedSunPanelRenders() {
        // Network is ambient — the test only proves body() doesn't trap
        // before the AVPlayer reports a frame.
        render(AnimatedSunPanel(), height: 400)
    }

    // MARK: - SolarAlmanacView (the user-reported crash point)

    func testSolarAlmanacViewRendersEmptyBrief() {
        render(
            SolarAlmanacView(brief: emptyBrief())
                .environment(config())
        )
    }

    func testSolarAlmanacViewRendersWithMinimalData() {
        render(
            SolarAlmanacView(brief: minimalPopulatedBrief())
                .environment(config())
        )
    }

    // MARK: - X-ray flux panel (log-scale crash regression)

    func testXRayFluxPanelRendersEmptyHistory() {
        let s = XRayState(
            currentFlux: 1e-7, currentClass: "B1.0",
            peakFlux24h: 1e-7, peakClass24h: "B1.0",
            rScale: "R0", observedAt: Date(),
            history: []
        )
        render(XRayFluxPanel(state: s))
    }

    func testXRayFluxPanelRendersSingleSample() {
        let s = XRayState(
            currentFlux: 5e-7, currentClass: "B5.0",
            peakFlux24h: 5e-7, peakClass24h: "B5.0",
            rScale: "R0", observedAt: Date(),
            history: [XRaySample(time: Date(), flux: 5e-7)]
        )
        render(XRayFluxPanel(state: s))
    }

    func testXRayFluxPanelRendersAllEqualSamples() {
        let now = Date()
        let s = XRayState(
            currentFlux: 5e-7, currentClass: "B5.0",
            peakFlux24h: 5e-7, peakClass24h: "B5.0",
            rScale: "R0", observedAt: now,
            history: (0..<10).map { i in
                XRaySample(time: now.addingTimeInterval(TimeInterval(-i * 60)), flux: 5e-7)
            }
        )
        // Same-flux series previously crashed the log-scale chart;
        // the rewritten panel should bail to the "Awaiting samples" view.
        render(XRayFluxPanel(state: s))
    }

    func testXRayFluxPanelRendersZeroFluxSamplesSafely() {
        let now = Date()
        let s = XRayState(
            currentFlux: 0, currentClass: "A0.0",
            peakFlux24h: 0, peakClass24h: "A0.0",
            rScale: "R0", observedAt: now,
            history: (0..<10).map { i in
                XRaySample(time: now.addingTimeInterval(TimeInterval(-i * 60)), flux: 0)
            }
        )
        // Zero flux must be filtered out before the log10 transform.
        render(XRayFluxPanel(state: s))
    }

    // MARK: - RF tab content (mostly Brief-derived)

    func testBandConditionsPanelRendersEmpty() {
        render(BandConditionsPanel(bands: []))
    }

    func testBandConditionsPanelRendersStormy() {
        let bands = BandConditions.evaluate(sfi: 72, kp: 7.5, rScale: "R3", mufMHz: 18)
        render(BandConditionsPanel(bands: bands))
    }

    func testIonosondePanelRendersEmpty() {
        render(IonosondePanel(stations: []))
    }

    // MARK: - Earthquakes + tides edge cases

    func testTidesCardRendersWithFlatHeights() {
        let now = Date()
        let tides = Tides(
            stationId: "1234", stationName: "Flat Bay",
            distanceKm: 5,
            events: (0..<4).map { i in
                TideEvent(time: now.addingTimeInterval(TimeInterval(i * 6 * 3600)),
                          heightFt: 3.0, kind: .high)
            }
        )
        render(TidesCard(tides: tides, timezoneName: "UTC"))
    }

    func testEarthquakeTimelineRendersEmpty() {
        render(EarthquakeTimelineChart(quakes: []))
    }

    // MARK: - Weather alerts

    func testWeatherAlertCardRendersMinimal() {
        let alert = WeatherAlert(
            alertId: "test-1",
            event: "Tornado Warning",
            severity: "Extreme",
            certainty: nil, urgency: nil, headline: nil,
            description: nil, instruction: nil,
            areaDesc: nil, onsetAt: nil, expiresAt: nil,
            senderName: nil
        )
        render(WeatherAlertCard(alert: alert))
    }

    func testWeatherAlertCardRendersFull() {
        let now = Date()
        let alert = WeatherAlert(
            alertId: "test-2",
            event: "Severe Thunderstorm Warning",
            severity: "Severe",
            certainty: "Observed", urgency: "Immediate",
            headline: "Severe storms approaching",
            description: "Long description text",
            instruction: "Take shelter in an interior room.",
            areaDesc: "La Crosse, Vernon",
            onsetAt: now,
            expiresAt: now.addingTimeInterval(3600),
            senderName: "NWS La Crosse"
        )
        render(WeatherAlertCard(alert: alert))
    }

    // MARK: - Solar Almanac panel population

    func testSolarWindPanelRendersAllEmpty() {
        let wind = SolarWind(
            observedAt: Date(),
            speedKmS: nil, densityP: nil, temperatureK: nil,
            bzNT: nil, btNT: nil,
            history: []
        )
        render(SolarWindPanel(wind: wind))
    }

    func testSolarWindPanelRendersWithHistory() {
        let now = Date()
        var samples: [SolarWindSample] = []
        for i in 0..<60 {
            let t = now.addingTimeInterval(TimeInterval(-i * 60))
            let speed = 400 + Double(i % 10) * 10
            let bz = -3 + Double(i % 7)
            samples.append(SolarWindSample(time: t, speedKmS: speed, bzNT: bz))
        }
        let wind = SolarWind(
            observedAt: now,
            speedKmS: 412, densityP: 4.2, temperatureK: 100_000,
            bzNT: -3.5, btNT: 6.0,
            history: samples
        )
        render(SolarWindPanel(wind: wind))
    }

    func testFlareProbabilityPanelRendersZeroes() {
        render(FlareProbabilityPanel(flare: FlareProbability(
            issuedAt: Date(), cClassPct: 0, mClassPct: 0, xClassPct: 0, protonEventPct: 0
        )))
    }

    func testKpForecastPanelRendersDays() {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let days = (0..<3).map { i in
            KpForecastDay(
                date: cal.date(byAdding: .day, value: i, to: now) ?? now,
                maxKp: Double(3 + i), gScale: "G\(i)"
            )
        }
        render(KpForecastPanel(days: days))
    }

    func testActiveRegionsPanelRendersTwoRegions() {
        let regions: [ActiveRegion] = [
            ActiveRegion(region: 4443, location: "S16E23",
                         latitude: -16, longitude: 23,
                         area: 250, numberOfSpots: 6,
                         magClass: "Beta-Gamma", spotClass: "Cao",
                         observedAt: Date()),
            ActiveRegion(region: 4441, location: "N12W05",
                         latitude: 12, longitude: -5,
                         area: nil, numberOfSpots: nil,
                         magClass: "Alpha", spotClass: "Axx",
                         observedAt: Date())
        ]
        render(ActiveRegionsPanel(regions: regions))
    }

    func testCMETrackerPanelRendersEvents() {
        let now = Date()
        let events: [CMEEvent] = [
            CMEEvent(activityID: "2026-05-21-CME-001",
                     startTime: now.addingTimeInterval(-3600),
                     sourceLocation: "N15W23", speedKmS: 480,
                     halfAngleDeg: 30, isHalo: false,
                     arrivalEstimateUtc: now.addingTimeInterval(48 * 3600),
                     note: "Faint CME from filament eruption.",
                     linkURL: nil),
            CMEEvent(activityID: "2026-05-20-CME-002",
                     startTime: now.addingTimeInterval(-86400),
                     sourceLocation: nil, speedKmS: nil,
                     halfAngleDeg: nil, isHalo: true,
                     arrivalEstimateUtc: nil, note: nil, linkURL: nil)
        ]
        render(CMETrackerPanel(cmes: events))
    }

    func testSolarOutlookPanelRendersDays() {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let days = (0..<27).map { i in
            SolarOutlookDay(
                date: cal.date(byAdding: .day, value: i, to: now) ?? now,
                radioFlux: 110 + (i % 5),
                aIndex: 4 + (i % 3),
                largestKp: 2 + (i % 4)
            )
        }
        render(SolarOutlookPanel(days: days))
    }

    func testSolarCyclePanelRendersMonths() {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let points = (0..<24).map { i -> SolarCyclePoint in
            let month = cal.date(byAdding: .month, value: -i, to: now) ?? now
            return SolarCyclePoint(
                month: month,
                sunspotNumber: Double(100 - i * 2),
                smoothedSunspotNumber: i < 18 ? Double(98 - i * 2) : nil,
                radioFlux: Double(115 - i),
                smoothedRadioFlux: i < 18 ? Double(112 - i) : nil
            )
        }.reversed()
        render(SolarCyclePanel(points: Array(points)))
    }

    func testWWVBulletinPanelRendersMinimal() {
        let bulletin = WWVBulletin(
            issuedAt: Date(),
            solarFlux: 114, aIndex: 5, kIndex: 2,
            geomagSummary: "Quiet conditions.",
            propagationSummary: "No storms predicted.",
            rawText: ""
        )
        render(WWVBulletinPanel(bulletin: bulletin))
    }

    func testIonosondePanelRendersStations() {
        var stations: [IonosondeStation] = []
        for i in 0..<3 {
            let station = IonosondeStation(
                name: "AB\(100 + i)",
                latitude: Double(40 + i),
                longitude: Double(-90 - i),
                fof2MHz: 8.0 + Double(i),
                mufMHz: 18.0 + Double(i),
                observedAt: Date(),
                distanceKm: 500.0 * Double(i + 1)
            )
            stations.append(station)
        }
        render(IonosondePanel(stations: stations))
    }

    func testAuroraForecastPanelRendersHighLow() {
        render(AuroraForecastPanel(forecast: AuroraForecast(
            observedAt: Date(), forecastFor: Date(),
            localProbabilityPct: 0, globalMaxPct: 5
        )))
        render(AuroraForecastPanel(forecast: AuroraForecast(
            observedAt: Date(), forecastFor: Date(),
            localProbabilityPct: 72, globalMaxPct: 90
        )))
    }

    // MARK: - Row-style cards

    func testCrewedLaunchRowRenders() {
        let launch = CrewedLaunch(
            name: "Crew-12", whenUtc: Date().addingTimeInterval(86400),
            pad: "LC-39A", provider: "SpaceX", status: "Go",
            missionName: "Crew-12", missionDescription: "Six-month ISS rotation.",
            rocketName: "Falcon 9", destination: "ISS"
        )
        render(CrewedLaunchRow(launch: launch))
    }

    func testPOTASpotRowRenders() {
        let spot = POTASpot(
            spotId: 1, activator: "W9ABC", parkRef: "K-0012",
            parkName: "Kettle Moraine State Forest",
            frequencyKHz: 14060, mode: "CW", spotTime: Date(),
            latitude: 43.5, longitude: -88.4,
            locationDesc: "US-WI", comments: "QRT in 15",
            distanceKm: 150
        )
        render(POTASpotRow(spot: spot))
    }

    func testSOTASpotRowRenders() {
        let spot = SOTASpot(
            spotId: 1, activator: "K1ABC",
            summitCode: "W4V/CT-001",
            summitDetails: "Mount Mitchell, 2037 m",
            frequencyKHz: 14062, mode: "CW",
            spotTime: Date(), comments: nil
        )
        render(SOTASpotRow(spot: spot))
    }

    func testDXSpotRowRenders() {
        let spot = DXSpot(
            dxCallsign: "VP6/W9XYZ",
            spotter: "K1ABC",
            frequencyKHz: 14025,
            info: "CQ DX", spotTime: Date()
        )
        render(DXSpotRow(spot: spot))
    }

    func testNEORowRenders() {
        let neo = NearEarthObject(
            name: "(2026 AB1) test", magnitudeH: 22,
            diameterMinM: 50, diameterMaxM: 110,
            isHazardous: true, approachAt: Date().addingTimeInterval(3 * 86400),
            missDistanceKm: 380_000, velocityKps: 12,
            nasaJplURL: nil
        )
        render(NEORow(neo: neo))
    }

    func testInterstellarRowRenders() {
        let obj = InterstellarObject(
            designation: "1I/'Oumuamua", discoveryDate: "2017-10-19",
            perihelionAU: 0.255, eccentricity: 1.20, inclinationDeg: 122.7,
            status: "Departed", notes: "First confirmed interstellar object."
        )
        render(InterstellarRow(obj: obj))
    }

    func testConstellationRowRenders() {
        render(ConstellationRow(summary: ConstellationSummary(
            name: "Starlink", group: "starlink",
            count: 5482, latestEpochAt: Date()
        )))
    }

    func testEarthquakeRowRenders() {
        let quake = Earthquake(
            id: "us123", magnitude: 4.8,
            place: "20 km SW of Test, ZZ",
            time: Date(),
            latitude: 36.5, longitude: -120.2,
            depthKm: 12, usgsURL: nil,
            isSignificant: false, distanceKm: 240
        )
        render(EarthquakeRow(quake: quake))
    }

    // MARK: - Almanac drill-ins + stale state

    func testMarsAlmanacViewRenders() {
        let mars = MarsWeather(
            sol: 4400, season: "Northern Autumn",
            terrestrialDate: "2026-04-01",
            minTempC: -85, maxTempC: -15,
            pressurePa: 720, atmoOpacity: "Sunny",
            sunrise: "05:35", sunset: "17:42",
            source: "Perseverance"
        )
        render(MarsAlmanacView(mars: mars, when: Date()), height: 900)
    }

    func testRiverStageAlmanacViewRenders() {
        let gauge = RiverGauge(
            lid: "LCRM5", name: "Mississippi at Test",
            lat: 43.8, lng: -91.2, distanceKm: 5,
            currentStageFt: 9.2, observedAt: Date(),
            actionStageFt: 12, minorFloodStageFt: 14,
            moderateFloodStageFt: 17, majorFloodStageFt: 20,
            forecastPeakFt: 11.5, forecastPeakAt: Date().addingTimeInterval(3 * 86400)
        )
        render(RiverStageAlmanacView(
            gauge: gauge, viewerLat: 43.86, viewerLng: -91.23
        ), height: 900)
    }

    func testRiverStageAlmanacViewRendersWithNoThresholds() {
        // A gauge that has only a current reading — no flood thresholds.
        // RiverStageAlmanacView shouldn't trap when computing the risk %.
        let gauge = RiverGauge(
            lid: "TEST1", name: "No-threshold gauge",
            lat: 0, lng: 0, distanceKm: 10,
            currentStageFt: 3.5, observedAt: Date(),
            actionStageFt: nil, minorFloodStageFt: nil,
            moderateFloodStageFt: nil, majorFloodStageFt: nil,
            forecastPeakFt: nil, forecastPeakAt: nil
        )
        render(RiverStageAlmanacView(gauge: gauge, viewerLat: nil, viewerLng: nil))
    }

    func testBriefDetailViewRendersEmptyStale() {
        // The state the user lands on at cold launch when the cache is
        // present but the first refresh hasn't completed yet.
        render(
            BriefDetailView(brief: emptyBrief(), fetchedAt: Date(), isStale: true)
                .environment(config()),
            height: 1600
        )
    }

    func testBriefDetailViewRendersPopulated() {
        render(
            BriefDetailView(
                brief: minimalPopulatedBrief(),
                fetchedAt: Date(),
                isStale: false
            )
            .environment(config()),
            height: 2400
        )
    }

    // MARK: - Sidereal footer

    func testSiderealFooterRendersWithMagDec() {
        let mag = MagneticDeclination(
            latitude: 43.8, longitude: -91.2,
            declinationDeg: 1.85, inclinationDeg: 70.2,
            totalFieldNT: 53_500, modelDate: 2026.4,
            model: "WMM-2025", observedAt: Date()
        )
        render(SiderealFooter(when: Date(), longitudeEastDeg: -91.2, magnetic: mag))
    }

    func testSiderealFooterRendersWithoutMag() {
        render(SiderealFooter(when: Date(), longitudeEastDeg: 0, magnetic: nil))
    }

    // MARK: - Meshtastic tab

    /// Cold-start render with no persisted history and no BLE connection —
    /// covers the empty-state branches of every section.
    func testMeshtasticViewRendersCold() {
        let service = MeshtasticService(inMemoryStore: true)
        render(
            MeshtasticView()
                .environment(service)
        )
    }

    // MARK: - X-ray flux helper formatting

    func testXRayLetterClassMapping() {
        XCTAssertEqual(XRayFluxPanel.letterClass(forLog10: -2), "X10")
        XCTAssertEqual(XRayFluxPanel.letterClass(forLog10: -3.5), "X")
        XCTAssertEqual(XRayFluxPanel.letterClass(forLog10: -4.5), "M")
        XCTAssertEqual(XRayFluxPanel.letterClass(forLog10: -5.5), "C")
        XCTAssertEqual(XRayFluxPanel.letterClass(forLog10: -6.5), "B")
        XCTAssertEqual(XRayFluxPanel.letterClass(forLog10: -8), "A")
    }
}
