# Spacetrucker Galactic Feature Matrix

Cross-platform parity tracking. **As of v0.2 there is no backend dependency for the iOS app.** Each client owns its own source clients and astronomy. The legacy `weathergalactic` repo remains for server-side delivery (Discord scheduler) but is not on the data path for the iOS app.

**Legend:**
- ✅ Implemented and shipped
- 🚧 In progress
- ⏳ Planned, not started
- ❌ Not applicable on this platform
- ⚠️ Drift (intentional divergence; see notes)

## Repos

| Platform | Repo | Role |
|----------|------|------|
| iOS | [StatusGalactic-iOS](https://github.com/SpaceTrucker2196/StatusGalactic-iOS) | Standalone (source of truth) |
| Android | StatusGalactic-Android | Future; mirrors iOS |
| Legacy backend | [weathergalactic](https://github.com/SpaceTrucker2196/weathergalactic) | Server-side delivery only (Discord, schedules). Not on client data path. |

## Brief sources

| Source | iOS | Android | Notes |
|--------|:---:|:-------:|-------|
| api.weather.gov (earth weather) | ✅ | ⏳ | Direct HTTP from client |
| tgftp.nws.noaa.gov (marine) | ✅ | ⏳ | Text bulletin, parsed client-side |
| services.swpc.noaa.gov (Kp + flux) | ✅ | ⏳ | Direct HTTP |
| ll.thespacedevs.com (launches) | ✅ | ⏳ | Direct HTTP |
| api.aprs.fi (callsign locate) | ✅ | ⏳ | Direct HTTP with API key in app settings |

## Mesh (local hardware)

| Source | iOS | Android | Notes |
|--------|:---:|:-------:|-------|
| Meshtastic node over BLE | ✅ | ⏳ | CoreBluetooth + `apple/swift-protobuf` (Apache-2.0); no internet hop |
| Meshtastic node over Wi-Fi/TCP | ⏳ | ⏳ | Deferred past v1; BLE only at launch |

## Astronomy (local computation)

| Quantity | iOS | Android | Notes |
|----------|:---:|:-------:|-------|
| Sunrise / sunset / twilight | ✅ | ⏳ | NOAA approximation, ~1 min accuracy mid-latitude |
| Golden hour windows | ✅ | ⏳ | sunset ± 30 min approximation |
| Moon phase | ✅ | ⏳ | Meeus 47 major periodic terms, <0.5° |
| Planet positions | ✅ | ⏳ | Mean orbital elements + EoC, ~1-3° accuracy |

## Brief sections (rendered)

| Feature | iOS | Android | Notes |
|---------|:---:|:-------:|-------|
| Earth weather | ✅ | ⏳ | |
| Marine weather | ✅ | ⏳ | |
| Space weather: Kp + flux + HF + aurora | ✅ | ⏳ | |
| Sunrise / sunset / golden hour | ✅ | ⏳ | |
| Civil / nautical / astronomical twilight | ✅ | ⏳ | |
| Moon phase + illumination | ✅ | ⏳ | |
| 10-body planetary positions | ✅ | ⏳ | |
| Upcoming launches | ✅ | ⏳ | |
| Sun day strip (twilight bands) | ✅ | ⏳ | Pure-data viz |
| APRS map (callsign last-known) | ✅ | ⏳ | MapKit on iOS |
| Meshtastic tab (BLE pair, live traffic, broadcast text) | ✅ | ⏳ | Service + BLE + protobuf codec + SwiftData store; vaporwave chrome |

## Inputs

| Feature | iOS | Android | Notes |
|---------|:---:|:-------:|-------|
| Manual lat / lng | ✅ | ⏳ | |
| Device location (Core Location / FusedLocation) | ✅ | ⏳ | |
| APRS callsign lookup | ✅ | ⏳ | API key in client settings |
| Callsign registry (add / list / remove) | ✅ | ⏳ | UserDefaults / DataStore |
| Marine zone selection | ✅ | ⏳ | |
| Timezone | ✅ | ⏳ | `TimeZone.current.identifier` |
| User-Agent string | ✅ | ⏳ | Required by NWS |

## Delivery

| Feature | iOS | Android | Notes |
|---------|:---:|:-------:|-------|
| Local notifications | ✅ | ⏳ | UNUserNotificationCenter; 14-day rolling schedule |
| Widget / glance | ✅ | ⏳ | WidgetKit (small + medium) |
| Watch app | ✅ | n/a | Standalone watchOS 10+ scheme; iOS-only side of the platform pair |
| Watch complications | ✅ | n/a | accessoryCircular / Corner / Inline / Rectangular |
| Maps deep linking | ✅ | ⏳ | Apple Maps / Google Maps Intent |
| Push notifications | ❌ | ⏳ | Out of scope for standalone client |

## Conventions

1. **Each client is the canonical implementation.** No shared server-side schema; the `Brief` Swift struct is the contract. Android Kotlin types must encode/decode the same JSON byte-for-byte (via the test fixture in `parity/audits/2026-05-19-standalone-iOS.md`).
2. **Astronomy formulas are documented constants.** Mean-element tables, Meeus periodic terms, NOAA zenith angles — all must be identical across platforms or briefs disagree about whether the moon is in Cancer or Leo.
3. **iOS ships first.** Android mirrors. Feature drift is documented in this matrix with ⚠️.
4. **Tests are mirrored.** Every iOS XCTest should have a Kotlin counterpart. Skip ones that test SwiftUI rendering.
5. **No backend dependency.** Both clients call public APIs directly. If a feature is impossible client-side (e.g., scheduled push delivery), document and skip.
6. **One approved third-party Swift package.** `apple/swift-protobuf` (Apache-2.0) is linked into the iOS target so the Meshtastic tab can decode the node's protobuf wire format. No other third-party SDKs. Android should mirror by using the equivalent Kotlin protobuf runtime.

## When Android porting begins

1. Create `StatusGalactic-Android/` (Kotlin + Compose).
2. Copy `ROADMAP.md` to `StatusGalactic-Android/MIGRATION_PLAN.md` and add: Swift→Kotlin type map, SwiftUI→Compose component map, Core Location → FusedLocationProviderClient, UserDefaults → DataStore, **astronomy formula port (verbatim)**.
3. Begin a parity session: append to `parity/log.md`, audit each source client port.
4. Validate astronomy by re-running iOS test fixtures in Kotlin (sunrise within 3 min, moon illumination within 3%, sun in correct zodiac sign).
