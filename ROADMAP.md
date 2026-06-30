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

## Phase E: HF radio + space-weather depth (v0.2 expansion)

The v0.2 work bloomed past "ports the original brief to a standalone iOS
app." Captured retroactively here so the milestone history reflects what
actually shipped.

### M17: SolarHam-tier HF data
**Goal:** Surface every datum a HF operator routinely checks on solarham.com without leaving the app.
**Deliverables:**
- Active regions + flare history (NOAA SRS / GOES)
- 3-day Kp forecast + 27-day F10.7 outlook (SWPC)
- Solar wind speed + IMF Bz (DSCOVR via SWPC)
- WWV/WWVH propagation bulletin parser
- D-RAP + DONKI CMEs + R/S/G storm scales
- Ionosonde MUF/foF2 (prop.kc2g.com)
- Local aurora probability (OVATION) + HF band conditions
**Status:** ✅

### M18: Ham activity feeds
**Goal:** Live ham activity from anywhere, with distance to viewer.
**Deliverables:**
- POTA spots (Parks On The Air)
- SOTA spots (Summits On The Air)
- DX Cluster (dxsummit.fi)
- RepeaterBook nearby repeaters
**Status:** ✅

### M19: RF tab consolidation
**Goal:** Move every ham-radio-flavored surface out of the general Brief into a dedicated RF tab.
**Deliverables:**
- New tab with station header (APRS-symbol icon, passcode, location fix)
- aprs.fi-backed messaging: inbox, threads, compose, bulletins
- Path-derived DX stats (today / month / year)
- 5-minute freshness gating on refresh so tab switches don't pound the APIs
**Status:** ✅

### M20: NWS + space-weather alerts
**Goal:** Severe weather + aurora + R/S/G storm escalations as notifications and inline chips.
**Deliverables:**
- NWS active alerts (CAP severity) on the brief
- Severe + Extreme auto-notify
- Aurora alert ≥ threshold pct (user-configurable)
- Storm-scale alert ≥ user-configurable G/S/R level
- Watch + widget surface the same alert summary
**Status:** ✅

### M21: Brief visualization upgrades
**Goal:** Turn the read-only brief into a glanceable dashboard.
**Deliverables:**
- Animated sun panel (SDO HMI/AIA frames with buffering progress)
- GOES X-ray 24h sparkline (log-scale flare-class axis)
- Tides, solar wind 24h, earthquake timeline sparklines
- Tappable solar almanac with Kp + F10.7 flux sparklines
- Phosphor section headers + storm-scale row layout polish
- Aurora forecast view with global oval imagery
**Status:** ✅

### M22: Cosmos + earth-physical breadth
**Goal:** Bring in the data sources that round out a "what's happening around you, on every axis" report.
**Deliverables:**
- Disk-backed image cache (90-day TTL) + APOD background
- Mars Curiosity + Perseverance feeds with freshness badge
- Upcoming crewed launches
- USGS earthquakes near viewer
- Planet ephemeris + sidereal footer
- Magnetic declination (WMM-2025)
- River gauge + flood-risk derivation
**Status:** ✅

---

## Phase F: Launch readiness

Everything between "feature-complete" and "live on the App Store."

### M23: Deterministic XCUITest screenshot pipeline
**Goal:** App Store screenshots regenerable from a single command, no manual sim driving.
**Deliverables:**
- `ScreenshotMode.swift` seeder (gated on `-UITEST_SCREENSHOT_MODE` launch arg)
- Hero `Brief` fixture covering every section the gallery showcases
- `StatusGalacticUITests/ScreenshotTests.swift` — 11 cases, swipe-count anchored
- `scripts/screenshots.sh` orchestrator: status-bar override, xcresult extraction, sips resample, flake retry
- Dark-mode force in screenshot mode so Callsigns + Settings chrome matches the neon-cyan accent
**Status:** ✅

### M24: App Store submission package
**Goal:** Everything App Store Connect needs to accept the v0.2 build.
**Deliverables:**
- Marketing copy drafted in `marketing/app-store.md`
- Privacy / support / landing pages live on GitHub Pages
- 6.9" + 6.1" screenshot galleries generated and resampled to target sizes
- Manual home-screen widget shot (#11) — not automatable via XCUITest
- App icon (1024×1024 source, opaque RGB, no pre-applied corners)
- Privacy nutrition labels filled in App Store Connect
**Status:** 🚧 widget shot + nutrition labels pending

### M25: Real-hardware verification
**Goal:** Run end-to-end on physical devices before TestFlight to catch what the sim hides.
**Deliverables:**
- iPhone (any 16/17-class device) — install Release build, walk every tab, confirm widget timeline + notifications fire
- Apple Watch (Series 9+ or Ultra 2) — install paired Watch app, confirm complications render on Modular + Infograph faces
**Status:** ⏳ Not Started

### M26: TestFlight + build-number policy
**Goal:** First TestFlight push out the door, with a sustainable build-number scheme so subsequent uploads don't get rejected.
**Deliverables:**
- Pick a build-number scheme — monotonic integer, date-of-day (`260526`), or CI-driven
- Document in `project.yml` comment or `scripts/`
- Push first build to TestFlight, complete Apple's beta review
- Internal testers added
**Status:** ⏳ Not Started

---

## Later (no committed timeline)

### M27: Apple Watch hardware run
Mirror of M25 watch leg — gated on owning the hardware. Tracked separately because it can ship without blocking M24/M26.

### M28: Android port
Kotlin + Compose mirror keyed to `M1..M26`. See `FEATURE_MATRIX.md` for the parity table; no work has started.

---

## Backend dependencies (historical)

The app was backend-dependent through v0.1.x and went standalone at v0.2.
Kept here for archaeological context — no future milestone depends on a
backend.

| iOS milestone | Backend requirement | Backend status |
|---------------|---------------------|----------------|
| M4  | `GET /brief` with lat/lng/call/zone/tz   | ✅ (v0.4) — superseded by client-side fetch in v0.2 |
| M11 | `GET /aprs/locate?call=X` proxy endpoint | ✅ (v0.5) — superseded by direct aprs.fi calls in v0.2 |
| M13 | Push delivery channel                     | ❌ Dropped — local notifications cover the use case |

---

## How to update this file

Mark a milestone ✅ when its deliverables ship to main. Add new milestones at the end of the relevant phase; do not renumber. When Android porting begins, copy this file to `StatusGalactic-Android/MIGRATION_PLAN.md` and add an `A1..Axx` column keyed to these `Mxx` IDs.
