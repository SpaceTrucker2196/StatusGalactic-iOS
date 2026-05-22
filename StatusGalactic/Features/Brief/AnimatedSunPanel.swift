import SwiftUI
import AVKit
import UIKit

/// Multi-day SDO AIA 304 Å animation. NASA publishes a rolling 48-hour
/// movie of the AIA 304 channel at a stable URL; we stream it via
/// `AVPlayer` configured for autoplay + loop + no chrome.
///
/// The still AIA 304 frame from the SDO image catalog is rendered behind
/// the player so the user sees something the moment the panel mounts;
/// the movie crossfades in once enough has buffered to start playback.
/// A thin progress bar in the footer reports buffering progress.
struct AnimatedSunPanel: View {
    static let movieURL = URL(string:
        "https://sdo.gsfc.nasa.gov/assets/img/latest/mpeg/SDO_AIA_304_v1.mp4"
    )!

    /// Fallback still for the "tap-to-zoom" detail sheet and for the
    /// placeholder layer behind the player.
    private var stillSource: SunImageSource {
        SunImageCatalog.all.first { $0.label.hasPrefix("AIA 304") }
            ?? SunImageCatalog.all[0]
    }

    @State private var showDetail = false
    @State private var playerReady = false
    @State private var loadProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showDetail = true } label: {
                ZStack {
                    Color.black
                    // Cached still — instantly visible while the MP4 buffers.
                    CachedAsyncImage(
                        url: stillSource.url,
                        placeholder: {
                            ZStack {
                                Color.black
                                ProgressView().tint(GalacticPalette.neonCyan)
                            }
                        },
                        failure: {
                            ZStack {
                                Color.black
                                Image(systemName: "sun.max.trianglebadge.exclamationmark")
                                    .font(.title)
                                    .foregroundStyle(GalacticPalette.neonMagenta)
                            }
                        }
                    )
                    .aspectRatio(contentMode: .fill)
                    .opacity(playerReady ? 0 : 1)

                    LoopingPlayerView(
                        url: Self.movieURL,
                        onProgress: { loadProgress = $0 },
                        onReady: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                playerReady = true
                            }
                        }
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .opacity(playerReady ? 1 : 0)
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

            if !playerReady {
                loadingFooter
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showDetail) {
            AnimatedSunDetail(still: stillSource, movieURL: Self.movieURL)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Solar imagery: AIA 304 Ångströms 48-hour animation from \(stillSource.provider).")
    }

    /// Slim progress bar + caption shown until AVPlayer reports playing.
    private var loadingFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.caption2)
                .foregroundStyle(GalacticPalette.peach.opacity(0.8))
            Text(loadProgress > 0
                 ? "Loading 48h animation"
                 : "Connecting to SDO")
                .font(.firaCode(.caption2))
                .foregroundStyle(.secondary)
            ProgressView(value: max(loadProgress, 0.02), total: 1.0)
                .tint(GalacticPalette.peach)
                .frame(maxWidth: .infinity)
            Text("\(Int(min(loadProgress, 1.0) * 100))%")
                .font(.firaCode(.caption2, weight: .semibold))
                .foregroundStyle(GalacticPalette.peach)
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.top, 2)
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
                    LoopingPlayerView(url: movieURL, onProgress: { _ in }, onReady: {})
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
///
/// Reports buffering progress (0–1 of total duration) and a "ready"
/// signal (the player transitioned to `.playing`) so the host view can
/// crossfade a still image out and remove a loading bar.
struct LoopingPlayerView: UIViewControllerRepresentable {
    let url: URL
    var onProgress: (Double) -> Void = { _ in }
    var onReady: () -> Void = {}

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        let looper = AVPlayerLooper(player: queue, templateItem: item)
        queue.isMuted = true
        queue.actionAtItemEnd = .advance

        let vc = AVPlayerViewController()
        vc.player = queue
        vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspect
        vc.view.backgroundColor = .black

        context.coordinator.bind(item: item, player: queue, looper: looper,
                                 onProgress: onProgress, onReady: onReady)
        queue.play()
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Nothing to update — the looper keeps playing the same URL.
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var looper: AVPlayerLooper?
        var progressObservation: NSKeyValueObservation?
        var durationObservation: NSKeyValueObservation?
        var rateObservation: NSKeyValueObservation?
        private var duration: Double = 0

        func bind(
            item: AVPlayerItem,
            player: AVQueuePlayer,
            looper: AVPlayerLooper,
            onProgress: @escaping (Double) -> Void,
            onReady: @escaping () -> Void
        ) {
            self.looper = looper

            // Duration arrives a tick after the item attaches; reread it
            // every time it changes so the progress fraction is honest.
            durationObservation = item.observe(\.duration, options: [.new]) { [weak self] item, _ in
                guard let self else { return }
                let secs = item.duration.seconds
                if secs.isFinite, secs > 0 {
                    self.duration = secs
                    self.report(item: item, onProgress: onProgress)
                }
            }

            // loadedTimeRanges grows as the network buffers more.
            progressObservation = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] item, _ in
                self?.report(item: item, onProgress: onProgress)
            }

            // `.playing` means there's enough buffered to start rolling.
            rateObservation = player.observe(\.timeControlStatus, options: [.new]) { player, _ in
                if player.timeControlStatus == .playing {
                    DispatchQueue.main.async { onReady() }
                }
            }
        }

        private func report(item: AVPlayerItem, onProgress: @escaping (Double) -> Void) {
            guard duration > 0 else { return }
            let buffered = item.loadedTimeRanges
                .map { $0.timeRangeValue.duration.seconds }
                .max() ?? 0
            let pct = min(1, max(0, buffered / duration))
            DispatchQueue.main.async { onProgress(pct) }
        }
    }
}
