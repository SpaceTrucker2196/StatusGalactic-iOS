import XCTest
import SwiftUI
import WidgetKit
@testable import StatusGalactic

/// Locks the panel-size ↔ grid-span ↔ widget-family mapping so a future
/// refactor can't silently break the iPad grid packer or the widget bundle.
final class PanelKitTests: XCTestCase {

    func testPanelSizeSpansMatchGridUnits() {
        XCTAssertEqual(PanelSize.small.span.cols, 1)
        XCTAssertEqual(PanelSize.small.span.rows, 1)
        XCTAssertEqual(PanelSize.wide.span.cols,  2)
        XCTAssertEqual(PanelSize.wide.span.rows,  1)
        XCTAssertEqual(PanelSize.tall.span.cols,  1)
        XCTAssertEqual(PanelSize.tall.span.rows,  2)
        XCTAssertEqual(PanelSize.large.span.cols, 2)
        XCTAssertEqual(PanelSize.large.span.rows, 2)
    }

    func testWidgetFamilyMapsToPanelSize() {
        XCTAssertEqual(WidgetFamily.systemSmall.panelSize,      .small)
        XCTAssertEqual(WidgetFamily.systemMedium.panelSize,     .wide)
        XCTAssertEqual(WidgetFamily.systemLarge.panelSize,      .large)
        // Extra-large (iPad-only) collapses to `.large` for now — this
        // test locks that decision so future changes are deliberate.
        XCTAssertEqual(WidgetFamily.systemExtraLarge.panelSize, .large)
    }

    func testPanelKindDisplayNamesAreStable() {
        // These strings are user-visible in widget pickers and the iPad
        // grid header. Pinning them here so a rename is a conscious act.
        XCTAssertEqual(PanelKind.brief.displayName,            "Brief")
        XCTAssertEqual(PanelKind.solarTerrestrial.displayName, "Solar-Terrestrial")
        XCTAssertEqual(PanelKind.tides.displayName,            "Tides")
    }

    // MARK: - Panel renderers

    /// Instantiating each shared panel at every size must not crash even
    /// with a nil brief. If a future refactor breaks any panel's empty
    /// state, this test catches it before it ships to a widget slot.
    func testEveryPanelRendersAtEverySizeWithNilBrief() {
        for size in PanelSize.allCases {
            _ = SolarPanel(size: size, brief: nil).body
            _ = BriefPanel(size: size, brief: nil).body
            _ = TidesPanel(size: size, brief: nil).body
        }
    }

    // MARK: - PanelLayoutStore

    func testLayoutStoreEmptyReturnsFallback() {
        PanelLayoutStore.clear()
        let fallback: [PanelTile] = [.init(kind: .brief, size: .wide)]
        let loaded = PanelLayoutStore.load(fallback: fallback)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].kind, .brief)
        XCTAssertEqual(loaded[0].size, .wide)
    }

    func testLayoutStoreRoundTripPreservesTilesAndIds() {
        PanelLayoutStore.clear()
        defer { PanelLayoutStore.clear() }

        let original: [PanelTile] = [
            .init(kind: .brief,            size: .wide),
            .init(kind: .solarTerrestrial, size: .tall),
            .init(kind: .tides,            size: .large),
        ]
        PanelLayoutStore.save(original)

        let loaded = PanelLayoutStore.load(fallback: [])
        XCTAssertEqual(loaded.count, 3)
        XCTAssertEqual(loaded.map(\.kind), original.map(\.kind))
        XCTAssertEqual(loaded.map(\.size), original.map(\.size))
        // Ids must round-trip so tile identity is stable across launches.
        XCTAssertEqual(loaded.map(\.id), original.map(\.id))
    }

    func testLayoutStoreCorruptDataReturnsFallback() {
        // Write garbage under the store's key, then confirm load falls
        // back cleanly instead of throwing / crashing.
        SharedDefaults.store.set(Data([0xFF, 0x00, 0x42]),
                                 forKey: PanelLayoutStore.key)
        defer { PanelLayoutStore.clear() }
        let fallback: [PanelTile] = [.init(kind: .tides, size: .small)]
        let loaded = PanelLayoutStore.load(fallback: fallback)
        XCTAssertEqual(loaded, fallback)
    }

    /// Solar has bespoke `.tall` and `.large` renderers — this pins the
    /// four Solar sub-view types actually exist as distinct SwiftUI
    /// views. If a future refactor deletes one and re-collapses to
    /// small/medium, this catches it.
    func testSolarHasFourDistinctSubviewTypes() {
        let types: [Any.Type] = [
            SolarSmallView.self,
            SolarMediumView.self,
            SolarTallView.self,
            SolarLargeView.self,
        ]
        let names = Set(types.map { "\($0)" })
        XCTAssertEqual(names.count, 4, "Expected 4 distinct Solar sub-views, got \(names)")
    }

    // MARK: - PanelGrid packing

    func testPackingSingleSmallSitsAtOrigin() {
        let tiles = [PanelTile(kind: .solarTerrestrial, size: .small)]
        let placements = PanelGrid<AnyView>.pack(tiles: tiles, columns: 2)
        XCTAssertEqual(placements.count, 1)
        XCTAssertEqual(placements[0].row, 0)
        XCTAssertEqual(placements[0].col, 0)
        XCTAssertEqual(placements[0].cols, 1)
        XCTAssertEqual(placements[0].rows, 1)
    }

    func testPackingTwoSmallsFillFirstRow() {
        let tiles = [
            PanelTile(kind: .solarTerrestrial, size: .small),
            PanelTile(kind: .solarTerrestrial, size: .small),
        ]
        let placements = PanelGrid<AnyView>.pack(tiles: tiles, columns: 2)
        XCTAssertEqual(placements.map(\.col), [0, 1])
        XCTAssertEqual(placements.map(\.row), [0, 0])
    }

    func testPackingWideForcesNewRowWhenOneColumnLeft() {
        // small(1×1) occupies (0,0). wide(2×1) can't fit in row 0 col 1
        // (only one column left), so it wraps to row 1 col 0.
        let tiles = [
            PanelTile(kind: .solarTerrestrial, size: .small),
            PanelTile(kind: .solarTerrestrial, size: .wide),
        ]
        let placements = PanelGrid<AnyView>.pack(tiles: tiles, columns: 2)
        XCTAssertEqual(placements[0].row, 0); XCTAssertEqual(placements[0].col, 0)
        XCTAssertEqual(placements[1].row, 1); XCTAssertEqual(placements[1].col, 0)
        XCTAssertEqual(placements[1].cols, 2)
    }

    func testPackingTallReservesTwoRowsInSameColumn() {
        // tall(1×2) at (0,0), then small(1×1) can slide into (0,1) since
        // the tall only occupies column 0 on rows 0 and 1.
        let tiles = [
            PanelTile(kind: .solarTerrestrial, size: .tall),
            PanelTile(kind: .solarTerrestrial, size: .small),
        ]
        let placements = PanelGrid<AnyView>.pack(tiles: tiles, columns: 2)
        XCTAssertEqual(placements[0].row, 0); XCTAssertEqual(placements[0].col, 0)
        XCTAssertEqual(placements[0].rows, 2)
        XCTAssertEqual(placements[1].row, 0); XCTAssertEqual(placements[1].col, 1)
    }

    func testPackingWideInSingleColumnClampsToOne() {
        // A wide tile in a 1-column grid can't be 2 wide; the packer
        // clamps to `columns`. Locking the fallback behavior here.
        let tiles = [PanelTile(kind: .solarTerrestrial, size: .wide)]
        let placements = PanelGrid<AnyView>.pack(tiles: tiles, columns: 1)
        XCTAssertEqual(placements[0].cols, 1)
        XCTAssertEqual(placements[0].col,  0)
    }

    func testPackingLargeTilePlacesAtOriginAndSubsequentSmallsWrap() {
        // large(2×2) fills cols 0..1 rows 0..1. Two smalls after it should
        // land at row 2, cols 0 and 1.
        let tiles = [
            PanelTile(kind: .solarTerrestrial, size: .large),
            PanelTile(kind: .solarTerrestrial, size: .small),
            PanelTile(kind: .solarTerrestrial, size: .small),
        ]
        let placements = PanelGrid<AnyView>.pack(tiles: tiles, columns: 2)
        XCTAssertEqual(placements[0].row, 0); XCTAssertEqual(placements[0].col, 0)
        XCTAssertEqual(placements[0].cols, 2); XCTAssertEqual(placements[0].rows, 2)
        XCTAssertEqual(placements[1].row, 2); XCTAssertEqual(placements[1].col, 0)
        XCTAssertEqual(placements[2].row, 2); XCTAssertEqual(placements[2].col, 1)
    }
}
