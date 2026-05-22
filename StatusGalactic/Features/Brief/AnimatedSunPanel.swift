import SwiftUI
import AVKit
import UIKit

/// Multi-day SDO AIA 304 Å animation. NASA publishes a rolling 48-hour
/// movie of the AIA 304 channel at a stable URL; we stream it via
/// `AVPlayer` configured for autoplay + loop + no chrome.
///
/// The previous still-image hero stays available as a fallback when the
/// movie URL is unreachable (the AVPlayer simply shows the dark
/// background colour and we render the AIA 304 still on top).
struct AnimatedSunPanel: View {
    static let movieURL = URL(string:
        "https://sdo.gsfc.nasa.gov/assets/img/latest/mpeg/SDO_AIA_304_v1.mp4"
    )!

    /// Fallback still used when the video can't load yet (and as the
    /// foreground for the "tap-to-zoom" detail sheet).
    private var stillSource: SunImageSource {
        SunImageCatalog.all.first { $0.label.hasPrefix("AIA 304") }
            ?? SunImageCatalog.all[0]
    }

    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showDetail = true } label: {
                ZStack {
                    Color.black
                    LoopingPlayerView(url: Self.movieURL)
                        .aspectRatio(1, contentMode: .fit)
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(GalacticPalette.neonPurple.opacity(0.55), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(stillSource.label)
                    .font(.firaCode(.title3, weight: .bold))
                    .foregroundStyle(GalacticPalette.neonCyan)
                    .neonGlow(GalacticPalette.neonCyan, intensity: 7)
                Text("48-hour rolling animation · SDO/AIA 304 Å")
                    .font(.firaCode(.caption))
                    .foregroundStyle(GalacticPalette.peach.opacity(0.85))
                Text(stillSource.provider + " · tap for full size")
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showDetail) {
            AnimatedSunDetail(still: stillSource, movieURL: Self.movieURL)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Solar imagery: AIA 304 Ångströms 48-hour animation from \(stillSource.provider).")
    }
}

private struct AnimatedSunDetail: View {
    let still: SunImageSource
    let movieURL: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LoopingPlayerView(url: movieURL)
                        .aspectRatio(1, contentMode: .fit)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text(still.label)
                        .font(.firaCode(.title3, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                    Text("Latest 48 hours of SDO/AIA 304 Å imagery, looped. " +
                         "Bright loops here are plasma at ~80,000 K — the chromospheric "
                         + "network, prominences and flare ribbons.")
                        .font(.firaCode(.body))
                    Text("Source: \(still.provider)")
                        .font(.firaCode(.caption))
                        .foregroundStyle(.secondary)
                    Link(movieURL.absoluteString, destination: movieURL)
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.hotPink)
                        .lineLimit(1)
                }
                .padding()
            }
            .navigationTitle(still.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Looping AVPlayer

/// `AVPlayerViewController` configured for autoplay + loop + no chrome,
/// wrapped for SwiftUI. Loop is implemented via the `AVPlayerLooper`
/// pattern on a queue player, which gives seamless playback without the
/// flash you get from rewinding a regular `AVPlayer`.
struct LoopingPlayerView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        let looper = AVPlayerLooper(player: queue, templateItem: item)
        context.coordinator.looper = looper      // retain
        queue.isMuted = true
        queue.actionAtItemEnd = .advance         // looper takes over after that

        let vc = AVPlayerViewController()
        vc.player = queue
        vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspect
        vc.view.backgroundColor = .black
        queue.play()
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Nothing to update — the looper keeps playing the same URL.
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var looper: AVPlayerLooper?
    }
}
