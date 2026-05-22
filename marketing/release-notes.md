# Spacetrucker Galactic — Release Notes

Authoritative changelog for App Store "What's New" entries and the GitHub Releases page. Keep newest first.

---

## v0.2 — Standalone (2026-05-20)

### Highlights

- **Spacetrucker Galactic now runs entirely on your device.** Every data source is fetched directly from its public origin; nothing is routed through a Spacetrucker Galactic server.
- All astronomy math (sun, moon, planets, twilight) computed locally with Meeus and NOAA formulas. No ephemeris file required, no licensing concerns.

### Additions

- Apple Watch app with five glance cards (location header, weather, space, sun with next-event countdown, moon).
- Watch complications for all four accessory families (circular, corner, inline, rectangular).
- Apple Maps deep linking: tap a callsign's coordinates for driving directions or a pin drop.
- Sun day strip visualization: 24-hour colored bands for astronomical, nautical, and civil twilight plus daylight, with a "now" indicator and sunrise/sunset glyphs.
- Local notifications for golden hour and astronomical dusk, scheduled fourteen days ahead.
- Home-screen widget in small and medium sizes.
- Settings: aprs.fi API key (SecureField), default marine zone, configurable User-Agent.

### Accessibility

- Sun day strip exposes a VoiceOver label that reads sunrise, sunset, and the current twilight phase.
- Haptic feedback on refresh: success when a brief loads, error when it fails.
- Guided empty state with "Allow Location" and "Open iOS Settings" actions when permission is missing.

### Removed

- The backend dependency. The previous `weathergalactic` HTTP server is no longer on the data path.

### Known limitations

- Planet positions use mean orbital elements with first-order equation-of-center correction. Accuracy is ~1° to 3° depending on the planet. Zodiac sign assignment is correct except very near sign boundaries.
- Widget and watch complications use a hardcoded fallback location until App Groups are wired up (requires a DEVELOPMENT_TEAM).

---

## v0.1 — Initial release

- Earth weather (NWS), marine weather (NWS coastal-zone text bulletins), space weather (NOAA SWPC).
- Sun events: sunrise, sunset, civil/nautical/astronomical twilight, golden-hour windows.
- Moon phase + illumination.
- Ten-body planetary positions.
- Upcoming launches via The Space Devs LL2.
- APRS callsign registry and lookup via aprs.fi.
- Core Location permission flow.
