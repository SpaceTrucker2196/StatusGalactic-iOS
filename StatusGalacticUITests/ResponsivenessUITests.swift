import XCTest

/// End-to-end responsiveness tests that drive the actual app in the
/// simulator. The goal here is *not* to assert the brief loads — that
/// depends on network and location permission which UI tests can't
/// reliably provision — but rather to prove the UI stays interactive
/// during whatever state the brief is in.
///
/// A blocked main thread would cause `XCUIElement.tap()` and
/// `waitForExistence` to time out, so the assertions below double as
/// hang detectors.
final class ResponsivenessUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    /// The nav bar must come up within a short window of launch — proof
    /// the SwiftUI scene mounts without being blocked by anything in
    /// StatusGalacticApp.task (notifications refresh + ImageCache purge).
    func testNavBarAppearsQuickly() {
        let title = app.navigationBars["SITREP Galactic"]
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Nav bar didn't appear within 5s — app likely blocked at launch."
        )
    }

    /// Refresh button must be reachable (tap returns) even when the brief
    /// is mid-refresh against real or stalled network. A blocked main
    /// thread makes tap() hang past the implicit XCUI timeout (~75s).
    /// We probe it twice to also exercise the disabled→re-enabled cycle.
    func testRefreshButtonStaysResponsive() {
        let title = app.navigationBars["SITREP Galactic"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))

        // The toolbar carries the source picker on the left and refresh
        // on the right. The refresh button's image is arrow.clockwise; we
        // look it up by accessibility identifier where possible and by
        // image fallback otherwise.
        let candidates = title.buttons.allElementsBoundByIndex
        guard let refresh = candidates.last(where: { $0.label.contains("arrow") || $0.identifier == "refresh" })
            ?? candidates.last
        else {
            XCTFail("Could not find refresh button in nav bar.")
            return
        }

        let started = Date()
        refresh.tap()
        let firstTap = Date().timeIntervalSince(started)
        XCTAssertLessThan(
            firstTap, 5,
            "Refresh tap took \(firstTap)s — likely hung on the main thread."
        )

        // Hit it again to confirm the disabled→re-enabled transition works
        // without freezing the UI. Even if the second tap is a no-op due
        // to the disabled-while-refreshing state, the call should return
        // immediately, not hang.
        _ = refresh.waitForExistence(timeout: 5)
        let secondStart = Date()
        refresh.tap()
        XCTAssertLessThan(Date().timeIntervalSince(secondStart), 5)
    }

    /// Scrolling the main brief should be smooth regardless of refresh
    /// state. A blocked main thread would stall the swipe gesture's
    /// event delivery.
    func testMainScrollViewRespondsToSwipe() {
        let title = app.navigationBars["SITREP Galactic"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))

        // The brief renders as a List inside a NavigationStack; the empty
        // states render as ContentUnavailableView. Either is swipeable.
        let scrollable = app.scrollViews.firstMatch
        let collection = app.collectionViews.firstMatch
        let target = scrollable.exists ? scrollable : collection

        if target.exists {
            let started = Date()
            target.swipeUp()
            XCTAssertLessThan(
                Date().timeIntervalSince(started), 5,
                "Swipe didn't return — main thread likely blocked."
            )
            target.swipeDown()
        }
    }

    /// Cumulative responsiveness probe: tap refresh, then issue rapid
    /// interactions and confirm each completes within a tight budget.
    /// This is the test that catches the kind of multi-second hang the
    /// user reported on a slow network.
    func testInteractionsStayUnderBudgetDuringRefresh() {
        let title = app.navigationBars["SITREP Galactic"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))

        // Kick off a refresh.
        if let refresh = title.buttons.allElementsBoundByIndex.last {
            refresh.tap()
        }

        // While refresh is in flight, every interaction below should
        // complete within 3 seconds. If the main thread were pinned, XCUI
        // would queue and eventually time out at ~75s.
        let scrollable = app.scrollViews.firstMatch
        let collection = app.collectionViews.firstMatch
        let target = scrollable.exists ? scrollable : collection

        for i in 0..<3 {
            let started = Date()
            if target.exists {
                target.swipeUp()
            } else {
                // No content yet; still ensure the app is alive by
                // re-querying the nav bar.
                _ = title.waitForExistence(timeout: 1)
            }
            let elapsed = Date().timeIntervalSince(started)
            XCTAssertLessThan(
                elapsed, 3,
                "Interaction \(i) took \(elapsed)s during refresh — main thread blocked."
            )
        }
    }
}
