# 2026-05-19 — Local notifications (M12)

## Scope

Milestone M12 of `ROADMAP.md`: local notifications for golden hour and astronomical dusk, scheduled out 14 days from the last known location. Fully client-side; no backend change.

## Files added

- `Services/SolarMath.swift` — pure-Swift NOAA solar-position approximation (Spencer 1971 / NOAA Solar Calculator). Computes sunrise / sunset for a given local calendar day at given lat/lng. Handles polar conditions (returns nil for both events when |cos(H)| > 1).
- `Services/NotificationManager.swift` — `@Observable`, UserDefaults-backed enable toggles, requests `UNUserNotificationCenter` authorization, schedules `UNCalendarNotificationTrigger` requests with stable ID prefixes (`io.river.statusgalactic.goldenHour.<offset>` and `.astroDusk.<offset>`), purges only its own requests on reschedule.

## Files modified

- `App/StatusGalacticApp.swift` — adds `NotificationManager` to the environment, refreshes auth status at scene launch.
- `Features/Brief/BriefView.swift` — after a successful brief load, calls `notifications.reschedule(latitude:longitude:)` with the brief's own lat/lng (which already accounts for callsign resolution).
- `Features/Settings/SettingsView.swift` — Notifications section with two toggles (golden hour, astronomical dusk), next-fire relative timestamps, denied-state label, and a footer explaining that schedule times are locally approximated.

## Why client-side sunset math

The backend's brief returns only today's sunrise/sunset. Scheduling a 14-day rolling window without daily backend round-trips means computing sunset locally. We use the standard NOAA approximation, which is accurate to ~1 minute for mid-latitudes. The brief still drives the *displayed* event times (skyfield + JPL DE421 precision); local math is *only* used to plan notifications.

Validated by `SolarMathTests.testLaCrosseMayDay`, which asserts the local computation is within 3 minutes of the backend's skyfield-reported sunrise/sunset for La Crosse on 2026-05-19 (the smoke-test date used throughout this build).

## Tests added

- `SolarMathTests.testLaCrosseMayDay` — within 3 min of backend sunset/sunrise
- `SolarMathTests.testEquatorDayLengthRoughly12Hours` — equatorial sanity check (12h ± 12 min)
- `SolarMathTests.testOrderingHolds` — sunrise < sunset on the winter solstice at 43.8°N

12 tests pass total.

## Astronomical dusk approximation

`NotificationManager.approximateAstronomicalDuskOffset(latitudeAbs:)` returns sunset + (78 + 0.6 × max(0, |lat| - 40)) minutes. This is a coarse linear scaling from ~78 min at mid-latitude to longer in the north. Adequate for scheduling: the user gets a ping near astronomical dusk, then the brief shows the precise time. Document this as a known-different from the backend's true skyfield computation.

## Drift / parity risks for Android

1. **Algorithm match.** Android port should reuse the Spencer 1971 / NOAA formulas in Kotlin (same constants). Both clients should pass the same fixture: La Crosse 2026-05-19, sunrise within 3 min of 10:35 UTC, sunset within 3 min of 01:28 UTC next day. Encode as a shared Kotlin test backfill.
2. **Astro dusk offset table.** The 78 + 0.6×(|lat|-40) min approximation must be identical on Android or notifications will fire at different times across platforms for the same user. Document the formula in `MIGRATION_PLAN.md` once Android starts.
3. **ID prefix collision.** `io.river.statusgalactic.goldenHour.*` and `.astroDusk.*` are reserved. If Android uses a `NotificationManager` with shared categories from a backend push channel later, prefix collisions could cause cancellations to cross-fire. Distinct channels per source.
4. **Authorization status mapping.** iOS `UNAuthorizationStatus` (notDetermined / denied / authorized / provisional / ephemeral) does not map 1:1 to Android NotificationChannel + permission. Document the mapping when porting.
5. **14-day window vs 64-pending iOS limit.** Two notification kinds × 14 days = 28 requests, well under the 64 limit. If more reminder types are added (M14 widget updates?), recount.

## Push notifications (M13) still blocked

Backend has no push channel yet. M12 is fully client-side and ships today; M13 stays ⏳ pending backend work.
