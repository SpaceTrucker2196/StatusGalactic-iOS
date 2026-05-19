# Status Galactic iOS Roadmap

Phases follow the CareTime convention: iOS ships first, Android mirrors. Backend (weathergalactic) is the source of truth; this app is a thin client. Milestones are numbered Mxx so the future Android repo can key its milestones (Axx) to align.

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
**Status:** ⏳

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
**Known limit:** widget uses hardcoded fallback URL and location (`WidgetConfig`) until App Groups are wired up; requires a DEVELOPMENT_TEAM to do that.
**Status:** ✅

### M15: watchOS companion
**Goal:** Quick-glance complication and watch face showing twilight phase + Kp + temp.
**Status:** ⏳

### M16: Apple Maps integration
**Goal:** Tap a location in callsigns to open in Maps for navigation.
**Status:** ⏳

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
