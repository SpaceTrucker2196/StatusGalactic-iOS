import SwiftUI

/// A single tile placement: which panel, what size. `PanelGrid` renders a
/// list of these into a variable-span layout that packs left-to-right,
/// top-to-bottom, wrapping when a tile doesn't fit in the current row.
///
/// `id` is a stable UUID that survives encode/decode round-trips through
/// `PanelLayoutStore`, so a tile the user has selected/highlighted in
/// the editor stays the same identity across launches.
struct PanelTile: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var kind: PanelKind
    var size: PanelSize
}

/// Variable-span grid host for `PanelTile`s. Home for the iPad home
/// screen; also usable on iPhone (falls back to a single-column stack when
/// `columns == 1`).
///
/// Layout is a simple deterministic bin-pack: for each tile in source
/// order, find the first (row, col) that admits its (cols × rows) span
/// without overlapping an already-placed tile. Tiles that don't fit in
/// the row width fall through to a new row.
struct PanelGrid<PanelContent: View>: View {
    let tiles: [PanelTile]
    let columns: Int
    let cellSize: CGFloat
    let gap: CGFloat
    let content: (PanelTile) -> PanelContent

    init(
        tiles: [PanelTile],
        columns: Int = 2,
        cellSize: CGFloat = 168,
        gap: CGFloat = 12,
        @ViewBuilder content: @escaping (PanelTile) -> PanelContent
    ) {
        self.tiles = tiles
        self.columns = max(1, columns)
        self.cellSize = cellSize
        self.gap = gap
        self.content = content
    }

    var body: some View {
        let placements = Self.pack(tiles: tiles, columns: columns)
        let totalRows = (placements.map { $0.row + $0.rows }.max() ?? 0)
        let totalHeight = totalRows == 0
            ? 0
            : CGFloat(totalRows) * cellSize + CGFloat(max(0, totalRows - 1)) * gap

        ZStack(alignment: .topLeading) {
            ForEach(placements, id: \.tile.id) { placement in
                content(placement.tile)
                    .frame(
                        width: cellSize * CGFloat(placement.cols)
                             + gap * CGFloat(max(0, placement.cols - 1)),
                        height: cellSize * CGFloat(placement.rows)
                              + gap * CGFloat(max(0, placement.rows - 1))
                    )
                    .offset(
                        x: CGFloat(placement.col) * (cellSize + gap),
                        y: CGFloat(placement.row) * (cellSize + gap)
                    )
            }
        }
        .frame(
            width: CGFloat(columns) * cellSize
                 + CGFloat(max(0, columns - 1)) * gap,
            height: totalHeight,
            alignment: .topLeading
        )
    }

    // MARK: - Packing

    struct Placement: Hashable {
        let tile: PanelTile
        let row: Int
        let col: Int
        let cols: Int
        let rows: Int
    }

    /// Row-major first-fit packing. Deterministic for a given input order.
    /// Tiles whose `cols` exceeds `columns` clamp to `columns` (a 2×N tile
    /// in a 1-column grid becomes 1×N so it still renders).
    static func pack(tiles: [PanelTile], columns: Int) -> [Placement] {
        let cols = max(1, columns)
        var occupied: [[Bool]] = []
        var placements: [Placement] = []
        placements.reserveCapacity(tiles.count)

        func fits(row: Int, col: Int, w: Int, h: Int) -> Bool {
            for r in row..<(row + h) {
                if r >= occupied.count { return true } // grow-on-demand
                for c in col..<(col + w) {
                    if occupied[r][c] { return false }
                }
            }
            return true
        }

        func markOccupied(row: Int, col: Int, w: Int, h: Int) {
            while occupied.count < row + h {
                occupied.append([Bool](repeating: false, count: cols))
            }
            for r in row..<(row + h) {
                for c in col..<(col + w) {
                    occupied[r][c] = true
                }
            }
        }

        for tile in tiles {
            let span = tile.size.span
            let w = min(span.cols, cols)
            let h = span.rows

            var placed = false
            var row = 0
            while !placed {
                for col in 0...(cols - w) {
                    if fits(row: row, col: col, w: w, h: h) {
                        markOccupied(row: row, col: col, w: w, h: h)
                        placements.append(
                            Placement(tile: tile, row: row, col: col, cols: w, rows: h)
                        )
                        placed = true
                        break
                    }
                }
                if !placed { row += 1 }
                // Safety valve: never loop forever.
                if row > tiles.count * 4 { placed = true }
            }
        }
        return placements
    }
}
