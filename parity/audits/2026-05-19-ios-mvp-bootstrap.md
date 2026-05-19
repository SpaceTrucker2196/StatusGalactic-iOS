# 2026-05-19 — iOS MVP Bootstrap

Initial commit of StatusGalactic-iOS. Establishes the parity baseline.

## Scope

Milestones M1 through M7 of `ROADMAP.md`. App scaffold, Core Location, Brief decoding, API client, brief rendering, callsign registry, settings.

## Backend version targeted

weathergalactic v0.4 (commit `4f06493`). Brief JSON schema includes:
- Earth (NWS), Marine (tgftp), Space (SWPC), Sun (skyfield with civil/nautical/astronomical twilight), Moon, 10-body Planets, Launches (LL2).

## Schema mapping (Python pydantic → Swift Codable)

| Backend type | iOS type | Notes |
|--------------|----------|-------|
| `Brief` | `Brief` | snake_case keys mapped via `CodingKeys` |
| `WeatherPeriod` | `WeatherPeriod` | |
| `EarthWeather` | `EarthWeather` | |
| `MarineWeather` | `MarineWeather` | `zone_id` → `zoneId` |
| `SpaceWeather` | `SpaceWeather` | |
| `SolarEvents` | `SolarEvents` | all 12 twilight + golden-hour fields preserved |
| `Moon` | `Moon` | |
| `Planet` | `Planet` | retrograde always false from backend currently |
| `Launch` | `Launch` | |

All datetime fields are decoded via a custom `JSONDecoder` strategy that handles ISO8601 with and without fractional seconds, since pydantic v2 emits both shapes depending on field source.

## Architecture decisions

1. **Thin client.** Astronomy math stays on the backend (skyfield + DE421). The iOS app never recomputes planetary positions or sunrise; it decodes the backend response.
2. **No external Swift dependencies.** Standard library, SwiftUI, Combine (implicit), CoreLocation, Foundation only. This keeps the Android porting story clean (no SwiftPM packages to translate).
3. **Persistence: UserDefaults.** Callsigns are a small list. SwiftData would be over-engineered. Android will use DataStore for the same role.
4. **State: `@Observable` (iOS 17+).** Forces deployment target to 17.0. Worth it for cleaner code than `ObservableObject`. Android equivalent: `StateFlow` / `MutableStateFlow` in ViewModel.

## Tests shipped

- `BriefDecodingTests` — full round-trip decode of a fixture Brief JSON. Asserts every section populates and snake_case mapping works.
- `CallsignStoreTests` — add, dedup (case insensitive), remove, persistence round-trip via in-memory `UserDefaults` suite.

## Known drift / parity risks

None yet; iOS is the only client. Items to watch when Android starts:

1. **Date format.** Kotlinx-serialization or moshi need an equivalent dual-format ISO8601 strategy. Pin this in a Kotlin parity test that decodes the same fixture JSON.
2. **Callsign normalization rule.** iOS uppercases and trims whitespace before dedup. Android must apply the identical rule, ideally driven by a shared test fixture.
3. **Marine zone string format.** iOS accepts any non-empty string and forwards to the backend. Android should not re-validate or normalize.
4. **Server URL trailing slash.** iOS `URLComponents.appendingPathComponent` is permissive. Android's `HttpUrl` is stricter. Document required form (no trailing slash on base URL).

## Next session triggers

- Backend ships push channel (M13 dependency).
- User decides to start Android port (kicks off `MIGRATION_PLAN.md` creation).
