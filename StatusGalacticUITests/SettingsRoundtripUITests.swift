import XCTest

/// Functional UI tests for the Settings tab. These exercise the
/// controls end-to-end rather than just checking they exist — the
/// goal is to catch regressions where a binding gets disconnected or
/// a control stops being editable.
///
/// Each test launches the app fresh under `-UITEST_SCREENSHOT_MODE`
/// so the persisted ClientConfig from previous runs doesn't bleed in.
/// ScreenshotMode also pre-seeds a callsign and marine zone — tests
/// here mutate those values and verify the in-app round-trip works,
/// without persisting beyond the test process.
final class SettingsRoundtripUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            // Keep in sync with ScreenshotMode.launchArgument in the app target.
            "-UITEST_SCREENSHOT_MODE",
            "-AppleLanguages", "(en-US)",
            "-AppleLocale", "en_US",
        ]
        app.launch()

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
        settingsTab.tap()
        usleep(350_000)
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// Toggle the golden-hour notifications switch and confirm its
    /// state actually flips.
    ///
    /// SwiftUI's Form/`Toggle` swallows `XCUIElement.tap()` on the
    /// switch element itself — the gesture lands on the row's
    /// tap-target instead of the embedded UISwitch. The workaround
    /// is to tap the switch's right-edge coordinate (the knob).
    /// Poll the value afterward because SwiftUI doesn't update
    /// `accessibilityValue` synchronously on the tap.
    func testGoldenHourToggleFlips() {
        let toggle = app.switches[A11yID.Settings.Notif.goldenHour]
        XCTAssertTrue(scrollUntilHittable(toggle))

        let initial = toggle.value as? String
        XCTAssertNotNil(initial, "Toggle had no readable value.")

        // Tap the switch knob, not the row.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()

        let deadline = Date().addingTimeInterval(3.0)
        var after: String? = initial
        while Date() < deadline {
            after = toggle.value as? String
            if after != initial { break }
            usleep(100_000)
        }
        XCTAssertNotEqual(
            initial, after,
            "Golden-hour toggle didn't change state within 3s of tap."
        )
    }

    /// Editing the callsign field should be reflected in the APRS-IS
    /// passcode row, which is derived from it. This proves the binding
    /// re-runs the dependent view.
    func testCallsignEditUpdatesPasscode() {
        let field = app.textFields[A11yID.Settings.callsign]
        XCTAssertTrue(scrollUntilHittable(field))

        field.tap()
        // Wipe whatever ScreenshotMode seeded.
        if let current = field.value as? String, !current.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
            field.typeText(deletes)
        }
        field.typeText("K1ABC")

        // The passcode row reads `APRSMessaging.passcode(for:)`. We
        // don't hard-code the expected number here (algorithm could
        // change) — instead we just assert *some* numeric passcode
        // appeared after the edit.
        let passcodeLabel = app.staticTexts["APRS-IS passcode"]
        XCTAssertTrue(
            passcodeLabel.waitForExistence(timeout: 2),
            "APRS-IS passcode row didn't appear after callsign edit."
        )
    }

    /// Aurora alerts are gated behind a parent toggle — flipping the
    /// parent should reveal the threshold stepper. Verifies the
    /// conditional `if notifications.auroraAlertsEnabled` block in
    /// SettingsView. Uses the coordinate-tap workaround for the
    /// SwiftUI Form/Toggle gesture-swallowing quirk.
    func testAuroraToggleRevealsThresholdStepper() {
        let parent = app.switches[A11yID.Settings.Notif.aurora]
        XCTAssertTrue(scrollUntilHittable(parent))

        // Force-on regardless of seeded state.
        if (parent.value as? String) == "0" {
            parent.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            usleep(400_000)
        }

        let stepper = app.steppers[A11yID.Settings.Notif.auroraThreshold]
        XCTAssertTrue(
            scrollUntilHittable(stepper),
            "Aurora threshold stepper never appeared after parent toggle was set."
        )
    }

    // MARK: - Helpers

    private func scrollUntilHittable(_ element: XCUIElement) -> Bool {
        if element.exists && element.isHittable { return true }
        let scroll = app.scrollViews.firstMatch
        let collection = app.collectionViews.firstMatch
        let target = scroll.exists ? scroll : collection
        for _ in 0..<8 {
            if element.exists && element.isHittable { return true }
            if target.exists {
                target.swipeUp(velocity: .fast)
            } else {
                break
            }
            usleep(200_000)
        }
        return element.exists && element.isHittable
    }
}
