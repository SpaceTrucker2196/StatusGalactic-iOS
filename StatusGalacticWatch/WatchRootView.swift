import SwiftUI

struct WatchRootView: View {
    @Environment(LocationManager.self) private var location
    @Environment(ClientConfig.self) private var config

    @State private var vm = WatchBriefViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Galactic")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .task {
                    location.requestPermissionIfNeeded()
                    await refresh()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let brief, let fetchedAt):
            WatchBriefView(brief: brief, fetchedAt: fetchedAt)
        case .error(let msg):
            VStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle").font(.title2)
                Text(msg)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                Button("Try Again") { Task { await refresh() } }
                    .font(.caption)
            }
            .padding(.horizontal)
        }
    }

    private func refresh() async {
        await vm.load(config: config, location: location.lastLocation)
    }
}
