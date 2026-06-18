import Foundation

/// View-local state for the Meshtastic tab.
///
/// Source-of-truth state (connection, traffic, chat) lives on
/// `MeshtasticService`. This type holds purely UI concerns: the compose
/// field, the auto-scroll pause toggle, and the inline confirmation for
/// "Clear history".
@Observable
@MainActor
final class MeshtasticViewModel {
    /// Compose-field text. Cleared on send.
    var composeText: String = ""

    /// When true, the TRAFFIC log stops auto-scrolling to the newest entry
    /// so the user can hold their place while reading older rows.
    var trafficPaused: Bool = false

    /// Inline confirmation gate for the destructive "Clear history" action.
    /// Goes true on first tap, false on second tap or timeout.
    var clearArmed: Bool = false
}
