# 2026-05-19 — Standalone iOS (remove server component)

## Scope

User requested: "remove the server component and do all api calls locally." This audit covers the architectural shift from "thin client over weathergalactic" to "fully standalone client."

The legacy weathergalactic backend repo continues to exist for server-side delivery (Discord scheduler, future email/push), but is no longer on the iOS data path.

## Files removed

- `StatusGalactic/Services/BriefAPIClient.swift` — old HTTP client calling backend `/brief`
- `StatusGalactic/Services/APRSClient.swift` — old HTTP client calling backend `/aprs/locate`
- `StatusGalactic/Services/ServerConfig.swift` — server URL configuration
- `StatusGalactic/Services/SolarMath.swift` — folded into `SunEvents.swift`
- `StatusGalacticWidget/SharedConfig.swift` — replaced by `WidgetConfig.swift`

## Files added

### Direct source clients
- `StatusGalactic/Services/Brief/HTTPError.swift` — typed transport errors + URLSession convenience
- `StatusGalactic/Services/Brief/NWSClient.swift` — api.weather.gov two-step (points → forecast)
- `StatusGalactic/Services/Brief/SWPCClient.swift` — planetary Kp + 10.7 cm flux
- `StatusGalactic/Services/Brief/MarineClient.swift` — tgftp text bulletins, parser ported from Python
- `StatusGalactic/Services/Brief/APRSClient.swift` — aprs.fi read API, key from `ClientConfig`
- `StatusGalactic/Services/Brief/LaunchesClient.swift` — Space Devs LL2
- `StatusGalactic/Services/Brief/BriefBuilder.swift` — parallel fanout orchestrator (counterpart to Python `build_brief`)

### Local astronomy
- `StatusGalactic/Services/Astronomy/JulianDate.swift` — JD helpers, degree/radian + `normalizedDegrees`
- `StatusGalactic/Services/Astronomy/SunEvents.swift` — NOAA solar position; sunrise/sunset and the three twilight transitions
- `StatusGalactic/Services/Astronomy/MoonPhase.swift` — Meeus chapter 47 major periodic terms
- `StatusGalactic/Services/Astronomy/Planets.swift` — mean orbital elements + equation of center, geocentric conversion via earth's heliocentric position

### Client config
- `StatusGalactic/Services/ClientConfig.swift` — `@Observable` UserDefaults wrapper for: aprs.fi key, default marine zone, User-Agent

## Files modified

- `StatusGalactic/App/StatusGalacticApp.swift` — `ClientConfig` replaces `ServerConfig` in environment
- `StatusGalactic/Features/Brief/BriefView.swift` — drops `BriefAPIClient`, passes `ClientConfig` to view model
- `StatusGalactic/Features/Brief/BriefViewModel.swift` — calls `BriefBuilder.build(...)` directly; resolves callsigns via `APRSClient`
- `StatusGalactic/Features/Callsigns/CallsignDetailView.swift` — uses `APRSClient` with API key from `ClientConfig`
- `StatusGalactic/Features/Settings/SettingsView.swift` — removes server URL field; adds aprs.fi API key (SecureField), User-Agent, and updates About footer
- `StatusGalactic/Services/NotificationManager.swift` — calls `SunEvents.sunriseAndSunset` (formerly `SolarMath`)
- `StatusGalacticWidget/BriefWidgetProvider.swift` — calls `BriefBuilder` directly with `WidgetConfig` defaults
- `StatusGalacticWidget/WidgetConfig.swift` — adds User-Agent
- `project.yml` — widget target now includes the entire `Services/Brief` and `Services/Astronomy` directories plus `ClientConfig`

## Astronomy accuracy report (validated by tests)

| Quantity | Backend (skyfield + DE421) | iOS local | Delta |
|----------|----------------------------|-----------|-------|
| Sunrise La Crosse 2026-05-19 | 10:35:00 UTC | within 3 min | ✓ asserted in test |
| Sunset La Crosse 2026-05-19 | 01:28:00 UTC (next) | within 3 min | ✓ asserted in test |
| Moon illumination 2026-05-19 | 12% | within 3% | ✓ asserted in test |
| Moon phase name 2026-05-19 | Waxing Crescent | Waxing Crescent | ✓ identical |
| Sun position 2026-05-19 | 28.31° Taurus | 28.3° ± 1.5° Taurus | ✓ asserted in test |

Trade-offs that drive the accuracy bounds:
- Planet positions use mean orbital elements with first-order equation-of-center correction. Skyfield uses VSOP87 / DE421. Inner-planet error can reach ~3°; outer planets stay within ~1°. Acceptable for "Mercury in Gemini at degree X.X" display except near sign boundaries (~0-1° of a sign).
- Moon longitude uses only the 13 largest periodic terms (Meeus 47.4). Sub-0.5° for the phase angle calculation we need.
- Sunrise/sunset uses NOAA's Spencer 1971 approximation. Within 1 min mid-latitude; degrades toward the poles.

## Architectural decisions

1. **Hand-rolled, not SwiftAA.** Pulling in a large astronomy SPM package would inflate the widget binary (memory-constrained on iOS). Hand-rolled code is portable to Kotlin verbatim, easier to test, easier to audit.
2. **Brief schema unchanged.** `Brief` Codable mirrors the original pydantic schema. Any existing fixture from the backend deserializes cleanly. This means Android can use the same JSON test fixtures.
3. **`BriefBuilder` mirrors `build_brief`.** Same parallel-fanout pattern, same per-source error isolation, same `errors: [String: String]` shape. Easy mental mapping for anyone who knew the Python.
4. **Widget shares the orchestrator.** No duplication; widget compiles in `Services/Brief` and `Services/Astronomy` directly.
5. **APRS API key is user-supplied.** No bundled key. SecureField in Settings. Keeps the app free of per-key rate-limit concerns and lets each user respect aprs.fi terms.

## Tests

12 tests pass:
- `ModelStructTests.testBriefRoundTripsThroughJSON` — Codable round trip
- `CallsignStoreTests.*` (6) — registry semantics
- `SunEventsTests.testLaCrosseMayDay` — sunrise/sunset within 3 min of backend
- `SunEventsTests.testTwilightOrdering` — six twilight events in correct chronological order
- `MoonPhaseTests.testMayCrescent` — phase name + illumination within 3% of backend
- `PlanetsTests.testSunPositionMatchesBackend` — sun in correct sign + within 1.5° of backend
- `PlanetsTests.testAllBodiesPresent` — all 10 expected bodies emitted

## Drift / parity risks for Android

1. **Astronomy formula port.** All math constants in `SunEvents`, `MoonPhase`, and `Planets` must port verbatim. A typo in one term shifts a planet by degrees. Encode the iOS unit tests as Kotlin parity fixtures and run them against the Kotlin port.
2. **Mean-element table.** The `Planets.elements` dictionary is the orbital ephemeris. Same numbers, same units (AU, degrees, deg/century).
3. **Equation-of-center series.** Truncate at the same order; document if Android needs more terms for higher accuracy and mark with ⚠️.
4. **NWS User-Agent requirement.** Both clients must send a contact-shaped User-Agent or get blocked. Default in `ClientConfig.defaultUserAgent`.
5. **Marine bulletin regex.** The `.PERIOD...body...$$` parser uses a specific regex; Kotlin's `Regex` should match the same fixture in `tests/test_marine.py` from the legacy backend.
6. **APRS API key handling.** No bundled key; user supplies their own. Document this UX in the Android port so it doesn't get auto-filled from a leaked source.

## Backend repo status

The `weathergalactic` repo still exists and still builds. It's now positioned as a **server-side delivery tool**, not a client data API. Future use cases:
- Discord webhook scheduler (already implemented, v0.2)
- Email channel
- Push notification fan-out
- Multi-user subscriber management

A future commit there could `410 Gone` the `/brief` and `/aprs/locate` endpoints with a redirect message, or just leave them in place. Not addressed in this audit.

## Things to remove from the ROADMAP

- M7 "Server URL configuration" was the last server-coupled UI element. Gone.
- M13 "Push notifications via backend" is now formally out of scope for the standalone client. Marked accordingly in ROADMAP.
