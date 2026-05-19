# 2026-05-19 — Phase B polish (M8..M11)

## Scope

Milestones M8 through M11 of `ROADMAP.md`:
- M8: pull-to-refresh and last-fetched timestamp
- M9: top-level error retry button
- M10: SunStrip horizontal twilight visualization
- M11: callsign last-known position with MapKit

## Backend changes

weathergalactic gained a single new endpoint for M11:

```
GET /aprs/locate?call=W9FJC
-> APRSFix { call, lat, lng, comment }
```

Thin wrapper around the existing `resolve_callsign` source function. Returns 502 with the underlying APRS error message if lookup fails. No change to brief schema.

Backend bumps to v0.5 conceptually (commit pending in this session).

## iOS changes

### M8 — pull-to-refresh
Added `.refreshable { await refresh() }` on `BriefView`'s content. Last-fetched timestamp already lived in `LocationHeader` from M5. No new types.

### M9 — error retry
In the `.error` case of `BriefView.content`, wrapped `ContentUnavailableView` in a `VStack` with a `Button("Try Again")` calling the same refresh function. No state changes; pressing the button transitions through `.loading → .loaded | .error` the same way as the toolbar refresh.

### M10 — SunStrip
New file: `StatusGalactic/Features/Brief/SunStrip.swift`. Renders a 24-hour horizontal strip:
- Bands computed from the `SolarEvents` event times in chronological order: astronomical dawn → nautical dawn → civil dawn → sunrise → sunset → civil dusk → nautical dusk → astronomical dusk. Skips missing events (polar conditions).
- Bands colored: astronomical dark (very dark blue), astronomical twilight (deep blue), nautical (medium blue), civil (light blue), daylight (warm yellow).
- A 1.5pt vertical "now" line.
- Tiny ↑ / ↓ glyphs over sunrise and sunset positions.

Embedded into `BriefDetailView`'s Sun section directly above the existing LabeledContent rows.

Crucially, no client-side astronomy math. The strip is built entirely from event times the backend already emits via skyfield. This keeps the implementation portable to Android (Compose: a `Canvas` or `Row` of colored Boxes) without duplicating ephemeris logic.

### M11 — CallsignDetailView
New file: `StatusGalactic/Features/Callsigns/CallsignDetailView.swift`. Pushed from `CallsignsView` via `NavigationLink(value: Callsign.self)` and `.navigationDestination`. Shows:
- Callsign and label at top
- Map (MapKit `Map(position:)` with a `Marker`) of last-known position
- Coordinates and APRS comment
- Refresh button
- Destructive remove button

Loads via new `Services/APRSClient.swift` calling `/aprs/locate`. Reuses `BriefAPIError` (renamed conceptually but kept as the shared transport-error type since the structure is identical: invalidURL, badResponse, decoding, transport). Worth promoting to a shared `HTTPClientError` if a third client emerges.

Camera position is initialized to `.automatic`, then snapped to a 0.5° span centered on the fix once the lookup returns.

## Tests

No new tests. The existing decoding and store tests still pass (9 total).

A future iteration should add `APRSClient` tests with `URLProtocol` stubs for the locate endpoint. Logged as a M9 follow-up but not blocking.

## Drift / parity risks for Android

1. **MapKit equivalent.** Android port should use Google Maps SDK or osmdroid (no licensing). `Marker` maps to a `Marker` in `MapView` either way.
2. **SunStrip math.** The segment-building algorithm is pure: sort events, iterate, take time deltas, divide by 86400. Trivially portable to Kotlin. Document the band colors as a shared constant table in `MIGRATION_PLAN.md` so both clients render the same palette.
3. **Error type sharing.** `BriefAPIError` is now used by both `BriefAPIClient` and `APRSClient`. Android equivalent should likewise share. If a third endpoint shows up (e.g., subscribers list), rename to `WeatherGalacticAPIError` or split.
4. **`/aprs/locate` JSON shape.** Returns `{call, lat, lng, comment}` (no timestamp). If we add `last_heard` later it must be optional in both clients.
