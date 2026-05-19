# Status Galactic for iOS

Native iOS client for the [Weather Galactic](https://github.com/SpaceTrucker2196/weathergalactic) personal almanac. Earth weather, marine weather, space weather, sunrise/sunset and twilight, moon phase, planetary positions, and upcoming launches, briefed for wherever you are right now.

## Features

- **Location-aware** via Core Location. Tap refresh and the app sends your current coordinates to the backend.
- **Callsign tracking.** Add APRS callsigns (your own and friends') and load a brief at any of their last-known positions.
- **Marine zone** per session, for coastal and sailing use.
- **Full Galactic brief** decoded from the backend: earth, marine, space, sun (with civil/nautical/astronomical twilight), moon, planets, launches.
- **Pure-Swift, no third-party deps.** Swift 5.10+, SwiftUI, iOS 17+.

## Quick start

Prerequisites:
- Xcode 15.4+
- iOS 17+ simulator or device
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- A running Weather Galactic backend (`pip install -e .` then `weathergalactic serve` from the [backend repo](https://github.com/SpaceTrucker2196/weathergalactic))

```bash
git clone https://github.com/SpaceTrucker2196/StatusGalactic-iOS.git
cd StatusGalactic-iOS
xcodegen generate
open StatusGalactic.xcodeproj
# Run on Simulator. In Settings tab, set the server URL to your backend.
```

The default server URL is `http://localhost:8000`. ATS is configured to allow local-network HTTP for development; ship a real HTTPS endpoint before production distribution.

## Project layout

```
StatusGalactic/
  App/             entry point, root TabView, Info.plist, asset catalog
  Models/          Codable mirrors of the backend Brief schema
  Services/        LocationManager (CoreLocation), BriefAPIClient, CallsignStore, ServerConfig
  Features/
    Brief/         BriefView, BriefDetailView, section subviews, ViewModel
    Callsigns/     CallsignsView, AddCallsignView
    Settings/      SettingsView
StatusGalacticTests/  XCTest unit tests for decoding and persistence
project.yml         XcodeGen spec
parity/             cross-platform parity workspace (see FEATURE_MATRIX.md)
docs/               design docs as needed
ROADMAP.md          milestone plan
FEATURE_MATRIX.md   cross-platform feature matrix (Backend / iOS / Android)
```

## Architecture

The iOS app is a thin client. The backend is the source of truth. iOS calls a single endpoint:

```
GET /brief?lat=&lng=&call=&zone=&tz=
```

and decodes the response into a `Brief` model that matches `weathergalactic`'s pydantic schema 1:1. All astronomy math (skyfield + JPL DE421), API fan-out (NWS, SWPC, tgftp, aprs.fi, Space Devs), and parallel/error handling live on the backend. iOS focuses on UX: Core Location, callsign registry, marine-zone selection, refresh, presentation.

## Status

v0.1 milestone. See `ROADMAP.md` for what's planned next, and `FEATURE_MATRIX.md` for cross-platform parity.

## License

MIT. See `LICENSE`.
