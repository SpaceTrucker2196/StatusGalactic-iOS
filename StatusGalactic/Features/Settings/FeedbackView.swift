import SwiftUI
import UIKit

/// Compose a bug report or feature request and ship it straight into the
/// project's GitHub issue tracker. Authoring lives in-app; we URL-encode
/// the title and body onto a `github.com/.../issues/new` deep link so the
/// user lands on a pre-filled issue form and just hits "Submit new issue"
/// once GitHub auth is satisfied in Safari.
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClientConfig.self) private var config

    enum Kind: String, CaseIterable, Identifiable {
        case bug      = "Bug"
        case feature  = "Feature"
        case question = "Question"
        var id: String { rawValue }

        var labelTag: String {
            switch self {
            case .bug:      return "bug"
            case .feature:  return "enhancement"
            case .question: return "question"
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

    private static let repoBase = "https://github.com/SpaceTrucker2196/StatusGalactic-iOS"

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

                Section("Title") {
                    TextField("Short summary", text: $title)
                        .font(.firaCode(.body))
                        .textInputAutocapitalization(.sentences)
                }

                Section {
                    TextEditor(text: $bodyText)
                        .font(.firaCode(.body))
                        .frame(minHeight: 180)
                } header: {
                    Text("Details")
                } footer: {
                    Text("Markdown is supported. Steps to reproduce, expected vs actual behavior, screenshots — paste any of it.")
                        .font(.caption)
                }

                Section {
                    Button {
                        send()
                    } label: {
                        Label("Open in GitHub", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSend)
                } footer: {
                    Text("Opens a pre-filled new-issue form on github.com. You'll sign in to GitHub there and submit.")
                        .font(.caption)
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func send() {
        guard let url = makeIssueURL() else { return }
        UIApplication.shared.open(url)
        dismiss()
    }

    /// Composes the GitHub new-issue URL with title, body, and the kind's
    /// label tag baked into the query string. Includes a small auto-appended
    /// device-context footer so we don't have to ask the user to type it.
    private func makeIssueURL() -> URL? {
        var components = URLComponents(string: "\(Self.repoBase)/issues/new")!
        let composedBody = """
        \(bodyText)

        ---
        _Submitted from Spacetrucker Galactic v\(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))_
        _iOS \(UIDevice.current.systemVersion) · \(UIDevice.current.model)_
        _User-Agent: \(config.userAgent)_
        """
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "body", value: composedBody),
            URLQueryItem(name: "labels", value: kind.labelTag),
        ]
        return components.url
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
