# Spacetrucker Galactic iOS Roadmap

Phases follow the CareTime convention: iOS ships first, Android mirrors. **As of v0.2 the app is fully standalone** (no backend dependency); iOS itself is the canonical implementation. Milestones are numbered Mxx so the future Android repo can key its milestones (Axx) to align.

---

## Phase A: MVP (single-user, foreground)

### M1: Project scaffold
**Goal:** xcodegen-generated Xcode project, SwiftUI app shell with three tabs (Brief, Callsigns, Settings) compiles and runs in simulator.
**Deliverables:** project.yml, App entry, ContentView TabView, Info.plist with location usage string.
**Status:** ✅

### M2: Core Location wrapper
**Goal:** Request when-in-use authorization, capture one-shot location, expose via `@Observable` LocationManager.
**Deliverables:** Services/LocationManager.swift, prompts with usage string on first run.
**Status:** ✅

### M3: Brief models (Codable, schema parity)
**Goal:** Decode every field the backend emits in `GET /brief` JSON without loss.
**Deliverables:** Models/Brief.swift with `Brief`, `EarthWeather`, `MarineWeather`, `SpaceWeather`, `SolarEvents`, `Moon`, `Planet`, `Launch`, `WeatherPeriod`. Custom date strategy handles ISO8601 with/without fractional seconds.
**Status:** ✅

### M4: Brief API client
**Goal:** Single call to backend with optional lat/lng/call/zone/tz. Async/await on URLSession. Returns `Brief` or typed error.
**Deliverables:** Services/BriefAPIClient.swift.
**Status:** ✅

### M5: Brief view (read-only render)
**Goal:** Display a loaded Brief as native SwiftUI sections matching the markdown rendering order: Earth, Marine, Space, Sun (with twilight), Moon, Planets, Launches.
**Deliverables:** Features/Brief/BriefView, BriefDetailView, section subviews.
**Status:** ✅

### M6: Callsign registry
**Goal:** Add, list, delete APRS callsigns persisted to UserDefaults. Tapping a callsign loads its brief.
**Deliverables:** Services/CallsignStore.swift, Features/Callsigns/CallsignsView, AddCallsignView.
**Status:** ✅

### M7: Settings (server URL, marine zone)
**Goal:** Configure backend base URL and default marine zone.
**Deliverables:** Services/ServerConfig.swift, Features/Settings/SettingsView.
**Status:** ✅

---

## Phase B: Polish

### M8: Pull-to-refresh + last-fetched timestamp
**Goal:** Standard `refreshable` modifier, show "Updated 2 min ago" in the brief header.
**Status:** ✅

### M9: Error states with retry
**Goal:** Try Again button on top-level error, source-level error footer in BriefDetailView.
**Status:** ✅

### M10: Sun day strip
**Goal:** Horizontal 24-hour strip with colored bands for astronomical / nautical / civil twilight and daylight, with a "now" indicator and sunrise/sunset glyphs. Visualization driven by event times from the backend, no client-side altitude math.
**Status:** ✅

### M11: Callsign live position via aprs.fi proxy
**Goal:** New backend endpoint `GET /aprs/locate?call=X`. iOS CallsignDetailView with MapKit showing last-known position, comment, and a refresh button.
**Status:** ✅

---

## Phase C: Notifications

### M12: Local notifications for golden hour and astronomical dusk
**Goal:** Schedule local notifications at sunset minus 30 min and at astronomical dusk for the user's last known location. Refreshes after every brief load. Schedules up to 14 days ahead.
**Deliverables:**
- `Services/SolarMath.swift` — pure-Swift NOAA solar-position approximation for scheduling (validated within 3 min of backend skyfield)
- `Services/NotificationManager.swift` — UN authorization, 14-day rolling schedule, cancel-all
- Settings section with toggles and next-fire timestamps
**Status:** ✅

### M13: Push notifications via backend
**Goal:** Register device token with backend; backend POSTs Galactic briefs to APNs at user's chosen schedule.
**Dependencies:** Backend push channel (weathergalactic roadmap).
**Status:** ❌ Out of scope (v0.2 made the app standalone; client no longer talks to a backend).

---

## Phase D: Cross-platform / extras

### M14: Widget (small + medium)
**Goal:** Home-screen widget showing current brief headline (location, weather, sun events, Kp).
**Deliverables:**
- New extension target `StatusGalacticWidget` (XcodeGen `app-extension`)
- `BriefWidget` (StaticConfiguration), `BriefWidgetProvider` (30-min refresh policy), `BriefWidgetView` (small + medium)
- Shared sources: `Models/Brief.swift` + `Services/BriefAPIClient.swift` compiled into both the app and the widget
- Small: location, current temp, current condition, next sun event with relative time
- Medium: + sunrise / sunset / next golden hour + moon phase + Kp index
**Implementation:** App Groups (`group.com.spacetrucker.statusgalactic`) wired across all four targets via `Services/Brief/SharedDefaults.swift`. The main app writes lat/lng + User-Agent on every successful brief load; the widget reads them at timeline time. `WidgetConfig` remains as a defensive fallback for the (now uncommon) case where the App Group entitlement isn't resolvable at runtime.
**Status:** ✅

### M15: watchOS companion
**Goal:** Standalone watchOS app + WidgetKit complications.
**Deliverables:**
- New `StatusGalacticWatch` target (watchOS 10+ standalone app, `WKWatchOnly: true`)
- New `StatusGalacticWatchComplications` extension target with `BriefComplication` supporting `accessoryCircular`, `accessoryCorner`, `accessoryInline`, `accessoryRectangular`
- Watch app: location header, current weather card, space weather card, sun card with next event countdown, moon card
- Shares `Models/Brief.swift`, `Services/ClientConfig.swift`, `Services/LocationManager.swift`, `Services/Brief/`, `Services/Astronomy/` with the iOS target (no separate framework)
**Note:** Source verified compile-clean via XcodeGen. watchOS 26.5 SDK is installed locally as of 2026-05; the scheme builds and runs end-to-end on the paired watch simulator. Real-hardware verification still pending.
**Status:** ✅ (source + simulator); ⏳ (real Apple Watch hardware run)

### M16: Apple Maps integration
**Goal:** Open callsign last-known position or brief location in Apple Maps for navigation or pin display.
**Deliverables:**
- `Services/MapsLauncher.swift` — `MKMapItem.openInMaps` wrapper with two modes (directions / show pin)
- `CallsignDetailView` gains "Get directions in Maps" and "Show in Maps" rows when a fix is loaded
- `BriefDetailView` location header gains a small map button to open the brief's coordinate in Maps
**Status:** ✅

---

## Dependencies on the backend

| iOS milestone | Backend requirement | Backend status |
|---------------|---------------------|----------------|
| M4 | `GET /brief` with lat/lng/call/zone/tz | ✅ (v0.4) |
| M11 | `GET /aprs/locate?call=X` proxy endpoint | ✅ (v0.5) |
| M13 | Push delivery channel | ⏳ |

---

## How to update this file

Mark a milestone ✅ when its deliverables ship to main. Add new milestones at the end of the relevant phase; do not renumber. When Android porting begins, copy this file to `StatusGalactic-Android/MIGRATION_PLAN.md` and add an `A1..Axx` column keyed to these `Mxx` IDs.
