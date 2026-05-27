# Notifications

Galactic schedules local notifications to alert you about time-sensitive astronomical and space weather events. All scheduling happens on-device — no push notification server is involved.

---

## Table of Contents

- [Overview](#overview)
- [Notification Types](#notification-types)
- [Scheduling Mechanism](#scheduling-mechanism)
- [Configuration](#configuration)
- [Implementation Details](#implementation-details)

---

## Overview

Galactic uses `UNUserNotificationCenter` to schedule local notifications up to **14 days ahead**. The schedule is refreshed every time a brief loads successfully, ensuring notifications stay accurate as the sun's position changes day to day.

**Key principles:**
- All notifications are local — no server, no push tokens, no APNs
- Schedule refreshes on every brief load (user-initiated)
- Cooldown logic prevents duplicate alerts for ongoing events
- Users control everything via toggles in Settings

---

## Notification Types

### Golden Hour Alert

| Parameter | Value |
|-----------|-------|
| **Trigger** | 30 minutes before sunset |
| **Purpose** | Photography, visual observation, that warm light before dark |
| **ID prefix** | `io.river.statusgalactic.goldenHour` |
| **Content** | "Golden hour begins in 30 minutes — sunset at {time}" |

### Astronomical Dusk Alert

| Parameter | Value |
|-----------|-------|
| **Trigger** | At astronomical twilight end (sun 18° below horizon) |
| **Purpose** | Sky is now fully dark — ideal for stargazing, deep-sky observation |
| **ID prefix** | `io.river.statusgalactic.astroDusk` |
| **Content** | "Astronomical dusk — sky is fully dark" |

### Aurora Alert

| Parameter | Value |
|-----------|-------|
| **Trigger** | When OVATION aurora probability at your latitude exceeds your threshold |
| **Purpose** | Heads-up to go outside and look north (or south, in the southern hemisphere) |
| **ID prefix** | `io.river.statusgalactic.spaceWX` |
| **Cooldown** | 90 minutes between re-alerts for the same event |
| **Threshold** | User-configurable (default: 30%) |

### Geomagnetic Storm Alert

| Parameter | Value |
|-----------|-------|
| **Trigger** | When Kp/storm scale reaches the user's configured minimum level |
| **Purpose** | HF propagation impact — bands may close, aurora may be visible |
| **Cooldown** | 90 minutes between re-alerts |

---

## Scheduling Mechanism

### 14-Day Rolling Schedule

On every successful brief load:

1. **Compute sun events** for the next 14 days at the user's last-known coordinates using the on-device astronomy engine (`SunEvents.swift`)
2. **Cancel all existing** golden hour and astronomical dusk notifications
3. **Schedule new notifications** for each day's computed times
4. Result: up to 28 notifications in the queue (14 golden hours + 14 dusks)

This rolling approach means:
- Notifications automatically adjust as days get longer/shorter
- Moving to a new location updates all times on next refresh
- No background processing needed — the OS fires them at the scheduled time

### Space Weather Alerts (Real-time)

Aurora and storm alerts work differently:
- They're evaluated on every brief refresh
- If the threshold is crossed **and** the cooldown has expired, a notification fires immediately
- The "last fired" timestamp is stored in UserDefaults to prevent re-alerting

---

## Configuration

All notification settings are in the **Settings** tab:

| Setting | Default | Description |
|---------|---------|-------------|
| Golden Hour | Off | Toggle golden hour 30-min warning |
| Astronomical Dusk | Off | Toggle full-dark notification |
| Aurora Alerts | Off | Toggle aurora probability alerts |
| Aurora Threshold | 30% | Minimum probability to trigger |
| Storm Alerts | Off | Toggle geomagnetic storm alerts |
| Storm Min Level | G1 | Minimum storm scale to trigger |

### Next-Fire Display

Settings shows the next scheduled fire time for golden hour and astronomical dusk, so you can verify the schedule looks correct:
- "Next golden hour: Today at 7:42 PM"
- "Next astro dusk: Today at 9:18 PM"

---

## Implementation Details

### File: `Services/NotificationManager.swift`

The `NotificationManager` class is `@Observable` and manages:

```
NotificationManager
├── Authorization request (UNUserNotificationCenter)
├── Golden hour scheduling (14-day lookahead)
├── Astronomical dusk scheduling (14-day lookahead)
├── Aurora threshold alerts (with cooldown)
├── Storm level alerts (with cooldown)
├── Next-fire timestamp tracking
└── Cancel-all on disable
```

### Authorization Flow

1. First toggle activation calls `UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound])`
2. If denied, toggles are disabled with a "Enable in Settings" prompt
3. Authorization status is re-checked on every app foreground

### Cooldown Logic

For space weather alerts that can persist for hours:

```
last_fired = UserDefaults timestamp for this alert type
cooldown = 90 minutes

if (now - last_fired) < cooldown:
    skip — don't re-alert for the same ongoing event
else:
    fire notification
    update last_fired = now
```

This prevents the user from getting pinged every 5 minutes during a sustained storm.

### Identifier Strategy

Each notification uses a deterministic ID:
- `io.river.statusgalactic.goldenHour.2026-05-27` — one per day
- `io.river.statusgalactic.astroDusk.2026-05-27` — one per day
- `io.river.statusgalactic.spaceWX.aurora` — single slot (cooldown-managed)
- `io.river.statusgalactic.spaceWX.storm` — single slot (cooldown-managed)

The date-based IDs mean canceling and re-scheduling is clean — old IDs are automatically replaced.

---

## Privacy Note

Notification scheduling uses only the coordinates from `LocationManager.lastLocation`. These coordinates never leave the device for notification purposes — all sun event times are computed locally by the astronomy engine.
