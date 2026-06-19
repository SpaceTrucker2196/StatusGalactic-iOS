# Getting Started

This guide walks you through setting up Spacetrucker Galactic for local development, from cloning to running in the simulator.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Xcode | 15.4+ | Mac App Store |
| iOS Simulator | iPhone with iOS 17+ | Included with Xcode |
| XcodeGen | Latest | `brew install xcodegen` |
| Git | Any recent version | Pre-installed on macOS |

**Optional:**
- An **aprs.fi read API key** (free — register at [aprs.fi](https://aprs.fi)) for callsign position lookups
- A **NASA API key** (free — register at [api.nasa.gov](https://api.nasa.gov)) for APOD backgrounds and NEO data
- An Apple Watch paired simulator for watchOS development
- A physical **Meshtastic node** (T-Beam, Heltec, RAK, etc.) for the Mesh tab — the simulator has no Bluetooth central, so this feature is only exercisable on a real iPhone
- **protoc + protoc-gen-swift** (`brew install protobuf swift-protobuf`) **only if you want to regenerate the vendored Meshtastic protobuf bindings**. The generated `*.pb.swift` files are committed under `StatusGalactic/Services/Meshtastic/Generated/`, so a routine build does not need either tool installed.

---

## Clone & Generate

```bash
git clone https://github.com/SpaceTrucker2196/StatusGalactic-iOS.git
cd StatusGalactic-iOS
xcodegen generate
open StatusGalactic.xcodeproj
```

XcodeGen reads `project.yml` and generates a fresh `.xcodeproj` with all targets, build settings, and entitlements configured.

---

## Project Configuration (`project.yml`)

The project is defined entirely in `project.yml` — no committed `.xcodeproj`. Key settings:

| Setting | Value |
|---------|-------|
| Bundle ID prefix | `com.spacetrucker.statusgalactic` |
| Deployment target | iOS 17.0 |
| Swift version | 5.10 |
| App Group | `group.com.spacetrucker.statusgalactic` |

### Targets generated:

1. **StatusGalactic** — Main iOS app (links the `SwiftProtobuf` Swift package; resolved automatically by SwiftPM on first build)
2. **StatusGalacticWidget** — WidgetKit extension
3. **StatusGalacticWatch** — Standalone watchOS app
4. **StatusGalacticWatchComplications** — Watch complications
5. **StatusGalacticTests** — Unit tests (also links `SwiftProtobuf` so the Mesh fakes/fixtures can construct `Meshtastic_*` types directly)
6. **StatusGalacticUITests** — UI tests + screenshot automation

---

## Running the App

1. Select the **StatusGalactic** scheme
2. Choose an iPhone 17 (or later) simulator
3. Press ⌘R to build and run

On first launch:
- The app requests "When In Use" location permission
- Grant it — the brief needs coordinates to fetch weather data
- The brief loads immediately with your simulator's default location (San Francisco)

### Simulating a custom location

In the simulator: **Features → Location → Custom Location** — enter any lat/lng to test different regions.

---

## Configuring API Keys

In the running app, go to **Settings** and enter:

| Key | Purpose | Where to get it |
|-----|---------|-----------------|
| aprs.fi API Key | APRS callsign lookups | [aprs.fi/page/api](https://aprs.fi/page/api) |
| NASA API Key | APOD + NEO data | [api.nasa.gov](https://api.nasa.gov) |
| User-Agent | Identifies you to NWS | Pre-filled; customize if you want |
| Marine Zone | Default forecast zone | e.g., `GMZ033` (see zone catalog in app) |

The app works without any API keys — APRS lookups and NASA features will simply be unavailable.

---

## Running Tests

```bash
xcodebuild -project StatusGalactic.xcodeproj -scheme StatusGalactic \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The test suite covers:
- Brief JSON encoding/decoding round-trip
- Callsign store add/remove/persistence
- Sunrise/sunset accuracy (validated against USNO data)
- Twilight event ordering (dawn < sunrise < sunset < dusk)
- Moon phase against backend reference values
- Planet position vs. Skyfield reference

---

## Building the Widget

The widget target (`StatusGalacticWidget`) builds automatically as a dependency of the main app. To test:

1. Run the main app at least once (writes location to App Group)
2. Add the widget to the simulator home screen
3. Or use the **Widget Gallery** in Xcode's preview canvas

---

## Building the Watch App

1. Select the **StatusGalacticWatch** scheme
2. Choose an Apple Watch simulator paired to your iPhone simulator
3. Build and run

The watch app is standalone — it has its own location manager and makes API calls independently.

---

## Project Layout for New Contributors

If you're new to the codebase, start here:

| Want to... | Look at... |
|-----------|-----------|
| Understand the data model | `StatusGalactic/Models/Brief.swift` |
| See how data is fetched | `StatusGalactic/Services/Brief/BriefBuilder.swift` |
| Add a new data source | Create a new client in `Services/Brief/`, add its output to `Brief.swift`, wire it in `BriefBuilder` |
| Modify the main UI | `StatusGalactic/Features/Brief/BriefView.swift` and its section views |
| Change settings | `StatusGalactic/Features/Settings/SettingsView.swift` |
| Update astronomy math | `StatusGalactic/Services/Astronomy/` |
| Modify the widget | `StatusGalacticWidget/BriefWidgetView.swift` |
| Work on the Meshtastic feature | `StatusGalactic/Services/Meshtastic/` (service, BLE transport, codec, store) + `StatusGalactic/Features/Meshtastic/` (view, viewmodel) |
| Add a Meshtastic test scenario | `StatusGalacticTests/Mesh/FakeMeshtasticTransport.swift` + `StatusGalacticTests/Mesh/MeshtasticServiceTests.swift` — the fake transport ships fixture builders on `Meshtastic_FromRadio` / `Meshtastic_LogRecord` so no CoreBluetooth or hardware is needed |
| Run tests | `StatusGalacticTests/` |

---

## Common Issues

| Problem | Solution |
|---------|----------|
| "No such module" errors | Run `xcodegen generate` — the .xcodeproj may be stale |
| "No such module 'SwiftProtobuf'" | First build hasn't resolved the SwiftPM package yet — build once with `xcodebuild ... -resolvePackageDependencies` or just `⌘B` in Xcode |
| Location always San Francisco | Simulator defaults; use Features → Location → Custom Location |
| Weather shows "offline" | Simulator needs network; NWS occasionally rate-limits |
| Widget shows placeholder | Run the main app first to seed App Group with location data |
| Watch scheme missing | Ensure Xcode 15.4+ with watchOS 10+ SDK installed |
| Mesh tab shows "Bluetooth Off" forever in the simulator | Expected — the iOS Simulator has no Bluetooth central. Test the Mesh tab on a real iPhone with a Meshtastic node nearby. |

---

## Regenerating the Meshtastic protobuf bindings

The Meshtastic wire protocol is protobufs; we vendor a snapshot of the upstream `.proto` files and check in the generated Swift bindings so the build is hermetic. To pull a newer protocol version:

```bash
# 1. Install the toolchain (one-time).
brew install protobuf swift-protobuf

# 2. Replace the vendored proto files from upstream.
git clone --depth 1 https://github.com/meshtastic/protobufs /tmp/mesh-protos
cp /tmp/mesh-protos/meshtastic/*.proto \
   StatusGalactic/Services/Meshtastic/proto/meshtastic/
cp /tmp/mesh-protos/nanopb.proto \
   StatusGalactic/Services/Meshtastic/proto/

# 3. Strip the upstream's `option swift_prefix = "";` line so generated
#    types pick up the standard Meshtastic_ prefix and don't collide
#    with Config/User/Channel/Position elsewhere in the app.
sed -i '' '/^option swift_prefix = "";/d' \
   StatusGalactic/Services/Meshtastic/proto/meshtastic/*.proto

# 4. Regenerate the *.pb.swift bindings.
cd StatusGalactic/Services/Meshtastic
rm -rf Generated/meshtastic Generated/nanopb.pb.swift
protoc \
  --proto_path=proto \
  --swift_out=Generated \
  --swift_opt=Visibility=Internal \
  proto/meshtastic/*.proto proto/nanopb.proto

# 5. Build + run the Mesh test suite to confirm nothing broke.
xcodebuild -project ../../../StatusGalactic.xcodeproj \
  -scheme StatusGalactic \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:StatusGalacticTests/MeshtasticServiceTests test
```

The modification described in step 3 is documented in `StatusGalactic/Services/Meshtastic/proto/NOTICE.md`. **No code is copied from the GPLv3 `Meshtastic-Apple` reference client** — only the schema is reused.
