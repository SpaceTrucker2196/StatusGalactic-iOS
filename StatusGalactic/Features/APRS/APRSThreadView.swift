import SwiftUI

struct APRSThreadView: View {
    let thread: APRSThread

    @Environment(ClientConfig.self) private var config
    @Environment(APRSMessageStore.self) private var store

    @State private var showCompose = false

    var body: some View {
        // Re-read messages from the store so a new send refreshes the thread.
        let current = store.threads(myCallsign: config.myCallsign)
            .first { $0.partner == thread.partner } ?? thread

        return List {
            ForEach(current.messages.reversed()) { msg in
                APRSBubble(message: msg, myCallsign: config.myCallsign)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .background(GalacticPalette.cosmicSky.ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .navigationTitle(thread.partner)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(config.myCallsign.isEmpty)
            }
        }
        .sheet(isPresented: $showCompose) {
            APRSComposeView(prefilledRecipient: thread.partner)
        }
    }
}

private struct APRSBubble: View {
    let message: APRSMessage
    let myCallsign: String

    var isOutgoing: Bool {
        message.from.uppercased() == myCallsign.uppercased()
    }

    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 40) }
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.firaCode(.body))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isOutgoing
                                  ? GalacticPalette.neonMagenta.opacity(0.25)
                                  : GalacticPalette.electricBlue.opacity(0.25))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isOutgoing
                                    ? GalacticPalette.hotPink
                                    : GalacticPalette.neonCyan, lineWidth: 0.8)
                    )
                Text(message.sentAt, style: .relative)
                    .font(.firaCode(.caption2))
                    .foregroundStyle(.secondary)
            }
            if !isOutgoing { Spacer(minLength: 40) }
        }
        .padding(.vertical, 2)
    }
}
