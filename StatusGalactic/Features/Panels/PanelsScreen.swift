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

    /// Sample layout for the pilot slice. Once more panels are factored,
    /// this becomes a persisted, user-editable layout.
    static let defaultLayout: [PanelTile] = [
        .init(kind: .solarTerrestrial, size: .wide),
        .init(kind: .solarTerrestrial, size: .small),
        .init(kind: .solarTerrestrial, size: .small),
        .init(kind: .solarTerrestrial, size: .tall),
        .init(kind: .solarTerrestrial, size: .large),
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
        case .solarTerrestrial:
            SolarPanel(size: tile.size, brief: brief, referenceDate: referenceDate)
        case .brief, .tides:
            // Not yet factored into a shared `PanelView`. Render a labelled
            // placeholder so the grid layout is still exercised.
            PanelPlaceholder(kind: tile.kind, size: tile.size)
        }
    }
}

/// Vaporwave placeholder for panels that haven't been factored yet.
struct PanelPlaceholder: View {
    let kind: PanelKind
    let size: PanelSize

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(kind.displayName.uppercased())
                .font(.firaCodeFixed(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(GalacticPalette.phosphorGreen)
            Text(size.rawValue.uppercased())
                .font(.firaCodeFixed(size: 9, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach.opacity(0.7))
            Spacer(minLength: 0)
            Text("Panel not yet factored")
                .font(.firaCodeFixed(size: 9))
                .foregroundStyle(GalacticPalette.hotPink.opacity(0.75))
        }
    }
}
