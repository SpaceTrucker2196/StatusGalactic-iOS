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
}
