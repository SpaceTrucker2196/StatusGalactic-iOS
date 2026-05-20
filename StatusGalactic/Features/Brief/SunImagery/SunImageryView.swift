import SwiftUI

struct SunImageryView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(SunImageCatalog.all) { image in
                    SunImageTile(image: image)
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
                                .foregroundStyle(.secondary)
                        }
                    case .empty:
                        ZStack {
                            Color.black
                            ProgressView().tint(.white)
                        }
                    @unknown default:
                        Color.black
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.quaternary, lineWidth: 0.5)
                )

                Text(image.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(image.provider)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 120, alignment: .leading)
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
