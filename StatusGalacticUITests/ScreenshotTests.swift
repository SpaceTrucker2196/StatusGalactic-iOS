import XCTest

/// Drives the app through every App Store screen and attaches a full-screen
/// PNG for each. Run via `scripts/screenshots.sh`, which feeds the right
/// destinations and pulls the attachments out of the xcresult bundle.
///
/// Each test attaches one screenshot whose `name` matches the function
/// (sans `test_` prefix). The extractor (`scripts/rename_screenshots.py`)
/// writes the PNG to `<device>/<name>.png` — so reordering or renaming
/// tests cascades all the way through to the App Store upload folder.
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += [
            // Keep in sync with ScreenshotMode.launchArgument in the app target.
            "-UITEST_SCREENSHOT_MODE",
            // Deterministic en-US formatting on every shot.
            "-AppleLanguages", "(en-US)",
            "-AppleLocale", "en_US",
        ]
        // Belt-and-braces: kill any stragglers from the previous test before
        // the fresh launch. Xcode 26 + iOS 26 sim sporadically SIGKILLs the
        // next launch when the previous process hasn't fully torn down yet.
        app.terminate()
        app.launch()

        // Wait for the four-tab chrome to settle. Brief loads the seeded
        // hero fixture synchronously, so the tab bar should appear within
        // a couple of seconds.
        let firstTab = app.tabBars.buttons["Brief"].firstMatch
        XCTAssertTrue(
            firstTab.waitForExistence(timeout: 10),
            "Brief tab never appeared — ScreenshotMode seeding may not be wired up."
        )
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - RF tab (the lead story)
    //
    // Each RF shot drops the scroll N swipes from the top of the list:
    //
    //   0 — Your station, Conversations, Bulletins
    //   1 — Bulletins tail + HF Band Conditions panel ("aurora-kp" story)
    //   2 — Parks On The Air + Summits On The Air
    //   3 — DX Cluster
    //
    // The seed data in `ScreenshotMode` is the contract: as long as RF
    // sections render in the order APRSView lays them out, these depths
    // land on the right surface every time.

    func test_01_rf_hero() {
        tap(tab: "RF")
        snapshot("01-rf-hero")
    }

    func test_02_aurora_kp() {
        tap(tab: "RF")
        swipeMain(count: 1)
        snapshot("02-aurora-kp")
    }

    func test_03_pota_sota() {
        tap(tab: "RF")
        swipeMain(count: 2)
        snapshot("03-pota-sota")
    }

    func test_04_dx_cluster() {
        tap(tab: "RF")
        swipeMain(count: 3)
        snapshot("04-dx-cluster")
    }

    // MARK: - Callsigns

    func test_05_callsigns() {
        tap(tab: "Callsigns")
        snapshot("05-callsigns")
    }

    func test_06_callsign_detail() {
        tap(tab: "Callsigns")
        // First seeded callsign is W1AW. Tap into the detail view.
        let row = app.staticTexts["W1AW"].firstMatch
        if row.waitForExistence(timeout: 5) {
            row.tap()
            // Give the MapKit pin a beat to settle so the screenshot
            // doesn't catch the map mid-zoom.
            usleep(900_000)
        }
        snapshot("06-callsign-detail")
    }

    // MARK: - Brief
    //
    // BriefDetailView's section order: Sun → Earth → Marine → Space →
    // Aurora → Moon → Planets → CrewedLaunches → Launches → … so:
    //
    //   0 — Sun + Earth Weather hero
    //   1 — Sun-strip + twilight times
    //   2 — Marine Weather GMZ033
    //   5 — Upcoming Launches

    func test_07_brief_hero() {
        tap(tab: "Brief")
        snapshot("07-brief-hero")
    }

    func test_08_sun_twilight() {
        tap(tab: "Brief")
        swipeMain(count: 1)
        snapshot("08-sun-twilight")
    }

    func test_09_launches() {
        tap(tab: "Brief")
        swipeMain(count: 5)
        snapshot("09-launches")
    }

    func test_10_marine() {
        tap(tab: "Brief")
        swipeMain(count: 2)
        snapshot("10-marine")
    }

    // MARK: - Widget (faux home screen)

    /// Shot 11. XCUITest can't drive SpringBoard, so we launch the app
    /// with an extra flag that swaps the root view for
    /// `WidgetHomeScreenPreview` — a SwiftUI render of the medium
    /// widget on a dark home-screen background. The end result reads
    /// as "home screen with widget" in the gallery.
    func test_11_widget() {
        // Fresh launch with the widget-preview flag.
        let widgetApp = XCUIApplication()
        widgetApp.launchArguments += [
            "-UITEST_SCREENSHOT_MODE",
            "-UITEST_WIDGET_PREVIEW",
            "-AppleLanguages", "(en-US)",
            "-AppleLocale", "en_US",
        ]
        widgetApp.terminate()
        widgetApp.launch()
        // Let the seeded brief settle into the widget view.
        usleep(800_000)
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "11-widget"
        attachment.lifetime = .keepAlways
        add(attachment)
        widgetApp.terminate()
    }

    // MARK: - Settings

    func test_12_settings() {
        tap(tab: "Settings")
        snapshot("12-settings")
    }

    // MARK: - Helpers

    /// Tap a tab bar button by accessibility label. The four tabs always
    /// render as a UITabBar on iPhone — no overflow / "More" handling
    /// needed since we have exactly four entries.
    private func tap(tab label: String) {
        let button = app.tabBars.buttons[label]
        XCTAssertTrue(
            button.waitForExistence(timeout: 5),
            "Tab '\(label)' not found in tab bar."
        )
        button.tap()
        // SwiftUI cross-fades the tab content; capturing instantly catches
        // a half-faded view on a cold device. 350ms is enough to settle.
        usleep(350_000)
    }

    /// Swipe the active tab's main list upward `count` times. Each swipe
    /// advances roughly one screen of content. Picked over text-anchor
    /// scrolling because (a) some section headers carry runtime data
    /// ("Marine Weather GMZ033") and (b) XCUI's `isHittable` check on a
    /// header bar still in the visible frame returns true before any
    /// scroll has happened, making anchor-loops no-op.
    private func swipeMain(count: Int) {
        let scroll = app.collectionViews.firstMatch
        let fallbackScroll = app.scrollViews.firstMatch
        let target: XCUIElement = scroll.exists ? scroll : fallbackScroll
        guard target.exists else { return }
        for _ in 0..<count {
            target.swipeUp(velocity: .fast)
            usleep(150_000)
        }
        // Let SwiftUI settle so the screenshot doesn't catch mid-animation.
        usleep(350_000)
    }

    private func snapshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
