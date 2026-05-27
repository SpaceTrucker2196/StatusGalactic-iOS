# Architecture

This document describes the internal architecture of Spacetrucker Galactic — how data flows from public APIs through the service layer into SwiftUI views, and how the app is organized into modules.

---

## Table of Contents

- [High-Level Overview](#high-level-overview)
- [Project Structure](#project-structure)
- [The Brief Pipeline](#the-brief-pipeline)
- [Layer Details](#layer-details)
- [Targets & Extensions](#targets--extensions)
- [Design Patterns](#design-patterns)
- [Concurrency Model](#concurrency-model)
- [State Management](#state-management)
- [Offline Behavior](#offline-behavior)

---

## High-Level Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        StatusGalactic.app                                │
│                                                                         │
│  ┌────────────────┐     ┌───────────────────────────────────────────┐  │
│  │   SwiftUI       │ ──→ │            BriefViewModel                 │  │
│  │   Views         │     │   (holds Brief, drives refresh lifecycle) │  │
│  └────────────────┘     └───────────────────────────────────────────┘  │
│                                     │                                   │
│                                     ↓                                   │
│                          ┌─────────────────────┐                        │
│                          │    BriefBuilder      │                        │
│                          │  (async fanout to    │                        │
│                          │   all data sources)  │                        │
│                          └─────────────────────┘                        │
│                                     │                                   │
│          ┌──────────────────────────┼──────────────────────┐            │
│          ↓                          ↓                      ↓            │
│  ┌──────────────────┐   ┌────────────────────┐   ┌──────────────┐     │
│  │  HTTP Clients     │   │  Astronomy Engine   │   │ CoreLocation │     │
│  │                   │   │                     │   │              │     │
│  │  NWSClient        │   │  SunEvents          │   │ LocationMgr  │     │
│  │  SWPCClient       │   │  MoonPhase          │   │              │     │
│  │  MarineClient     │   │  Planets            │   └──────────────┘     │
│  │  LaunchesClient   │   │  SiderealClock      │                        │
│  │  APRSClient       │   │  JulianDate         │                        │
│  │  POTAClient       │   │                     │                        │
│  │  SOTAClient       │   └────────────────────┘                        │
│  │  DXClusterClient  │                                                  │
│  │  OVATIONClient    │                                                  │
│  │  NEOClient        │                                                  │
│  │  EarthquakeClient │                                                  │
│  │  TidesClient      │                                                  │
│  │  RiverGaugeClient │                                                  │
│  │  IonosondeClient  │                                                  │
│  │  ... (30+ total)  │                                                  │
│  └──────────────────┘                                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
StatusGalactic-iOS/
├── StatusGalactic/                  # Main iOS app target
│   ├── App/                         # Entry point, root TabView, Info.plist
│   │   ├── StatusGalacticApp.swift  # @main App struct
│   │   ├── ContentView.swift        # Root TabView (RF, Brief, APRS, Callsigns, Settings)
│   │   └── Info.plist
│   ├── Models/
│   │   └── Brief.swift              # The Brief struct + all nested model types
│   ├── Services/
│   │   ├── Brief/                   # BriefBuilder + all HTTP source clients
│   │   ├── Astronomy/               # On-device computation (sun, moon, planets)
│   │   ├── LocationManager.swift    # Core Location wrapper (@Observable)
│   │   ├── CallsignStore.swift      # UserDefaults-backed callsign registry
│   │   ├── ClientConfig.swift       # User settings (API keys, marine zone, UA)
│   │   ├── NotificationManager.swift # Local notification scheduling
│   │   ├── MapsLauncher.swift       # Apple Maps deep-link helper
│   │   ├── BriefCache.swift         # Offline brief persistence
│   │   ├── ImageCache.swift         # In-memory image cache for APOD
│   │   ├── MarineZoneCatalog.swift  # All US NWS marine zone codes
│   │   ├── GalacticPalette.swift    # App color scheme
│   │   ├── GalacticSymbols.swift    # SF Symbol + custom symbol registry
│   │   └── Typography.swift         # Font scale definitions
│   ├── Features/
│   │   ├── Brief/                   # BriefView, BriefDetailView, all section panels
│   │   ├── APRS/                    # APRS messaging, DX stats, station views
│   │   ├── Callsigns/              # Add/list/detail callsign views
│   │   └── Settings/               # SettingsView, API key help, marine zone picker
│   ├── Screenshots/                 # Screenshot automation helpers
│   └── Resources/                   # Asset catalog (AppIcon, colors)
├── StatusGalacticWidget/            # WidgetKit extension
├── StatusGalacticWatch/             # Standalone watchOS app
├── StatusGalacticWatchComplications/ # Watch complication extension
├── StatusGalacticTests/             # XCTest suite
├── StatusGalacticUITests/           # UI automation tests
├── docs/                            # GitHub Pages marketing site
├── parity/                          # Cross-platform parity workspace
├── project.yml                      # XcodeGen project specification
├── ROADMAP.md                       # Milestone plan
└── FEATURE_MATRIX.md               # Cross-platform feature tracking
```

---

## The Brief Pipeline

The central abstraction in Galactic is the **Brief** — a single struct that holds everything the user sees in one refresh cycle. Here's how it's built:

### 1. Trigger

The user pulls to refresh, the app launches, or the widget timeline fires.

### 2. Location Resolution

`LocationManager` provides the current device coordinates via Core Location. Alternatively, a callsign lookup via `APRSClient` resolves a station's last-known position.

### 3. BriefBuilder Fanout

`BriefBuilder.build(lat:lng:marineZone:timezone:)` is called. It instantiates **every source client** and fires them all concurrently using Swift's structured concurrency (`async let` or `TaskGroup`):

```
NWSClient           → EarthWeather, WeatherAlerts
MarineClient        → MarineWeather
SWPCClient          → SpaceWeather (Kp, SFI)
LaunchesClient      → [Launch]
POTAClient          → [POTASpot]
SOTAClient          → [SOTASpot]
DXClusterClient     → [DXSpot]
OVATIONClient       → AuroraForecast
NEOClient           → [NearEarthObject]
EarthquakeClient    → [Earthquake]
TidesClient         → Tides
RiverGaugeClient    → RiverGauge
IonosondeClient     → [IonosondeStation]
SolarWindClient     → SolarWind
ActiveRegionsClient → [ActiveRegion]
DONKIClient         → [CMEEvent]
...
SunEvents.compute() → SolarEvents (on-device)
MoonPhase.compute() → Moon (on-device)
Planets.compute()   → [Planet] (on-device)
```

### 4. Error Isolation

Each source is wrapped in its own do/catch. If one API fails (NWS is down, no marine zone configured, NASA rate-limited), that section's field in the Brief is `nil` and the error is captured in `Brief.errors`. The rest of the brief still renders.

### 5. Assembly

All results are packed into a single `Brief` struct and returned to the view model.

### 6. Rendering

`BriefViewModel` publishes the Brief. SwiftUI views observe it and render each non-nil section. Nil sections are simply omitted — no error state shown unless everything failed.

---

## Layer Details

### Models Layer (`Models/Brief.swift`)

A single file defines the entire data contract:

- `Brief` — the root container with 40+ fields
- `EarthWeather`, `MarineWeather`, `SpaceWeather`, `SolarEvents`, `Moon`, `Planet`, `Launch`, etc.
- All types are `Codable` for JSON round-tripping (cache, widget data sharing)
- Custom `CodingKeys` map snake_case JSON to camelCase Swift

### Services Layer (`Services/`)

Two sub-categories:

**HTTP Clients** (`Services/Brief/`) — Each client is a lightweight struct with:
- A `URLSession` reference
- A `userAgent` string (required by NWS)
- One or more `async throws` methods that return decoded model types
- Proper error mapping via `HTTPError`

**Astronomy Engine** (`Services/Astronomy/`) — Pure computational modules:
- `JulianDate` — Calendar ↔ Julian Date conversion
- `SunEvents` — NOAA solar position algorithm for sunrise/sunset/twilight
- `MoonPhase` — Meeus chapter 47 periodic terms
- `Planets` — Mean orbital elements + equation of center for 10 bodies
- `SiderealClock` — Local sidereal time computation

### Features Layer (`Features/`)

Organized by tab/domain. Each feature folder typically contains:
- A view (SwiftUI `View` struct)
- A view model (where needed)
- Section subviews for complex layouts

### App Layer (`App/`)

Minimal — just the `@main` entry, root `TabView`, and Info.plist configuration.

---

## Targets & Extensions

| Target | Platform | Role |
|--------|----------|------|
| `StatusGalactic` | iOS 17+ | Main app |
| `StatusGalacticWidget` | iOS 17+ | WidgetKit extension (small + medium) |
| `StatusGalacticWatch` | watchOS 10+ | Standalone watch app |
| `StatusGalacticWatchComplications` | watchOS 10+ | WidgetKit complications |
| `StatusGalacticTests` | iOS 17+ | XCTest unit tests |
| `StatusGalacticUITests` | iOS 17+ | UI automation + screenshot capture |

All targets share source files from `Models/` and `Services/` — no separate framework. XcodeGen's `sources` array compiles the same Swift files into each target that needs them.

**App Groups:** `group.com.spacetrucker.statusgalactic` connects all four targets. The main app writes location + User-Agent to `SharedDefaults`; widgets and complications read them at timeline/complication refresh time.

---

## Design Patterns

### Pattern: Observable State

The app uses Swift's `@Observable` macro (Observation framework, iOS 17+) for state management:

- `LocationManager` — publishes `lastLocation`, `authorizationStatus`
- `ClientConfig` — publishes all user settings
- `CallsignStore` — publishes `callsigns` array
- `NotificationManager` — publishes authorization status, toggle states, next fire times
- `BriefViewModel` — publishes the current `Brief`, loading state, errors

### Pattern: Fanout with Error Isolation

`BriefBuilder` fires all network requests concurrently. Each source is independent — failure in one never blocks or cancels others. This is critical because the app contacts 8+ different APIs with varying reliability.

### Pattern: Protocol-Free Clients

HTTP clients are simple structs, not protocol-abstracted. They take a `URLSession` and a `userAgent`, expose `async throws` methods, and return concrete types. Testing injects a custom `URLSession` with mock responses.

### Pattern: Shared Source Compilation

Rather than creating a framework, shared code (Models, Services) is compiled directly into each target via XcodeGen's `sources` list. This keeps the project simple and avoids dynamic framework overhead.

---

## Concurrency Model

The app is built on Swift structured concurrency:

- **`async/await`** throughout the service layer
- **`TaskGroup`** or parallel `async let` in `BriefBuilder` for fanout
- **`@MainActor`** on view models that publish to SwiftUI
- **No Combine.** The app uses Observation framework exclusively
- **No GCD.** No `DispatchQueue` usage — pure structured concurrency

---

## State Management

| State | Storage | Scope |
|-------|---------|-------|
| Current brief | In-memory (`BriefViewModel`) + disk cache | Session / offline fallback |
| User settings | `UserDefaults` | Persistent, device-local |
| Saved callsigns | `UserDefaults` (JSON-encoded) | Persistent, device-local |
| Notification schedule | iOS notification center | Managed by OS |
| Widget data | App Group `UserDefaults` | Shared across targets |
| Location | Core Location (ephemeral) | Per-request |

---

## Offline Behavior

When network is unavailable:

1. **Astronomy sections always work** — sun, moon, planets, magnetic declination, sidereal time are computed locally with no network dependency.
2. **Cached brief** — `BriefCache` stores the last successful brief to disk. On launch with no network, the cached brief renders with a "Last updated X ago" header.
3. **Graceful degradation** — Network-sourced sections (weather, space weather, launches, POTA, etc.) show a quiet "offline" indicator rather than an error state.
4. **No crash** — The app never crashes on network failure. Every HTTP call is independently caught.
