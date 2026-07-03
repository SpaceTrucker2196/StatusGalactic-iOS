import SwiftUI

/// iPad-first home for the panel grid. Renders whatever layout the user
/// has persisted via `PanelLayoutStore`, falling back to `defaultLayout`
/// on first launch or after a decode failure.
///
/// Renders fine on iPhone too (falls back to a single wider column via
/// `columns(for:)`), so we can wire it as a tab today without gating.
struct PanelsScreen: View {
    @Environment(BriefViewModel.self) private var brief
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var tiles: [PanelTile] = PanelLayoutStore.load(fallback: PanelsScreen.defaultLayout)
    @State private var showingEditor = false

    /// Ship-with layout. Order and mix demonstrate all three panels at
    /// multiple sizes so the packer + tile chrome are exercised out of
    /// the box. Also used as the "Reset to default" target in the editor.
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
                tiles: tiles,
                columns: columns(for: horizontalSizeClass),
                cellSize: cellSize(for: horizontalSizeClass)
            ) { tile in
                PanelTileView(tile: tile, brief: currentBrief, referenceDate: Date())
            }
            .padding(16)
        }
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .navigationTitle("Panels")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "square.grid.3x3.square")
                        .foregroundStyle(GalacticPalette.neonCyan)
                }
                .accessibilityLabel("Edit panel layout")
            }
        }
        .sheet(isPresented: $showingEditor) {
            PanelLayoutEditor(
                tiles: $tiles,
                defaultLayout: PanelsScreen.defaultLayout
            )
        }
        .onChange(of: tiles) { _, new in
            PanelLayoutStore.save(new)
        }
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
