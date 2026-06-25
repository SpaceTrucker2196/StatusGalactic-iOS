import XCTest
@testable import StatusGalactic

/// Coverage for the brief-section ordering helpers — both the
/// persistence reconciler and the visible-list → full-order move
/// translator that drives `BriefDetailView`'s `.onMove` handler.
final class BriefSectionReconcileTests: XCTestCase {

    /// Default order must list every case exactly once, with no
    /// duplicates. If a future case is added without being put in
    /// `defaultOrder`, the reconciler will still surface it (via the
    /// `missing` pass), but the test catches the omission early.
    func testDefaultOrderCoversEveryCase() {
        let defaults = BriefSection.defaultOrder
        XCTAssertEqual(defaults.count, BriefSection.allCases.count,
                       "defaultOrder is missing or duplicating cases")
        XCTAssertEqual(Set(defaults), Set(BriefSection.allCases),
                       "defaultOrder doesn't enumerate every case")
        XCTAssertEqual(defaults.count, Set(defaults).count,
                       "defaultOrder contains duplicates")
    }

    /// An empty persistence (first launch, or fresh install) yields
    /// the default order verbatim.
    func testReconcileEmptyReturnsDefaults() {
        XCTAssertEqual(
            BriefSection.reconcile(persistedRawValues: []),
            BriefSection.defaultOrder
        )
    }

    /// A persisted list that mirrors the defaults round-trips unchanged.
    func testReconcileRoundTripDefaults() {
        let raws = BriefSection.defaultOrder.map(\.rawValue)
        XCTAssertEqual(
            BriefSection.reconcile(persistedRawValues: raws),
            BriefSection.defaultOrder
        )
    }

    /// A user-permuted order is preserved by reconcile when every case
    /// is present.
    func testReconcilePreservesUserPermutation() {
        var permuted = BriefSection.defaultOrder
        permuted.swapAt(0, permuted.count - 1)
        XCTAssertEqual(
            BriefSection.reconcile(persistedRawValues: permuted.map(\.rawValue)),
            permuted
        )
    }

    /// Unknown raw values (e.g. a section removed in a future release)
    /// are silently dropped.
    func testReconcileDropsUnknownRawValues() {
        let raws = ["sun", "definitely_not_a_section", "moon", "another_bogus"]
        let out = BriefSection.reconcile(persistedRawValues: raws)
        XCTAssertEqual(out.prefix(2), [.sun, .moon])
        XCTAssertEqual(out.count, BriefSection.allCases.count,
                       "unknowns should be dropped, not counted as cases")
    }

    /// New cases shipped after the persisted list was written get
    /// appended in their default-order positions at the tail.
    func testReconcileAppendsMissingCases() {
        // Simulate a persisted list missing several known cases.
        let known: [BriefSection] = [.sun, .moon, .planets]
        let raws = known.map(\.rawValue)
        let out = BriefSection.reconcile(persistedRawValues: raws)

        XCTAssertEqual(out.prefix(3), [.sun, .moon, .planets])
        let appended = Array(out.dropFirst(3))
        let expectedAppended = BriefSection.defaultOrder.filter { !known.contains($0) }
        XCTAssertEqual(appended, expectedAppended,
                       "missing cases should arrive in default-order order")
    }

    /// Combined: known + unknown + missing should all be handled in
    /// one pass.
    func testReconcileMixedCase() {
        let raws = ["sun", "bogus", "moon", "earthquakes"]
        let out = BriefSection.reconcile(persistedRawValues: raws)
        XCTAssertEqual(out.prefix(3), [.sun, .moon, .earthquakes])
        XCTAssertEqual(out.count, BriefSection.allCases.count)
        XCTAssertEqual(Set(out), Set(BriefSection.allCases))
    }
}

final class BriefSectionMoveTests: XCTestCase {

    /// When every section is visible, moving an item should match the
    /// standard `Array.move(fromOffsets:toOffset:)` semantics.
    func testMoveWithAllSectionsVisible() {
        let order: [BriefSection] = [.sun, .moon, .planets, .earthquakes]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: order,
            from: IndexSet(integer: 0),
            to: 3
        )
        XCTAssertEqual(moved, [.moon, .planets, .sun, .earthquakes])
    }

    /// Moving from index 0 to index 0 (no-op) returns the original.
    func testMoveToSameIndexIsNoOp() {
        let order: [BriefSection] = [.sun, .moon, .planets]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: order,
            from: IndexSet(integer: 1),
            to: 1
        )
        XCTAssertEqual(moved, order)
    }

    /// Moving to the very end (destination == visible.count) lands the
    /// item at the tail of the full order.
    func testMoveToEnd() {
        let order: [BriefSection] = [.sun, .moon, .planets]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: order,
            from: IndexSet(integer: 0),
            to: order.count
        )
        XCTAssertEqual(moved, [.moon, .planets, .sun])
    }

    /// The critical case: when invisible sections sit between the
    /// visible ones, moving a visible section past another visible
    /// section must preserve the relative positions of the invisibles.
    ///
    ///   full:    [A, X, B, Y, C]   (X, Y invisible)
    ///   visible: [A,    B,    C]
    ///   move A → past B (destination=1 in visible) ⇒
    ///   full:    [X, B, A, Y, C]   (A lands before C; X and Y stay
    ///                               in their original relative slots)
    func testMovePreservesInvisibleNeighbours() {
        let order: [BriefSection] = [.sun, .moon, .planets, .apod, .earthquakes]
        let visible: [BriefSection] = [.sun, .planets, .earthquakes]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: visible,
            from: IndexSet(integer: 0),
            to: 2
        )
        // .sun lands at the slot where .earthquakes (the anchor) sat,
        // i.e. full-index 4. After remove+insert, the result is:
        XCTAssertEqual(moved, [.moon, .planets, .apod, .sun, .earthquakes])
    }

    /// Moving the last visible to the front pushes it ahead of all
    /// other visibles in the full order, while the invisibles slide
    /// down naturally.
    func testMoveLastVisibleToFront() {
        let order: [BriefSection] = [.sun, .moon, .planets, .apod, .earthquakes]
        let visible: [BriefSection] = [.sun, .planets, .earthquakes]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: visible,
            from: IndexSet(integer: 2),
            to: 0
        )
        // .earthquakes goes to the front; .moon and .apod keep their
        // relative positions trailing their neighbours.
        XCTAssertEqual(moved, [.earthquakes, .sun, .moon, .planets, .apod])
    }

    /// Moving a visible section past the *end* of the visible list
    /// when invisibles trail it leaves those invisibles in place at
    /// the tail.
    func testMoveVisibleToEndKeepsInvisibleTail() {
        let order: [BriefSection] = [.sun, .moon, .planets, .apod]
        // .moon and .apod are invisible.
        let visible: [BriefSection] = [.sun, .planets]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: visible,
            from: IndexSet(integer: 0),
            to: 2
        )
        // .sun goes to the end of the full order; .moon and .apod
        // shift up one each.
        XCTAssertEqual(moved, [.moon, .planets, .apod, .sun])
    }

    /// Empty source index set is a no-op rather than a crash.
    func testEmptySourceIsNoOp() {
        let order: [BriefSection] = [.sun, .moon, .planets]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: order,
            from: IndexSet(),
            to: 1
        )
        XCTAssertEqual(moved, order)
    }

    /// Source pointing off the end of visible is a no-op.
    func testOutOfRangeSourceIsNoOp() {
        let order: [BriefSection] = [.sun, .moon, .planets]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: order,
            from: IndexSet(integer: 99),
            to: 0
        )
        XCTAssertEqual(moved, order)
    }

    /// A move where the visible[destination] is the same kind being
    /// moved (caused by destination pointing into a visible whose
    /// pre-move position equals source) should be a no-op or at least
    /// non-destructive.
    func testMoveDestinationEqualsSelfIsBenign() {
        let order: [BriefSection] = [.sun, .moon, .planets]
        let moved = BriefSection.moveInFullOrder(
            order: order,
            visible: order,
            from: IndexSet(integer: 2),
            to: 2
        )
        XCTAssertEqual(moved, order)
    }

    /// Multiple back-to-back reorders compose correctly — what a user
    /// drag session looks like in practice.
    func testMultipleReordersCompose() {
        var order = BriefSection.defaultOrder

        // First drag: move .earthquakes to the very front.
        let earthquakesIdx = order.firstIndex(of: .earthquakes)!
        order = BriefSection.moveInFullOrder(
            order: order,
            visible: order,
            from: IndexSet(integer: earthquakesIdx),
            to: 0
        )
        XCTAssertEqual(order.first, .earthquakes)

        // Second drag: move .apod immediately after .earthquakes
        // (destination = 1 in visible).
        let apodIdx = order.firstIndex(of: .apod)!
        order = BriefSection.moveInFullOrder(
            order: order,
            visible: order,
            from: IndexSet(integer: apodIdx),
            to: 1
        )
        XCTAssertEqual(order.prefix(2), [.earthquakes, .apod])

        // Order still includes every case exactly once.
        XCTAssertEqual(Set(order), Set(BriefSection.allCases))
        XCTAssertEqual(order.count, BriefSection.allCases.count)
    }
}

final class BriefSectionVisibilityTests: XCTestCase {

    /// Nothing hidden, every section has content — visible equals
    /// order, preserving it verbatim.
    func testNoHiddenAllContent() {
        let order: [BriefSection] = [.sun, .moon, .planets, .earthquakes]
        let result = BriefSection.visible(
            in: order, hidden: [], hasContent: { _ in true }
        )
        XCTAssertEqual(result, order)
    }

    /// Hidden sections are excluded and the remaining order is
    /// preserved exactly.
    func testHiddenSectionsExcluded() {
        let order: [BriefSection] = [.sun, .moon, .planets, .earthquakes]
        let result = BriefSection.visible(
            in: order,
            hidden: [.moon, .earthquakes],
            hasContent: { _ in true }
        )
        XCTAssertEqual(result, [.sun, .planets])
    }

    /// Sections without content are excluded even when not hidden.
    func testEmptyContentExcluded() {
        let order: [BriefSection] = [.sun, .moon, .planets]
        let result = BriefSection.visible(
            in: order,
            hidden: [],
            hasContent: { $0 != .moon }
        )
        XCTAssertEqual(result, [.sun, .planets])
    }

    /// Hidden + no-content union: a section in either set is excluded.
    func testHiddenAndEmptyUnion() {
        let order: [BriefSection] = [.sun, .moon, .planets, .earthquakes]
        let result = BriefSection.visible(
            in: order,
            hidden: [.sun],
            hasContent: { $0 != .planets }
        )
        XCTAssertEqual(result, [.moon, .earthquakes])
    }

    /// Hiding every section yields an empty visible list — the brief
    /// renders nothing, which is exactly what the user asked for.
    func testHidingEverythingClearsVisible() {
        let order: [BriefSection] = [.sun, .moon, .planets]
        let result = BriefSection.visible(
            in: order,
            hidden: Set(order),
            hasContent: { _ in true }
        )
        XCTAssertEqual(result, [])
    }

    /// Hiding a section the user never had in their order is harmless
    /// — `hidden` is just a filter, not authoritative.
    func testHiddenSectionNotInOrderIsHarmless() {
        let order: [BriefSection] = [.sun, .moon]
        let result = BriefSection.visible(
            in: order,
            hidden: [.earthquakes],
            hasContent: { _ in true }
        )
        XCTAssertEqual(result, [.sun, .moon])
    }

    /// Hidden sections still keep their slot in the persisted order —
    /// unhiding restores them at the same position. The visibility
    /// helper is order-preserving, so this reduces to a round-trip
    /// over hide / unhide.
    func testUnhideRestoresOriginalPosition() {
        let order: [BriefSection] = [.sun, .moon, .planets, .earthquakes]
        let withHidden = BriefSection.visible(
            in: order, hidden: [.moon], hasContent: { _ in true }
        )
        let restored = BriefSection.visible(
            in: order, hidden: [], hasContent: { _ in true }
        )
        XCTAssertEqual(withHidden, [.sun, .planets, .earthquakes])
        XCTAssertEqual(restored, order)
    }
}
