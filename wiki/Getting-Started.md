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

1. **StatusGalactic** — Main iOS app
2. **StatusGalacticWidget** — WidgetKit extension
3. **StatusGalacticWatch** — Standalone watchOS app
4. **StatusGalacticWatchComplications** — Watch complications
5. **StatusGalacticTests** — Unit tests
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
| Run tests | `StatusGalacticTests/` |

---

## Common Issues

| Problem | Solution |
|---------|----------|
| "No such module" errors | Run `xcodegen generate` — the .xcodeproj may be stale |
| Location always San Francisco | Simulator defaults; use Features → Location → Custom Location |
| Weather shows "offline" | Simulator needs network; NWS occasionally rate-limits |
| Widget shows placeholder | Run the main app first to seed App Group with location data |
| Watch scheme missing | Ensure Xcode 15.4+ with watchOS 10+ SDK installed |
