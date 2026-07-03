import SwiftUI

/// Sheet-hosted editor for the iPad `PanelsScreen` tile layout. Lets the
/// user reorder tiles (drag handles), change each tile's `PanelKind` and
/// `PanelSize`, delete rows, add new tiles, and reset to the default
/// layout. Mutates the passed `Binding<[PanelTile]>` in place; parent
/// persists via `PanelLayoutStore.save` on every change.
struct PanelLayoutEditor: View {
    @Binding var tiles: [PanelTile]
    let defaultLayout: [PanelTile]
    var onDismiss: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .active

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($tiles) { $tile in
                        PanelLayoutRow(tile: $tile)
                    }
                    .onMove { indices, newOffset in
                        tiles.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    .onDelete { offsets in
                        tiles.remove(atOffsets: offsets)
                    }
                } header: {
                    Text("Tiles (\(tiles.count))")
                        .font(.firaCode(.caption))
                } footer: {
                    Text("Drag the handles to reorder. Tap a row to change the panel or size. Swipe left to delete.")
                        .font(.firaCode(.caption2))
                }
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden)
            .background(GalacticPalette.cosmicSky.ignoresSafeArea())
            .navigationTitle("Layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(PanelKind.allCases) { kind in
                            Button {
                                tiles.append(PanelTile(kind: kind, size: .small))
                            } label: {
                                Label(kind.displayName, systemImage: iconName(for: kind))
                            }
                        }
                        Divider()
                        Button(role: .destructive) {
                            tiles = defaultLayout
                        } label: {
                            Label("Reset to default", systemImage: "arrow.uturn.backward")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(GalacticPalette.neonCyan)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundStyle(GalacticPalette.neonCyan)
                }
            }
        }
    }

    private func iconName(for kind: PanelKind) -> String {
        switch kind {
        case .brief:            return "globe.americas.fill"
        case .solarTerrestrial: return "sun.max.fill"
        case .tides:            return "water.waves"
        }
    }
}

/// One row in the layout editor — kind picker on the left, size picker on
/// the right. The row is a `Menu` on each side rather than a full-row
/// tap so drag handles and delete swipe still work.
struct PanelLayoutRow: View {
    @Binding var tile: PanelTile

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(PanelKind.allCases) { kind in
                    Button {
                        tile.kind = kind
                    } label: {
                        if kind == tile.kind {
                            Label(kind.displayName, systemImage: "checkmark")
                        } else {
                            Text(kind.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: iconName(for: tile.kind))
                        .foregroundStyle(GalacticPalette.phosphorGreen)
                    Text(tile.kind.displayName)
                        .font(.firaCode(.body, weight: .semibold))
                        .foregroundStyle(GalacticPalette.peach)
                }
            }

            Spacer(minLength: 8)

            Menu {
                ForEach(PanelSize.allCases) { size in
                    Button {
                        tile.size = size
                    } label: {
                        if size == tile.size {
                            Label(sizeLabel(size), systemImage: "checkmark")
                        } else {
                            Text(sizeLabel(size))
                        }
                    }
                }
            } label: {
                Text(sizeLabel(tile.size))
                    .font(.firaCode(.callout, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().stroke(GalacticPalette.neonCyan.opacity(0.5), lineWidth: 0.75)
                    )
            }
        }
        .listRowBackground(GalacticPalette.deepPurple.opacity(0.35))
    }

    private func iconName(for kind: PanelKind) -> String {
        switch kind {
        case .brief:            return "globe.americas.fill"
        case .solarTerrestrial: return "sun.max.fill"
        case .tides:            return "water.waves"
        }
    }

    private func sizeLabel(_ size: PanelSize) -> String {
        switch size {
        case .small: return "1×1"
        case .wide:  return "2×1"
        case .tall:  return "1×2"
        case .large: return "2×2"
        }
    }
}
