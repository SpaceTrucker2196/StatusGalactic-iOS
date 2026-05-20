# Parity Log

Chronological one-liner log of parity-relevant sessions. Append-only.

Format: `YYYY-MM-DD — milestone or scope — what happened — link to audit if any`

---

2026-05-19 — M1..M7 — iOS MVP scaffold shipped. Backend at weathergalactic v0.4. No Android repo yet. — `audits/2026-05-19-ios-mvp-bootstrap.md`
2026-05-19 — M8..M11 — Phase B shipped: pull-to-refresh, error retry, SunStrip visualization, CallsignDetailView with MapKit. Backend gained `GET /aprs/locate` (v0.5). — `audits/2026-05-19-phase-b-polish.md`
2026-05-19 — M12 — Local notifications for golden hour and astronomical dusk. Client-side SolarMath (NOAA) for 14-day rolling schedule. No backend change. — `audits/2026-05-19-local-notifications.md`
2026-05-19 — M14 — Home-screen widget (small + medium) via new StatusGalacticWidget extension target. Shares Brief models + API client with the app. App Group sync deferred until DEVELOPMENT_TEAM is set. — `audits/2026-05-19-widget.md`
2026-05-19 — v0.2 standalone — Removed dependency on weathergalactic backend. All data sources fetched directly from origin (NWS, SWPC, marine, aprs.fi, Space Devs). Astronomy computed locally (NOAA + Meeus). Backend remains for server-side delivery only. — `audits/2026-05-19-standalone-iOS.md`
2026-05-20 — M15 watchOS — Added StatusGalacticWatch app target + StatusGalacticWatchComplications extension. Both share Brief models, Services/Brief, Services/Astronomy, ClientConfig, and LocationManager with the iOS target. Source verified via XcodeGen; runtime build pending watchOS SDK install (Xcode > Settings > Components). — `audits/2026-05-20-watchos.md`
2026-05-20 — M16 Maps deep link — Added MapsLauncher wrapping MKMapItem.openInMaps with directions and show-pin modes. Wired into CallsignDetailView (two new buttons when a fix is loaded) and BriefDetailView header (small map button on the location row). iOS-only (watch target does not include MapsLauncher). Closes Phase D.
