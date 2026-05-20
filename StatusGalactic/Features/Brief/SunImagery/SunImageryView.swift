import SwiftUI

struct SunImageryView: View {
    var body: some View {
        ImageStrip(images: SunImageCatalog.all)
    }
}

struct AuroraImageryView: View {
    var body: some View {
        ImageStrip(images: AuroraCatalog.both, tileWidth: 180, tileHeight: 180)
    }
}

struct DeepSkyImageryView: View {
    var body: some View {
        ImageStrip(images: DeepSkyCatalog.all, tileWidth: 160, tileHeight: 160)
    }
}

private struct ImageStrip: View {
    let images: [SunImageSource]
    var tileWidth: CGFloat = 120
    var tileHeight: CGFloat = 120

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(images) { image in
                    SunImageTile(image: image, width: tileWidth, height: tileHeight)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }
}

private struct SunImageTile: View {
    let image: SunImageSource
    let width: CGFloat
    let height: CGFloat
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                AsyncImage(url: image.url, transaction: .init(animation: .default)) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            Color.black
                            Image(systemName: "sun.max.trianglebadge.exclamationmark")
                                .font(.title2)
                                .foregroundStyle(GalacticPalette.neonMagenta.opacity(0.7))
                        }
                    case .empty:
                        ZStack {
                            Color.black
                            ProgressView().tint(GalacticPalette.neonCyan)
                        }
                    @unknown default:
                        Color.black
                    }
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(GalacticPalette.neonPurple.opacity(0.5), lineWidth: 0.8)
                )

                Text(image.label)
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                    .lineLimit(1)
                Text(image.provider)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(image.label). \(image.caption). From \(image.provider).")
        .sheet(isPresented: $showDetail) {
            SunImageDetailView(image: image)
        }
    }
}

private struct SunImageDetailView: View {
    let image: SunImageSource
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: image.url) { phase in
                        switch phase {
                        case .success(let img):
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .background(.black)
                        case .failure:
                            ZStack {
                                Color.black
                                Label("Image unavailable", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.secondary)
                            }
                            .aspectRatio(1, contentMode: .fit)
                        case .empty:
                            ZStack {
                                Color.black
                                ProgressView().tint(.white)
                            }
                            .aspectRatio(1, contentMode: .fit)
                        @unknown default:
                            Color.black
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(image.label)
                            .font(.title3.weight(.semibold))
                        Text(image.caption)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text("Source: \(image.provider)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Link(image.url.absoluteString, destination: image.url)
                            .font(.caption2)
                            .lineLimit(1)
                    }
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
