import SwiftUI

/// Hero panel for the top of the brief: the latest SDO AIA 304 Å frame
/// filling the card, then a header-styled caption underneath.
///
/// Tap the image to open the same detail sheet the smaller Sun Imagery
/// strip uses.
struct AIASunPanel: View {
    private var source: SunImageSource {
        SunImageCatalog.all.first { $0.label.hasPrefix("AIA 304") }
            ?? SunImageCatalog.all[0]
    }

    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showDetail = true
            } label: {
                AsyncImage(url: source.url, transaction: .init(animation: .default)) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            Color.black
                            Image(systemName: "sun.max.trianglebadge.exclamationmark")
                                .font(.title)
                                .foregroundStyle(GalacticPalette.neonMagenta)
                        }
                        .aspectRatio(1, contentMode: .fit)
                    case .empty:
                        ZStack {
                            Color.black
                            ProgressView().tint(GalacticPalette.neonCyan)
                        }
                        .aspectRatio(1, contentMode: .fit)
                    @unknown default:
                        Color.black
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(GalacticPalette.neonPurple.opacity(0.55), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.label)
                    .font(.firaCode(.title3, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 7)
                Text(source.caption)
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                Text(source.provider + " · tap for full size")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showDetail) {
            AIASunPanelDetail(image: source)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Solar imagery: \(source.label). \(source.caption). \(source.provider).")
    }
}

private struct AIASunPanelDetail: View {
    let image: SunImageSource
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: image.url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fit)
                                .background(Color.black)
                        case .failure:
                            Label("Image unavailable", systemImage: "exclamationmark.triangle")
                                .padding()
                        case .empty:
                            ProgressView().padding()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text(image.label)
                        .font(.firaCode(.title3, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                    Text(image.caption)
                        .font(.firaCode(.body))
                    Text("Source: \(image.provider)")
                        .font(.firaCode(.caption))
                        .foregroundStyle(.secondary)
                    Link(image.url.absoluteString, destination: image.url)
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.hotPink)
                        .lineLimit(1)
                }
                .padding()
            }
            .navigationTitle(image.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
