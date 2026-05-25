import XCTest

/// Accessibility smoke tests for every tab.
///
/// Strategy:
///   - Launch under `-UITEST_SCREENSHOT_MODE` so the four tabs render
///     deterministic seeded content (callsign set, marine zone set,
///     hero brief loaded). That lets us exercise buttons that gate on
///     `!config.myCallsign.isEmpty` (RF compose, RF refresh) and lets
///     the Brief tab skip its location-permission empty state.
///   - For each interactive surface we check three things:
///       1. it's discoverable by `accessibilityIdentifier`
///       2. it's hittable (rules out covered/off-screen elements)
///       3. its `label` is non-empty (rules out icon-only buttons that
///          would be unusable under VoiceOver)
///
/// If you add a new interactive surface, add its identifier to
/// `AccessibilityIdentifiers.swift` and a check here. Both files are
/// compiled into the test target so the constant references stay
/// stable.
final class AccessibilityUITests: XCTestCase {

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

        // The four-tab chrome must come up before we can probe anything.
        let firstTab = app.tabBars.buttons["Brief"].firstMatch
        XCTAssertTrue(
            firstTab.waitForExistence(timeout: 10),
            "Tab bar never appeared — ScreenshotMode seeding may not be wired up."
        )
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Tab bar

    /// Every tab must be findable by its VoiceOver label and reachable
    /// with a single tap. This is the floor — if this fails, no other
    /// tab-specific check can succeed.
    func testTabBarLabelsAreAccessible() {
        for label in ["Brief", "RF", "Callsigns", "Settings"] {
            let tab = app.tabBars.buttons[label]
            XCTAssertTrue(tab.exists, "Tab \"\(label)\" missing from tab bar.")
            XCTAssertTrue(tab.isHittable, "Tab \"\(label)\" not hittable.")
            tab.tap()
            usleep(250_000)
        }
    }

    // MARK: - Brief

    func testBriefTabAccessibilitySurfaces() {
        tap(tab: "Brief")

        // Refresh button — icon-only, must carry an accessibility label.
        assertInteractive(
            id: A11yID.Brief.refresh,
            description: "Brief refresh button"
        )

        // Source picker — Menu surfaced as a button.
        assertInteractive(
            id: A11yID.Brief.sourcePicker,
            description: "Brief source picker"
        )
    }

    // MARK: - RF

    func testRFTabAccessibilitySurfaces() {
        tap(tab: "RF")

        assertInteractive(
            id: A11yID.RF.refresh,
            description: "RF refresh button",
            // Refresh may already be running when we land on the tab.
            allowDisabled: true
        )
        assertInteractive(
            id: A11yID.RF.compose,
            description: "RF compose button"
        )
    }

    // MARK: - Callsigns

    func testCallsignsTabAccessibilitySurfaces() {
        tap(tab: "Callsigns")

        // Seeded list has four callsigns, so the toolbar Add + Edit
        // buttons should both be present.
        assertInteractive(
            id: A11yID.Callsigns.addToolbar,
            description: "Callsigns toolbar Add button"
        )
        assertInteractive(
            id: A11yID.Callsigns.edit,
            description: "Callsigns Edit button"
        )

        // First seeded callsign row.
        let row = app.buttons["callsigns.row.W1AW"]
            .firstMatch
        XCTAssertTrue(
            row.waitForExistence(timeout: 3),
            "Seeded W1AW callsign row not found by identifier."
        )
        XCTAssertTrue(row.isHittable, "W1AW row not hittable.")
    }

    func testCallsignsAddFormAccessibility() {
        tap(tab: "Callsigns")

        let addButton = app.buttons[A11yID.Callsigns.addToolbar]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        let callField = app.textFields[A11yID.Callsigns.AddForm.call]
        XCTAssertTrue(
            callField.waitForExistence(timeout: 3),
            "Add Callsign sheet didn't appear or call field is missing its identifier."
        )

        // Every form field + button should be addressable.
        for id in [
            A11yID.Callsigns.AddForm.call,
            A11yID.Callsigns.AddForm.label,
            A11yID.Callsigns.AddForm.notes,
        ] {
            let field = app.textFields[id]
            XCTAssertTrue(
                field.exists,
                "Add Callsign field \"\(id)\" missing."
            )
        }
        for id in [
            A11yID.Callsigns.AddForm.save,
            A11yID.Callsigns.AddForm.cancel,
        ] {
            let button = app.buttons[id]
            XCTAssertTrue(
                button.exists,
                "Add Callsign button \"\(id)\" missing."
            )
        }

        // Dismiss so we don't leave the sheet stranded for the next test.
        app.buttons[A11yID.Callsigns.AddForm.cancel].tap()
    }

    // MARK: - Settings
    //
    // The Settings form is long — eight sections. `scrollUntilHittable`
    // only scrolls down, so we walk the form in screen order
    // (Notifications → APRS → NASA → N2YO → Marine → Imagery →
    // Network → Location → About) and split the verification across
    // smaller tests so a failure points at one section rather than
    // crashing-with-kill after a 22-second scroll dance.

    func testSettings_Notifications() {
        tap(tab: "Settings")
        for id in [
            A11yID.Settings.Notif.goldenHour,
            A11yID.Settings.Notif.astroDusk,
            A11yID.Settings.Notif.aurora,
            A11yID.Settings.Notif.storm,
        ] {
            let toggle = app.switches[id]
            XCTAssertTrue(
                scrollUntilHittable(toggle),
                "Notifications toggle \"\(id)\" not found / not hittable."
            )
        }
    }

    func testSettings_APRSandKeys() {
        tap(tab: "Settings")
        XCTAssertTrue(
            scrollUntilFieldExists(id: A11yID.Settings.callsign),
            "Callsign field not found."
        )
        // SecureField exposure varies — SwiftUI sometimes lands them in
        // `secureTextFields`, sometimes in `textFields`, depending on
        // focus state and iOS version. The scroll loop re-queries both
        // pools each iteration so we don't bind to the wrong query
        // before the field even materializes.
        for id in [
            A11yID.Settings.aprsKey,
            A11yID.Settings.nasaKey,
            A11yID.Settings.n2yoKey,
        ] {
            XCTAssertTrue(
                scrollUntilFieldExists(id: id),
                "API key field \"\(id)\" not found."
            )
        }
    }

    func testSettings_MarineImageryNetwork() {
        tap(tab: "Settings")
        XCTAssertTrue(
            scrollUntilHittable(app.buttons[A11yID.Settings.marineZone]),
            "Marine zone navigation row not found / not hittable."
        )
        XCTAssertTrue(
            scrollUntilHittable(app.switches[A11yID.Settings.apodToggle]),
            "APOD toggle not found / not hittable."
        )
        XCTAssertTrue(
            scrollUntilHittable(app.buttons[A11yID.Settings.clearCache]),
            "Clear image cache button not found / not hittable."
        )
        XCTAssertTrue(
            scrollUntilHittable(app.textFields[A11yID.Settings.userAgent]),
            "User-Agent field not found / not hittable."
        )
    }

    func testSettings_LocationAndAbout() {
        tap(tab: "Settings")
        XCTAssertTrue(
            scrollUntilHittable(app.buttons[A11yID.Settings.refreshLocation]),
            "Refresh location button not found / not hittable."
        )
        XCTAssertTrue(
            scrollUntilHittable(app.buttons[A11yID.Settings.feedback]),
            "Feedback button not found / not hittable."
        )
    }

    // MARK: - Helpers

    private func tap(tab label: String) {
        let button = app.tabBars.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        usleep(350_000)
    }

    /// Assert a control identified by `id` exists, is hittable, and has
    /// a non-empty `label` (so VoiceOver users have something to read).
    /// Looks the element up across the most common interactive pools.
    private func assertInteractive(
        id: String,
        description: String,
        allowDisabled: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let pools: [XCUIElementQuery] = [
            app.buttons,
            app.switches,
            app.textFields,
            app.secureTextFields,
            app.steppers,
            app.otherElements,
        ]
        var hit: XCUIElement?
        for pool in pools {
            let candidate = pool[id]
            if candidate.exists {
                hit = candidate
                break
            }
        }
        guard let element = hit else {
            XCTFail(
                "\(description) (id=\(id)) not found in any interactive pool.",
                file: file, line: line
            )
            return
        }
        XCTAssertTrue(
            element.waitForExistence(timeout: 3),
            "\(description) (id=\(id)) never appeared.",
            file: file, line: line
        )
        if !allowDisabled {
            XCTAssertTrue(
                element.isHittable,
                "\(description) (id=\(id)) is not hittable.",
                file: file, line: line
            )
        }
        XCTAssertFalse(
            element.label.isEmpty,
            "\(description) (id=\(id)) has no accessibility label — VoiceOver would read nothing.",
            file: file, line: line
        )
    }

    /// Swipe the visible scroll/collection view up a few times to bring
    /// `element` into the hittable region, then verify it. Used for
    /// long Forms (Settings) where some controls sit below the fold.
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

    /// Weaker version of `scrollUntilHittable` — settles for the element
    /// existing in the accessibility tree, without insisting it be
    /// hittable. SecureField rows in SwiftUI Forms sometimes report
    /// `isHittable == false` even when they're fully on screen.
    private func scrollUntilExists(_ element: XCUIElement) -> Bool {
        if element.exists { return true }
        let scroll = app.scrollViews.firstMatch
        let collection = app.collectionViews.firstMatch
        let target = scroll.exists ? scroll : collection
        for _ in 0..<8 {
            if element.exists { return true }
            if target.exists {
                target.swipeUp(velocity: .fast)
            } else {
                break
            }
            usleep(200_000)
        }
        return element.exists
    }

    /// Find a TextField-shaped control by identifier, checking both the
    /// `textFields` and `secureTextFields` pools — SecureField is sometimes
    /// exposed in one, sometimes the other, depending on iOS version and
    /// focus state.
    private func findField(id: String) -> XCUIElement {
        let secure = app.secureTextFields[id]
        if secure.exists { return secure }
        return app.textFields[id]
    }

    /// Scroll until *either* a SecureField *or* a TextField with the
    /// given identifier exists. Re-queries both pools on every iteration,
    /// which is necessary because virtualized SwiftUI rows only mount
    /// once they scroll into the visible region.
    private func scrollUntilFieldExists(id: String) -> Bool {
        func found() -> Bool {
            app.secureTextFields[id].exists || app.textFields[id].exists
        }
        if found() { return true }
        let scroll = app.scrollViews.firstMatch
        let collection = app.collectionViews.firstMatch
        let target = scroll.exists ? scroll : collection
        for _ in 0..<8 {
            if found() { return true }
            if target.exists {
                target.swipeUp(velocity: .fast)
            } else {
                break
            }
            usleep(200_000)
        }
        return found()
    }
}
