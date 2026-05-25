---
title: Support
layout: default
---

# Spacetrucker Galactic (iOS) — Support

> Questions, bugs, or feedback: email
> **[support@river.io](mailto:support@river.io)** or open an issue on
> **[GitHub](https://github.com/SpaceTrucker2196/StatusGalactic-iOS/issues)**.
> We respond within a few business days.

---

## Common questions

### The brief shows no data / "offline" banner.
Spacetrucker Galactic fetches every source directly from its public
origin — if your device has no network, the brief will fall back to
on-device math (sun, moon, planets) and show an offline banner for the
network-sourced sections. Pull-to-refresh once you're back on a network.

### Location is wrong, or the forecast is for the wrong place.
The brief uses Core Location's one-shot fix. Make sure
**Settings → Privacy & Security → Location Services → Spacetrucker
Galactic** is set to **While Using the App**. If you're indoors with a
poor GPS fix, step outside or wait a few seconds and refresh.

### Callsign lookups say "API key missing" or "not authorized."
Callsign position lookups use aprs.fi's read API, which requires a free
account and a personal read key. Get one at
[aprs.fi → My Account → Web service API key](https://aprs.fi/), then
paste it into **Settings → APRS.fi API key**. The key is stored in
`UserDefaults` on this device only.

### My marine zone isn't showing a forecast.
Marine zones are NWS coastal text bulletins (GMZ, AMZ, PZZ, AN, …).
Set the zone in **Settings → Marine zone**, exactly as NWS formats it
(e.g. `GMZ033`). If the zone is valid but the bulletin source is slow,
the brief continues without it; the other sections still render.

### Golden hour / astronomical dusk notifications aren't firing.
The app schedules local notifications fourteen days ahead. Make sure
notifications are enabled at **Settings → Notifications → Spacetrucker
Galactic**, and enabled inside the app at **Settings → Notifications**.
If you've recently toggled the in-app switch, give the next golden-hour
or astronomical-dusk window a chance to arrive.

### The widget on my Home Screen isn't updating.
Widgets are scheduled by iOS, not by Spacetrucker Galactic. The system
generally refreshes widgets every ~15 minutes when your device is
active. Opening the app forces a fresh fetch and re-renders the
timeline.

### The watch app is empty / not loading.
The watch app shares a brief snapshot with the iPhone over WatchConnectivity
when the iPhone refreshes. Open the iPhone app, refresh, and the watch
should pick up the next snapshot. The four complication families
(circular, corner, inline, rectangular) are supported on Apple Watch
Series 4 and later.

### Planet positions are a few degrees off from Stellarium.
That's a known and intentional trade-off. Spacetrucker Galactic
computes planet positions from mean orbital elements plus the equation
of center (Meeus chapter 33 style), not from VSOP87 or a JPL
ephemeris. Accuracy is ~1–3°, which is fine for zodiac-sign and
roughly-where-is-it-in-the-sky purposes, but not for telescope pointing.
See `parity/audits/2026-05-19-standalone-iOS.md` in the repo for the
full accuracy report.

### How do I reset my User-Agent / API key / marine zone?
**Settings** has a clear button for each. Clearing the API key
disables callsign lookups; clearing the marine zone disables marine
bulletins; resetting the User-Agent restores the default
`StatusGalactic/<version> ([contact](mailto:support@river.io))` string
that NWS requires.

---

## What Spacetrucker Galactic does not do

- **Sync between devices.** One iPhone per install. iCloud Backup is
  the safety net for moving to a new phone.
- **Replace a marine HF / VHF radio** or any official weather
  briefing for aviation, maritime, or commercial use. Spacetrucker
  Galactic is a personal almanac.
- **Send anything to a Spacetrucker Galactic server.** There isn't
  one.
- **Track you, run analytics, or report crashes.** No third-party
  SDKs.
- **Background-track your location.** One fix per refresh, foreground
  only.

---

## Reporting a bug

Email **[support@river.io](mailto:support@river.io)** or open a GitHub
issue at
**[github.com/SpaceTrucker2196/StatusGalactic-iOS/issues](https://github.com/SpaceTrucker2196/StatusGalactic-iOS/issues)**
with:

- The version (Settings → at the bottom).
- What you were doing when the bug happened.
- What you expected vs. what actually happened.
- A screenshot if you can.

The app collects no logs or diagnostics, so if a bug is reproducible
you'll need to walk us through it.

---

[← back to Spacetrucker Galactic](./)
