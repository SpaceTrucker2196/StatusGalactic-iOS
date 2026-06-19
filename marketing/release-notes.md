# Spacetrucker Galactic — Release Notes

Authoritative changelog for App Store "What's New" entries and the GitHub Releases page. Keep newest first.

---

## v0.3 — Meshtastic tab (unreleased)

### Highlights

- **Mesh tab.** Pair Galactic with a nearby [Meshtastic](https://meshtastic.org) node over Bluetooth LE and use the node as your radio while the phone handles the UI. Live traffic feed, device-log tail, known-node directory, and broadcast text send/receive on the primary channel. Everything stays on-device — the iPhone never reaches the internet to make Mesh work.
- **Persistent mesh history.** Traffic + chat survive app relaunch via a SwiftData store pinned to the app's own sandbox (deliberately *not* the App Group container — Mesh history stays private to the main app). FIFO eviction at 5,000 traffic rows / 2,000 chat messages, plus a "Clear history" button in the STATUS section.

### Additions

- Five-tab `TabView` (Brief, RF, Callsigns, Mesh, Settings).
- New `MeshtasticService` (`@Observable @MainActor`) owning the BLE transport, protobuf codec, and SwiftData store.
- `MeshtasticTransport` protocol with two implementations: `MeshtasticBLETransport` (CoreBluetooth) for the real device, and `FakeMeshtasticTransport` in the test target that drives the service through realistic scenarios (handshake, RX text, TX broadcast, NodeInfo updates, log records) with no BLE hardware required.
- 17 new `MeshtasticServiceTests` scenarios, plus two regression tests covering a real-hardware bug (high-bit node-num crash) and the SwiftData store landing in the correct sandbox.
- `NSBluetoothAlwaysUsageDescription` Info.plist entry. The prompt is only ever shown when the user opens the Mesh tab.

### Dependencies

- One new third-party Swift package: Apple's Apache-2.0 [`swift-protobuf`](https://github.com/apple/swift-protobuf), scoped to the Mesh feature so it can decode the protobuf wire format. No other SDKs were added; the rest of the app remains system-frameworks-only.

### Licence posture

- Meshtastic protobuf bindings under `Services/Meshtastic/Generated/` were regenerated locally with `protoc-gen-swift` from a vendored snapshot of [`meshtastic/protobufs`](https://github.com/meshtastic/protobufs). The schema files (`.proto`) are GPLv3; the generated Swift binds against the Apache-2.0 `SwiftProtobuf` runtime. **No code was copied from the GPLv3 `Meshtastic-Apple` reference client.** See `StatusGalactic/Services/Meshtastic/proto/NOTICE.md`.

### Known limitations

- BLE transport only. TCP/Wi-Fi transport (firmware 2.7.4+) is deferred past v0.3.
- Primary channel only for text send/receive. No channel-management UI, no PSK rotation, no QR pairing.
- Foreground only — no background BLE scanning, no push notifications on incoming Mesh text.
- iPad layout still deferred (the app remains iPhone-only at launch).

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
