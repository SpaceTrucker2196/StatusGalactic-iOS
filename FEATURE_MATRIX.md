# Status Galactic Feature Matrix

Cross-platform parity tracking. Backend is the single source of truth; clients consume the same `GET /brief` JSON. Update this file whenever a feature ships, drifts, or moves on the roadmap.

**Legend:**
- ✅ Implemented and shipped
- 🚧 In progress (open PR or active branch)
- ⏳ Planned (in roadmap, not started)
- ❌ Not applicable on this platform
- ⚠️ Drift (intentional divergence; see notes)

## Repos

| Platform | Repo | Source of truth? |
|----------|------|-------------------|
| Backend | [weathergalactic](https://github.com/SpaceTrucker2196/weathergalactic) | ✅ (schema + computations) |
| iOS | [StatusGalactic-iOS](https://github.com/SpaceTrucker2196/StatusGalactic-iOS) | ✅ (client UX, ships first) |
| Android | StatusGalactic-Android | future; mirrors iOS |

## Brief sections (rendered from `GET /brief`)

| Feature | Backend | iOS | Android | Notes |
|---------|:-------:|:---:|:-------:|-------|
| Earth weather (NWS) | ✅ | ✅ | ⏳ | |
| Marine weather (tgftp bulletins) | ✅ | ✅ | ⏳ | |
| Space weather: Kp + 10.7 cm flux | ✅ | ✅ | ⏳ | |
| HF propagation summary | ✅ | ✅ | ⏳ | |
| Aurora likelihood | ✅ | ✅ | ⏳ | |
| Sunrise / sunset | ✅ | ✅ | ⏳ | |
| Golden hour windows | ✅ | ✅ | ⏳ | |
| Civil / nautical / astro twilight | ✅ | ✅ | ⏳ | |
| Moon phase + illumination | ✅ | ✅ | ⏳ | |
| 10-body planetary positions | ✅ | ✅ | ⏳ | |
| Upcoming launches (LL2) | ✅ | ✅ | ⏳ | |
| Sun day strip (twilight bands) | ❌ | ✅ | ⏳ | Client-only viz; uses backend event times |
| APRS map (callsign last-known position) | ✅ (`/aprs/locate`) | ✅ | ⏳ | iOS uses MapKit |

## Inputs

| Feature | Backend | iOS | Android | Notes |
|---------|:-------:|:---:|:-------:|-------|
| Manual lat / lng | ✅ | ✅ | ⏳ | |
| Device location (Core Location / FusedLocation) | ❌ | ✅ | ⏳ | Client-only |
| APRS callsign lookup (aprs.fi) | ✅ | ✅ | ⏳ | |
| Callsign registry (add / list / remove) | ❌ | ✅ | ⏳ | Client-only, UserDefaults / DataStore |
| Marine zone selection | ✅ | ✅ | ⏳ | |
| Timezone | ✅ | ✅ | ⏳ | iOS uses `TimeZone.current.identifier` |
| Configurable server URL | n/a | ✅ | ⏳ | Settings tab |

## Delivery

| Feature | Backend | iOS | Android | Notes |
|---------|:-------:|:---:|:-------:|-------|
| HTTP API (`/brief`, `/brief.md`) | ✅ | n/a | n/a | |
| Subscriber-driven scheduler | ✅ | n/a | n/a | |
| Discord webhook | ✅ | ❌ | ⏳ | Backend-side only |
| Local notifications | ❌ | ✅ | ⏳ | UNUserNotificationCenter / NotificationCompat; 14-day schedule, golden hour + astro dusk |
| Push notifications | ⏳ | ⏳ | ⏳ | APNs / FCM, requires backend hook |
| Widget / glance | ❌ | ✅ | ⏳ | WidgetKit (small + medium) / Glance |

## Conventions

1. **Backend is the canonical schema.** Both clients decode the same JSON. When a field is added on the backend, the iOS Codable model must update first (in lockstep with the PR); Android follows in a parity PR.
2. **iOS ships first.** Android does not get a feature before iOS. If a feature lives only on iOS for native reasons (Widget, watch), record it here and skip the Android column with ⏳ pending decision.
3. **Drift is documented.** Any intentional divergence between iOS and Android lives in this matrix with the ⚠️ symbol and a short note. Detailed drift entries belong in `parity/audits/`.
4. **Tests are mirrored.** Every iOS unit test in `StatusGalacticTests/` should have a Kotlin counterpart in the Android repo's `src/test/`. If a test cannot be mirrored, mark with ⚠️ and explain.
5. **Parity sessions are logged.** Each porting session adds a one-liner to `parity/log.md` linking to a detailed audit in `parity/audits/YYYY-MM-DD-<scope>.md`.

## When Android porting begins

1. Create `StatusGalactic-Android/` (Kotlin + Compose).
2. Copy `ROADMAP.md` to `StatusGalactic-Android/MIGRATION_PLAN.md` and add: Swift→Kotlin type map, SwiftUI→Compose component map, Core Location → FusedLocationProviderClient, UserDefaults → DataStore.
3. Begin a parity session: append to `parity/log.md`, create the first audit file for the brief decoding contract.
4. Update this matrix as Android features ship.
