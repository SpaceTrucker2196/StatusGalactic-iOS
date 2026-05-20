import SwiftUI

/// Astronomy Picture of the Day card. Renders the image (or video thumbnail),
/// the title in neon cyan, a clipped explanation, and a "Read more" sheet.
struct APODCard: View {
    let apod: APOD
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                if let url = apod.displayImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            ZStack {
                                Color.black
                                Image(systemName: "sparkles")
                                    .font(.title)
                                    .foregroundStyle(GalacticPalette.neonPurple)
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
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(GalacticPalette.neonPurple.opacity(0.6), lineWidth: 1)
                    )
                }

                Text(apod.title)
                    .font(.firaCode(.headline, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 6)
                    .multilineTextAlignment(.leading)

                Text(apod.explanation)
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(apod.date)
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.hotPink)
                    if let copyright = apod.copyright {
                        Text("• \(copyright)")
                            .font(.firaCode(.caption2))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            APODDetail(apod: apod)
        }
    }
}

private struct APODDetail: View {
    let apod: APOD
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let url = apod.displayImageURL {
                        AsyncImage(url: url) { phase in
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
                    }
                    Text(apod.title)
                        .font(.firaCode(.title3, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                    Text(apod.explanation)
                        .font(.firaCode(.body))
                    if let copyright = apod.copyright {
                        Text("© \(copyright)")
                            .font(.firaCode(.caption2))
                            .foregroundStyle(.secondary)
                    }
                    Link("Open on apod.nasa.gov", destination: URL(string: "https://apod.nasa.gov/apod/")!)
                        .font(.firaCode(.caption))
                        .foregroundStyle(GalacticPalette.hotPink)
                }
                .padding()
            }
            .navigationTitle(apod.date)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// Mars weather card (Curiosity REMS via MAAS2).
struct MarsWeatherCard: View {
    let mars: MarsWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "globe.central.south.asia.fill")
                    .foregroundStyle(GalacticPalette.mars)
                    .neonGlow(GalacticPalette.mars, intensity: 6)
                Text("Sol \(mars.sol)")
                    .font(.firaCode(.headline, weight: .bold))
                    .foregroundStyle(GalacticPalette.mars)
                Spacer()
                if let season = mars.season {
                    Text(season)
                        .font(.firaCode(.caption))
                        .foregroundStyle(GalacticPalette.peach)
                }
            }

            HStack(spacing: 12) {
                if let minC = mars.minTempC {
                    tempPanel(label: "Low",  c: minC, color: GalacticPalette.electricBlue)
                }
                if let maxC = mars.maxTempC {
                    tempPanel(label: "High", c: maxC, color: GalacticPalette.hotPink)
                }
            }

            if let opacity = mars.atmoOpacity {
                LabeledContent {
                    Text(opacity)
                        .font(.firaCode(.subheadline))
                        .foregroundStyle(GalacticPalette.peach)
                } label: {
                    Label("Atmosphere", systemImage: "aqi.medium")
                        .font(.firaCode(.subheadline))
                }
            }
            if let p = mars.pressurePa {
                LabeledContent {
                    Text("\(Int(p)) Pa")
                        .font(.firaCode(.subheadline))
                        .foregroundStyle(GalacticPalette.neonCyan)
                } label: {
                    Label("Pressure", systemImage: "gauge.medium")
                        .font(.firaCode(.subheadline))
                }
            }
            if let date = mars.terrestrialDate {
                Text("Earth date: \(date)")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tempPanel(label: String, c: Double, color: Color) -> some View {
        let f = c * 9 / 5 + 32
        return VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(c.rounded()))°C")
                    .font(.firaCode(.title3, weight: .bold))
                    .foregroundStyle(color)
                    .neonGlow(color, intensity: 4)
                Text("(\(Int(f.rounded()))°F)")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
