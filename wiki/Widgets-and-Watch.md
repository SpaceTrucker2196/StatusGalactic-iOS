# Widgets & Watch

Galactic extends beyond the main app with home-screen widgets and a standalone Apple Watch companion. This page documents both.

---

## Table of Contents

- [Home-Screen Widgets](#home-screen-widgets)
- [Apple Watch App](#apple-watch-app)
- [Watch Complications](#watch-complications)
- [Shared Data Architecture](#shared-data-architecture)

---

## Home-Screen Widgets

![Widget](../docs/assets/img/screens/11-widget.png)

### Overview

Galactic provides WidgetKit widgets in two sizes, offering at-a-glance information without opening the app.

### Small Widget

Displays:
- Current location name
- Temperature and conditions
- Next sun event (e.g., "Sunset in 2h 14m")

### Medium Widget

Everything in the small widget, plus:
- Sunrise and sunset times
- Next golden hour window
- Moon phase icon and illumination percentage
- Current Kp index
- R/S/G storm scale pills (Radio blackout / Solar radiation / Geomagnetic)
- Aurora probability (if elevated)

### Timeline & Refresh

| Parameter | Value |
|-----------|-------|
| Refresh policy | 30-minute timeline |
| Data source | App Group shared `UserDefaults` |
| Fallback | `WidgetConfig` defensive defaults if App Group unavailable |

The widget **does not make API calls itself** for the brief data. Instead:
1. The main app writes the latest brief snapshot to the App Group container on every successful refresh
2. The widget's `BriefWidgetProvider` reads from the App Group at timeline entry generation time
3. If the App Group data is stale (>1 hour), the widget shows a "Tap to refresh" prompt

### Implementation Files

```
StatusGalacticWidget/
├── StatusGalacticWidgetBundle.swift  # @main WidgetBundle entry
├── BriefWidget.swift                # Widget configuration declaration
├── BriefWidgetProvider.swift        # TimelineProvider (generates timeline entries)
├── BriefWidgetView.swift            # SwiftUI view for small + medium
├── WidgetConfig.swift               # Fallback configuration
└── Info.plist
```

---

## Apple Watch App

### Overview

A **standalone** watchOS 10+ app that provides a condensed Galactic brief on your wrist. It operates independently — it has its own location manager and fetches data directly from public APIs.

### Screens

The watch app shows a vertical scroll of cards:

1. **Location header** — city/area name and coordinates
2. **Weather card** — current temperature, conditions, wind
3. **Space weather card** — Kp index, solar flux, storm scales
4. **Sun card** — next sunrise/sunset with countdown timer
5. **Moon card** — phase name, illumination, icon

### Architecture

The watch app shares source code with the iOS app (compiled into both targets via XcodeGen):

| Shared | Watch-specific |
|--------|---------------|
| `Models/Brief.swift` | `WatchRootView.swift` |
| `Services/ClientConfig.swift` | `WatchBriefView.swift` |
| `Services/LocationManager.swift` | `WatchBriefViewModel.swift` |
| `Services/Brief/*` (all clients) | `StatusGalacticWatchApp.swift` |
| `Services/Astronomy/*` | |

### Implementation Files

```
StatusGalacticWatch/
├── StatusGalacticWatchApp.swift    # @main WatchKit app entry
├── WatchRootView.swift            # Root navigation
├── WatchBriefView.swift           # Brief display (condensed)
├── WatchBriefViewModel.swift      # Brief loading + state
├── Info.plist
└── Resources/
    └── Assets.xcassets/           # Watch-specific app icon
```

### Limitations vs. iOS App

| Feature | iOS | Watch |
|---------|:---:|:-----:|
| Full brief (all sections) | ✅ | Subset |
| APRS messaging | ✅ | ❌ |
| POTA/SOTA spots | ✅ | ❌ |
| DX cluster | ✅ | ❌ |
| Interactive map | ✅ | ❌ |
| Marine zone selection | ✅ | Uses iOS setting |
| Notifications | ✅ | Mirrored from iPhone |

---

## Watch Complications

### Overview

WidgetKit-based complications for watchOS, providing quick-glance Galactic data on any watch face.

### Supported Families

| Family | What it shows |
|--------|--------------|
| `accessoryCircular` | Kp index gauge (0–9 scale, color-coded) |
| `accessoryCorner` | Next sun event (sunrise/sunset) with countdown |
| `accessoryInline` | Single-line brief: "Kp 3 · ☀ 6:42a · 🌙 73%" |
| `accessoryRectangular` | Multi-line: weather + Kp + sun times + moon |

### Timeline

Complications use WidgetKit's complication timeline with a 30-minute refresh cadence. Data is read from the App Group container (same mechanism as iOS widgets).

### Implementation Files

```
StatusGalacticWatchComplications/
├── StatusGalacticWatchComplicationsBundle.swift  # @main WidgetBundle
├── BriefComplication.swift                      # Complication views per family
├── WatchComplicationProvider.swift              # Timeline provider
├── Info.plist
└── StatusGalacticWatchComplications.entitlements
```

---

## Shared Data Architecture

All four targets (iOS app, iOS widget, watch app, watch complications) share data through **App Groups**.

```
┌──────────────────────┐
│   iOS App (main)     │──writes──→┐
└──────────────────────┘           │
                                   ↓
                     ┌───────────────────────────┐
                     │  App Group UserDefaults    │
                     │  group.com.spacetrucker.   │
                     │  statusgalactic            │
                     │                           │
                     │  Keys:                    │
                     │  • latitude               │
                     │  • longitude              │
                     │  • userAgent              │
                     │  • marineZone             │
                     │  • lastBriefJSON          │
                     │  • lastUpdated            │
                     └───────────────────────────┘
                                   ↑
┌──────────────────────┐           │
│   iOS Widget         │──reads────┘
└──────────────────────┘           │
┌──────────────────────┐           │
│   Watch App          │──reads────┘
└──────────────────────┘           │
┌──────────────────────┐           │
│   Watch Complications│──reads────┘
└──────────────────────┘
```

### SharedDefaults.swift

The `SharedDefaults` helper provides type-safe access to the App Group container:

```swift
// Write (main app, on every successful brief load):
SharedDefaults.store.set(lat, forKey: SharedDefaults.Keys.latitude)
SharedDefaults.store.set(lng, forKey: SharedDefaults.Keys.longitude)
SharedDefaults.store.set(userAgent, forKey: SharedDefaults.Keys.userAgent)

// Read (widget/complication provider):
let lat = SharedDefaults.store.double(forKey: SharedDefaults.Keys.latitude)
```

### Entitlements

Each target has its own `.entitlements` file declaring the App Group:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.spacetrucker.statusgalactic</string>
</array>
```
