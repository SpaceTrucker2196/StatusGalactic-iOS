import SwiftUI
import UIKit
import MessageUI

/// Compose a bug report or feature request and ship it straight to
/// support@river.io via the iOS system mail composer. No GitHub
/// account, no third-party sign-in — the user's already-authenticated
/// Mail.app handles delivery. A `mailto:` fallback covers devices
/// without Mail configured.
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClientConfig.self) private var config

    enum Kind: String, CaseIterable, Identifiable {
        case bug      = "Bug"
        case feature  = "Feature"
        case question = "Question"
        var id: String { rawValue }

        var subjectTag: String {
            switch self {
            case .bug:      return "Bug"
            case .feature:  return "Feature request"
            case .question: return "Question"
            }
        }

        var icon: String {
            switch self {
            case .bug:      return "ladybug.fill"
            case .feature:  return "sparkles"
            case .question: return "questionmark.circle.fill"
            }
        }
    }

    @State private var kind: Kind = .bug
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var showComposer = false
    @State private var mailFallbackError: String?

    private static let supportEmail = "support@river.io"

    private var canSend: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Kind", selection: $kind) {
                        ForEach(Kind.allCases) { k in
                            Label(k.rawValue, systemImage: k.icon).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))

                PhosphorSection("Title") {
                    TextField("Short summary", text: $title)
                        .font(.firaCode(.body))
                        .textInputAutocapitalization(.sentences)
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))

                Section {
                    TextEditor(text: $bodyText)
                        .font(.firaCode(.body))
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("Details").phosphorHeader()
                } footer: {
                    Text("Steps to reproduce, what you expected, what actually happened. Device + app version are appended automatically.")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.75))
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))

                Section {
                    Button {
                        send()
                    } label: {
                        Label("Send email", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GalacticPalette.neonMagenta)
                    .disabled(!canSend)

                    if let mailFallbackError {
                        Label(mailFallbackError, systemImage: "exclamationmark.triangle")
                            .font(.firaCode(.caption))
                            .foregroundStyle(GalacticPalette.storm)
                    }
                } footer: {
                    Text("Goes straight to support@river.io from your phone's Mail. No GitHub sign-in, no accounts.")
                        .font(.firaCode(.caption2))
                        .foregroundStyle(GalacticPalette.peach.opacity(0.75))
                }
                .listRowBackground(GalacticPalette.deepPurple.opacity(0.30))
            }
            .scrollContentBackground(.hidden)
            .background(GalacticPalette.cosmicSky.ignoresSafeArea())
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GalacticPalette.cosmicBlack.opacity(0.85), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showComposer) {
                MailComposer(
                    recipient: Self.supportEmail,
                    subject: composedSubject,
                    body: composedBody
                ) { _ in
                    showComposer = false
                    dismiss()
                }
                .ignoresSafeArea()
            }
        }
    }

    private func send() {
        if MFMailComposeViewController.canSendMail() {
            mailFallbackError = nil
            showComposer = true
        } else if let url = mailtoFallbackURL() {
            // No Mail account configured — hand the system the
            // mailto: URL and let the user pick whichever client is
            // set as default (or follow Apple's prompt to set one up).
            UIApplication.shared.open(url) { opened in
                if !opened {
                    mailFallbackError = "Couldn't open Mail. Email \(Self.supportEmail) directly."
                } else {
                    dismiss()
                }
            }
        } else {
            mailFallbackError = "No mail client available. Email \(Self.supportEmail) directly."
        }
    }

    private var composedSubject: String {
        "[Galactic \(kind.subjectTag)] \(title)"
    }

    private var composedBody: String {
        """
        \(bodyText)

        ---
        Submitted from Galactic v\(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))
        iOS \(UIDevice.current.systemVersion) · \(UIDevice.current.model)
        Callsign: \(config.myCallsign.isEmpty ? "—" : config.myCallsign)
        User-Agent: \(config.userAgent)
        """
    }

    private func mailtoFallbackURL() -> URL? {
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = Self.supportEmail
        c.queryItems = [
            URLQueryItem(name: "subject", value: composedSubject),
            URLQueryItem(name: "body", value: composedBody),
        ]
        return c.url
    }
}

// MARK: - Mail composer bridge

/// Thin UIViewControllerRepresentable wrapper over MFMailComposeViewController.
/// Pre-fills recipient + subject + body and dismisses on send / cancel.
private struct MailComposer: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    let onFinish: (MFMailComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (MFMailComposeResult) -> Void
        init(onFinish: @escaping (MFMailComposeResult) -> Void) { self.onFinish = onFinish }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true) { [onFinish] in
                onFinish(result)
            }
        }
    }
}

private extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }
    var buildNumber: String {
        (infoDictionary?["CFBundleVersion"] as? String) ?? "0"
    }
}
