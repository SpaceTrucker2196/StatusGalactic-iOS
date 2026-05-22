import SwiftUI

/// Short signup walkthrough for one of the third-party API keys the app
/// can consume. Surfaced via a small "info" affordance next to the
/// field in Settings so the user doesn't have to dig the URL out of
/// docs.
struct APIKeyInfo: Identifiable {
    let id: String
    let name: String
    let summary: String
    let steps: [String]
    let url: URL
    let isFree: Bool
    let rateLimit: String?

    static let aprsFi = APIKeyInfo(
        id: "aprs.fi",
        name: "aprs.fi API key",
        summary: "Powers APRS callsign lookups, message receive, and the My-Station fix details. Without it the RF tab can send messages but can't fetch anything from the network.",
        steps: [
            "Log into aprs.fi with your callsign (free account).",
            "Open My account → Web service API key.",
            "Click \"Generate new key\".",
            "Copy the 32-character string into Settings → APRS."
        ],
        url: URL(string: "https://aprs.fi/page/api")!,
        isFree: true,
        rateLimit: "≈ 1 request/second per key. Reasonable daily quota."
    )

    static let nasa = APIKeyInfo(
        id: "api.nasa.gov",
        name: "api.nasa.gov key",
        summary: "Used by the Astronomy Picture of the Day, the Near-Earth Object close-approach panel, and the DONKI CME tracker. DEMO_KEY works for a few requests/hour; a real key removes the throttle.",
        steps: [
            "Visit api.nasa.gov.",
            "Fill out the short form (first + last name, email).",
            "Receive the key by email immediately.",
            "Copy it into Settings → NASA."
        ],
        url: URL(string: "https://api.nasa.gov")!,
        isFree: true,
        rateLimit: "1,000 requests/hour per key. DEMO_KEY caps around 30/hour."
    )

    static let n2yo = APIKeyInfo(
        id: "n2yo.com",
        name: "n2yo.com API key",
        summary: "Optional. Adds upcoming visible ISS pass predictions for your coordinates to the Brief's Crewed Spacecraft section.",
        steps: [
            "Sign up at n2yo.com (free account, callsign optional).",
            "Open Profile → Personal API key.",
            "Copy the key into Settings → N2YO."
        ],
        url: URL(string: "https://www.n2yo.com/api/")!,
        isFree: true,
        rateLimit: "1,000 requests/hour per key."
    )

    static let userAgent = APIKeyInfo(
        id: "user-agent",
        name: "User-Agent string",
        summary: "NWS requires a contact-shaped User-Agent header on every weather request. The default identifies the app and a project URL; if you fork the app, change it to something they can reach you at.",
        steps: [
            "Format: \"AppName/version (contact)\"",
            "The contact can be a project URL or an email.",
            "Don't put your callsign or personal data here."
        ],
        url: URL(string: "https://www.weather.gov/documentation/services-web-api")!,
        isFree: true,
        rateLimit: "NWS doesn't publish a hard rate; be polite (a few hits/min)."
    )
}

/// Small info-circle that opens a popover with the matching `APIKeyInfo`.
struct APIKeyHelpButton: View {
    let info: APIKeyInfo
    @State private var showPopover = false

    var body: some View {
        Button {
            showPopover = true
        } label: {
            Image(systemName: "info.circle")
                .font(.body)
                .foregroundStyle(GalacticPalette.electricBlue)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("How to get a \(info.name)")
        .popover(isPresented: $showPopover, arrowEdge: .top) {
            APIKeyInfoView(info: info)
                .presentationCompactAdaptation(.popover)
        }
    }
}

private struct APIKeyInfoView: View {
    let info: APIKeyInfo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(info.name)
                        .font(.firaCode(.headline, weight: .bold))
                        .foregroundStyle(GalacticPalette.neonCyan)
                    Spacer()
                    if info.isFree {
                        Text("Free")
                            .font(.firaCode(.caption2, weight: .bold))
                            .foregroundStyle(GalacticPalette.mint)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(GalacticPalette.mint.opacity(0.18)))
                    }
                }

                Text(info.summary)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text("How to get one")
                    .font(.firaCode(.caption, weight: .semibold))
                    .foregroundStyle(GalacticPalette.peach)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(info.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i + 1).")
                                .font(.firaCode(.caption, weight: .bold))
                                .foregroundStyle(GalacticPalette.hotPink)
                                .monospacedDigit()
                                .frame(width: 18, alignment: .trailing)
                            Text(step)
                                .font(.firaCode(.caption))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if let rate = info.rateLimit {
                    Divider()
                    HStack(spacing: 6) {
                        Image(systemName: "speedometer")
                            .foregroundStyle(GalacticPalette.peach)
                        Text(rate)
                            .font(.firaCode(.caption2))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Link(destination: info.url) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square")
                        Text(info.url.host ?? info.url.absoluteString)
                            .font(.firaCode(.caption, weight: .semibold))
                    }
                    .foregroundStyle(GalacticPalette.hotPink)
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .frame(idealWidth: 340, idealHeight: 320)
    }
}
