import SwiftUI

/// iPad-first home for the panel grid. Pilots the abstraction with the
/// Solar-Terrestrial panel at three of its four sizes so the grid packing
/// is exercised. As other panels get factored into `PanelKit`, this
/// screen's `defaultLayout` grows.
///
/// Renders fine on iPhone too (falls back to a single wider column via
/// `columns(for:)`), so we can wire it as a tab today without gating.
struct PanelsScreen: View {
    @Environment(BriefViewModel.self) private var brief
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Sample layout — kept in code until slice 3 lands a persisted,
    /// user-editable layout. Order and mix demonstrate all three panels
    /// at multiple sizes so the packer + tile chrome are exercised.
    static let defaultLayout: [PanelTile] = [
        .init(kind: .brief,            size: .wide),
        .init(kind: .solarTerrestrial, size: .small),
        .init(kind: .solarTerrestrial, size: .small),
        .init(kind: .tides,            size: .wide),
        .init(kind: .solarTerrestrial, size: .large),
        .init(kind: .tides,            size: .tall),
        .init(kind: .brief,            size: .small),
        .init(kind: .solarTerrestrial, size: .tall),
    ]

    var body: some View {
        ScrollView {
            PanelGrid(
                tiles: Self.defaultLayout,
                columns: columns(for: horizontalSizeClass),
                cellSize: cellSize(for: horizontalSizeClass)
            ) { tile in
                PanelTileView(tile: tile, brief: currentBrief, referenceDate: Date())
            }
            .padding(16)
        }
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle("Panels")
    }

    private var currentBrief: Brief? {
        if case let .loaded(brief, _, _) = brief.state { return brief }
        return nil
    }

    private func columns(for sc: UserInterfaceSizeClass?) -> Int {
        sc == .regular ? 4 : 2
    }

    private func cellSize(for sc: UserInterfaceSizeClass?) -> CGFloat {
        sc == .regular ? 180 : 160
    }
}

/// One panel tile rendered into the grid. Dispatches by `PanelKind` to the
/// concrete `SolarPanel` / (future) `BriefPanel` / `TidesPanel` / … The
/// tile chrome (rounded corners, glow ring, background) lives here so
/// each panel author only writes content, not framing.
struct PanelTileView: View {
    let tile: PanelTile
    let brief: Brief?
    let referenceDate: Date

    var body: some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(GalacticPalette.deepPurple.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(GalacticPalette.neonCyan.opacity(0.35), lineWidth: 0.6)
            )
    }

    @ViewBuilder
    private var content: some View {
        switch tile.kind {
        case .brief:
            BriefPanel(size: tile.size, brief: brief, referenceDate: referenceDate)
        case .solarTerrestrial:
            SolarPanel(size: tile.size, brief: brief, referenceDate: referenceDate)
        case .tides:
            TidesPanel(size: tile.size, brief: brief, referenceDate: referenceDate)
        }
    }
}
