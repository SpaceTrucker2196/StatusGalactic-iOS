import SwiftUI

struct APRSComposeView: View {
    @Environment(ClientConfig.self) private var config
    @Environment(APRSMessageStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var recipient: String = ""
    @State private var text: String = ""
    @State private var isSending = false
    @State private var error: String?

    private let charLimit = 67

    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    Text(config.myCallsign.uppercased())
                        .font(.firaCode(.title3, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.4))

                Section("To") {
                    TextField("e.g. KJ7CMR", text: $recipient)
                        .font(.firaCode(.body, weight: .semibold))
                        .foregroundStyle(GalacticPalette.hotPink)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.4))

                Section {
                    TextField("Message", text: $text, axis: .vertical)
                        .font(.firaCode(.body))
                        .lineLimit(3...6)
                    HStack {
                        Spacer()
                        Text("\(text.count) / \(charLimit)")
                            .font(.firaCode(.caption2))
                            .foregroundStyle(text.count > charLimit
                                             ? GalacticPalette.severe
                                             : GalacticPalette.peach.opacity(0.8))
                    }
                } header: {
                    Text("Message (67 char limit)")
                } footer: {
                    Text("Sent via APRS-IS over HTTP. Long messages are truncated by the network.")
                        .font(.firaCode(.caption2))
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.4))

                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.firaCode(.caption))
                            .foregroundStyle(GalacticPalette.storm)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(GalacticPalette.cosmicSky.ignoresSafeArea())
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSending {
                        ProgressView().tint(GalacticPalette.neonCyan)
                    } else {
                        Button("Send") {
                            Task { await send() }
                        }
                        .disabled(!canSend)
                    }
                }
            }
        }
    }

    private var canSend: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty
            && !text.trimmingCharacters(in: .whitespaces).isEmpty
            && text.count <= charLimit
    }

    private func send() async {
        isSending = true
        defer { isSending = false }

        let messaging = APRSMessaging(userAgent: config.userAgent)
        let counter = store.nextOutgoingNumber()
        do {
            let id = try await messaging.send(
                from: config.myCallsign,
                to: recipient,
                text: text,
                messageNumber: counter
            )
            let outgoing = APRSMessage(
                messageID: "\(config.myCallsign.uppercased())-out-\(id)",
                from: config.myCallsign.uppercased(),
                to: recipient.uppercased(),
                text: text,
                sentAt: Date(),
                direction: .outgoing,
                acknowledged: false
            )
            store.upsert(outgoing)
            dismiss()
        } catch let http as HTTPError {
            error = http.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
