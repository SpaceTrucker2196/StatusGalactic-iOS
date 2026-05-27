import Foundation

/// Stable accessibility identifiers for every interactive surface the app
/// exposes. The UITest target references the exact same constants
/// (project.yml lists this file under both target sources), so the test
/// suite never hard-codes string literals.
///
/// Convention:
///   - lowercase, dot-separated
///   - first segment = tab / surface
///   - last segment = action
///
/// Visible (VoiceOver) labels are still added inline on the views — these
/// identifiers are for test queries only.
enum A11yID {

    enum Brief {
        static let refresh              = "brief.refresh"
        static let sourcePicker         = "brief.source.picker"
        static let locationAllow        = "brief.location.allow"
        static let locationOpenSettings = "brief.location.openSettings"
        static let retry                = "brief.error.retry"
    }

    enum RF {
        static let refresh = "rf.refresh"
        static let compose = "rf.compose"
    }

    enum Callsigns {
        static let addToolbar = "callsigns.add"
        static let addEmpty   = "callsigns.add.empty"
        static let edit       = "callsigns.edit"
        static let list       = "callsigns.list"

        enum AddForm {
            static let call   = "callsigns.add.call"
            static let label  = "callsigns.add.label"
            static let notes  = "callsigns.add.notes"
            static let save   = "callsigns.add.save"
            static let cancel = "callsigns.add.cancel"
        }
    }

    enum Settings {
        static let callsign       = "settings.callsign"
        static let aprsKey        = "settings.aprs.apiKey"
        static let nasaKey        = "settings.nasa.apiKey"
        static let n2yoKey        = "settings.n2yo.apiKey"
        static let userAgent      = "settings.userAgent"
        static let marineZone     = "settings.marineZone"
        static let apodToggle     = "settings.imagery.apodToggle"
        static let clearCache     = "settings.imagery.clearCache"
        static let refreshLocation = "settings.location.refresh"
        static let feedback       = "settings.about.feedback"

        enum Notif {
            static let goldenHour       = "settings.notif.goldenHour"
            static let astroDusk        = "settings.notif.astroDusk"
            static let aurora           = "settings.notif.aurora"
            static let auroraThreshold  = "settings.notif.auroraThreshold"
            static let storm            = "settings.notif.storm"
            static let stormLevel       = "settings.notif.stormLevel"
        }
    }
}
