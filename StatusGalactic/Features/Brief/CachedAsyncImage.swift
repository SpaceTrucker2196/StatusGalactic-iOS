import SwiftUI
import UIKit

/// SwiftUI image view that loads from `ImageCache` first and falls back to
/// network. Mimics `AsyncImage` without the system caching opacity.
struct CachedAsyncImage<Placeholder: View, Failure: View>: View {
    let url: URL?
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else if failed {
                failure()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        image = nil
        failed = false
        guard let url else { return }
        do {
            let data = try await ImageCache.shared.data(for: url)
            if let ui = UIImage(data: data) {
                image = ui
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
    }
}

extension CachedAsyncImage where Placeholder == AnyView, Failure == AnyView {
    /// Convenience: pulsing-cyan placeholder + dimmed-icon failure state.
    init(url: URL?) {
        self.init(
            url: url,
            placeholder: {
                AnyView(
                    ProgressView()
                        .tint(GalacticPalette.neonCyan)
                        .frame(maxWidth: .infinity, minHeight: 120)
                )
            },
            failure: {
                AnyView(
                    Image(systemName: "wifi.exclamationmark")
                        .foregroundStyle(GalacticPalette.peach.opacity(0.6))
                        .frame(maxWidth: .infinity, minHeight: 120)
                )
            }
        )
    }
}
