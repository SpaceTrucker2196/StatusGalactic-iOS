# APRS & Callsigns

Galactic provides a receive-side APRS experience and a callsign registry for tracking stations of interest. This page documents both features in detail.

---

## Table of Contents

- [APRS Overview](#aprs-overview)
- [Callsign Registry](#callsign-registry)
- [Station Position Lookups](#station-position-lookups)
- [APRS Messaging (Receive-Only)](#aprs-messaging-receive-only)
- [DX Statistics](#dx-statistics)
- [APRS Symbol Rendering](#aprs-symbol-rendering)
- [Maps Integration](#maps-integration)
- [My Station View](#my-station-view)
- [Configuration](#configuration)

---

## APRS Overview

The **Automatic Packet Reporting System (APRS)** is an amateur radio protocol for real-time position reporting, messaging, and telemetry. Galactic integrates with APRS through the [aprs.fi](https://aprs.fi) public API to provide:

- Last-known position of any APRS station
- Message thread viewing
- Path-derived DX statistics
- Station symbol display

> ⚠️ **Galactic is receive-only.** It reads data from aprs.fi — it does not transmit APRS packets. For TX, use a radio with a TNC (Terminal Node Controller).

---

## Callsign Registry

### What It Does

Save callsigns of stations you want to track. Each saved callsign gives you:
- One-tap position lookup
- Full brief at their last-known location
- Map display of their position
- Notes field for your own reference

### How It Works

The `CallsignStore` persists callsigns to `UserDefaults` as JSON:

```
Callsign {
    call: String        // e.g., "W7XYZ-9"
    label: String       // e.g., "Dad's truck"
    notes: String       // free-form notes
    addedAt: Date       // when you added it
}
```

### Operations

| Action | Description |
|--------|-------------|
| **Add** | Enter a callsign (with optional SSID), label, and notes |
| **List** | See all saved callsigns with labels |
| **Tap** | Load a brief at that station's last-known position |
| **Delete** | Swipe to remove |

### Normalization

Callsigns are automatically normalized:
- Uppercased
- Whitespace trimmed
- SSID preserved (e.g., `W7XYZ-9` stays as-is)
- Duplicates prevented

---

## Station Position Lookups

When you tap a saved callsign (or use the APRS tab), Galactic queries aprs.fi:

```
GET https://api.aprs.fi/api/get?name={CALL}&what=loc&apikey={KEY}&format=json
```

### Response Data

| Field | Description |
|-------|-------------|
| Latitude / Longitude | Last-known position |
| Timestamp | When the position was reported |
| Comment | Station comment string (often includes speed, course, status) |
| Symbol | APRS symbol table + code (rendered as icon) |
| Path | Digipeater path used to reach the network |
| Speed / Course | If mobile, speed and heading |

### After Lookup

Once a position is resolved, you can:
1. **View on map** — MapKit annotation at the station's coordinates
2. **Load brief there** — Fetch a full Galactic brief for that location
3. **Get directions** — Open Apple Maps with driving directions to the station
4. **Show in Maps** — Drop a pin in Apple Maps

---

## APRS Messaging (Receive-Only)

The APRS tab includes a messaging view that shows message threads between stations:

- View conversations between any two callsigns
- Messages are fetched from aprs.fi's message API
- Thread-style display with timestamps
- Compose view is present for UI completeness but routes through aprs.fi (read-only in practice)

### Implementation

- `APRSMessaging.swift` — Client for fetching message threads
- `APRSThreadView.swift` — Thread display UI
- `APRSComposeView.swift` — Compose interface
- `APRSMessageStore.swift` — Local message cache

---

## DX Statistics

For each tracked station, Galactic computes path-derived DX statistics:

- **Maximum distance** reached (from digipeater path analysis)
- **Bearing** to the station from your position
- **Great-circle distance** between you and the station
- **Path analysis** — which digipeaters relayed the packet

### Implementation

- `APRSDXStats.swift` — DX statistics computation
- `APRSPathParser.swift` — Parses APRS path strings into structured data
- `APRSStationLogStore.swift` — Historical position log for tracked stations

---

## APRS Symbol Rendering

APRS defines a symbol table with hundreds of icons (cars, trucks, houses, weather stations, boats, etc.). Galactic renders these as native SwiftUI views:

- `APRSSymbolIcon.swift` — Maps APRS symbol table/code pairs to SF Symbols or custom drawn icons
- Displayed inline in station lists and detail views
- Fallback to a generic pin for unrecognized symbols

### Common Symbols

| Symbol | Meaning |
|--------|---------|
| 🚗 | Car/mobile |
| 🏠 | House/home station |
| ⛵ | Boat/maritime |
| 🏔️ | Mountain/hiking |
| ☁️ | Weather station |
| 📡 | Digipeater |
| ✈️ | Aircraft |

---

## Maps Integration

Galactic integrates with Apple Maps for spatial context:

### In Callsign Detail View

- **"Show in Maps"** — Opens Apple Maps with a pin at the station's position
- **"Get Directions"** — Opens Apple Maps with driving directions from your current location to the station

### In Brief Detail View

- **Map button** in the location header opens the brief's coordinates in Apple Maps

### Implementation

`MapsLauncher.swift` wraps `MKMapItem.openInMaps` with two modes:
- `.showPin` — displays a pin at the coordinates
- `.directions` — launches turn-by-turn navigation

---

## My Station View

The "My Station" section in the APRS tab shows your own callsign's status:

- Your last-known position on aprs.fi
- Your APRS path (which digis you're hitting)
- Distance and bearing from your current device location
- DX statistics for your own packets

This requires your callsign to be configured in Settings.

### Implementation

- `MyStationViews.swift` — dedicated view for your own callsign data
- Uses the same `APRSClient` lookup but with `ClientConfig.myCallsign`

---

## Configuration

| Setting | Location | Purpose |
|---------|----------|---------|
| **My Callsign** | Settings | Your amateur radio callsign (for "My Station" feature) |
| **aprs.fi API Key** | Settings | Required for all APRS lookups (free at aprs.fi) |

### Getting an aprs.fi API Key

1. Go to [aprs.fi](https://aprs.fi)
2. Create an account (free)
3. Navigate to **My account → API keys**
4. Generate a read-only key
5. Paste it into Galactic Settings

Without a key, APRS features are simply unavailable — the rest of the app works normally.

---

## Privacy

- Your callsign and API key are stored in `UserDefaults` on-device only
- APRS lookups go directly to `api.aprs.fi` — no intermediary
- Your position is never reported to aprs.fi (receive-only)
- No callsign data is shared with any third party
