---
title: Support
layout: default
---

# Spacetrucker Galactic (iOS) — Support

> Questions, bugs, or feedback: email
> **[support@river.io](mailto:support@river.io)** or open an issue on
> **[GitHub](https://github.com/SpaceTrucker2196/StatusGalactic-iOS/issues)**.
> We respond within a few business days. 73.

---

## Radio operator FAQ

### What's the HF propagation summary actually based on?
NOAA SWPC's published planetary Kp index, 10.7 cm solar flux (SFI),
and A index. The app pulls those values directly and runs a small
rules table to map them to a plain-English read on noise floor and
band-by-band conditions. It's a tendency indicator, not a propagation
model — for serious planning, cross-check with a tool like VOACAP.

### How fresh is the Kp / SFI data?
SWPC publishes Kp on a 3-hour cadence and SFI daily. The app fetches
on launch, on pull-to-refresh, and on foreground-from-background when
the cached brief is older than **5 minutes**. If you're staring at
the Kp number waiting for a flare to bite, refresh manually — Spacetrucker
Galactic won't poll the server in the background.

### The DX cluster / POTA / SOTA list is empty or stale.
The RF tab loads those feeds from their public endpoints. If your
device is on a captive-portal Wi-Fi (campground, marina) or a marginal
cell connection, the request can time out. The app degrades gracefully:
sections that couldn't load show an offline marker and the rest of the
brief still renders. Pull-to-refresh once you have a real connection.

### My callsign lookups say "API key missing" or "not authorized."
aprs.fi requires a free account and a personal read API key for
position queries. Get one at
[aprs.fi → My Account → Web service API key](https://aprs.fi/), then
paste it into **Settings → APRS.fi API key**. The key is stored in
`UserDefaults` on this device only and is sent only to aprs.fi.

### Why doesn't the app post APRS positions?
By design — Spacetrucker Galactic is a **receive-only** APRS client.
It reads positions and bulletins via the aprs.fi read API. If you want
to beacon, use a TNC, a radio with built-in APRS, or a dedicated
client (APRSdroid, PinPoint, YAAC). Spacetrucker Galactic stays out
of the transmit path on purpose.

### Magnetic declination — what model and epoch?
On-device computation against the current World Magnetic Model (WMM)
coefficients. Accurate to within a fraction of a degree for the
current epoch; refresh the app version every couple of years to pick
up the next WMM cycle.

### Will it remind me about a contest, an aurora, or a band opening?
Not yet. The only local notifications the app schedules today are
**golden hour** and **astronomical dusk** — useful for antenna work
that should not happen in the dark. Aurora / Kp threshold alerts are
on the roadmap; track on GitHub Issues.

### Field-day / portable use — does the app work without cell?
Sun/moon/planet math, magnetic declination, and golden-hour /
astro-dusk notifications work fully offline (they're computed
on-device against your last known location). Anything that needs a
live feed (Kp, SFI, NWS forecast, marine bulletin, DX cluster, POTA,
SOTA, APRS, launches) requires a working network round-trip and will
show an offline marker if it can't reach the source.

---

## General FAQ

### The brief shows no data / "offline" banner everywhere.
Spacetrucker Galactic fetches every network source directly from its
public origin. If your device has no network, the brief falls back to
on-device math (sun, moon, planets, declination) and shows an offline
banner for the network-sourced sections. Pull-to-refresh once you're
back on a network.

### Location is wrong, or the forecast is for the wrong place.
The brief uses Core Location's one-shot fix. Make sure
**Settings → Privacy & Security → Location Services → Spacetrucker
Galactic** is set to **While Using the App**. If you're indoors with
a poor GPS fix, step outside or wait a few seconds and refresh.

### My marine zone isn't showing a forecast.
Marine zones are NWS coastal text bulletins (GMZ, AMZ, PZZ, AN, …).
Set the zone in **Settings → Marine zone**, exactly as NWS formats it
(e.g. `GMZ033`). If the zone is valid but the bulletin source is slow,
the brief continues without it and the other sections still render.

### Golden hour / astronomical dusk notifications aren't firing.
The app schedules local notifications fourteen days ahead. Make sure
notifications are enabled at **Settings → Notifications → Spacetrucker
Galactic**, and enabled inside the app at **Settings → Notifications**.
If you've recently toggled the in-app switch, give the next golden-hour
or astronomical-dusk window a chance to arrive.

### The widget on my Home Screen isn't updating.
Widgets are scheduled by iOS, not by Spacetrucker Galactic. The
system generally refreshes widgets every ~15 minutes when your device
is active. Opening the app forces a fresh fetch and re-renders the
timeline.

### The watch app is empty / not loading.
The watch app shares a brief snapshot with the iPhone over
WatchConnectivity when the iPhone refreshes. Open the iPhone app,
refresh, and the watch should pick up the next snapshot. The four
complication families (circular, corner, inline, rectangular) are
supported on Apple Watch Series 4 and later.

### Planet positions are a few degrees off from Stellarium.
That's a known and intentional trade-off. Spacetrucker Galactic
computes planet positions from mean orbital elements plus the equation
of center (Meeus chapter 33 style), not from VSOP87 or a JPL
ephemeris. Accuracy is ~1–3°, which is fine for zodiac-sign and
roughly-where-is-it-in-the-sky purposes, but not for telescope pointing.

### How do I reset my User-Agent / API key / marine zone?
**Settings** has a clear control for each. Clearing the API key
disables callsign lookups; clearing the marine zone disables marine
bulletins; resetting the User-Agent restores the default
`StatusGalactic/<version> ([support@river.io](mailto:support@river.io))`
string that NWS requires.

---

## What Spacetrucker Galactic does not do

- **Transmit on APRS.** Receive-only by design. Use a real TNC or a
  dedicated APRS client to beacon.
- **Replace VOACAP, ITURHFProp, or a real propagation model.** The HF
  summary is a quick-look indicator, not a forecast.
- **Sync between devices.** One iPhone per install. iCloud Backup is
  the safety net for moving to a new phone.
- **Replace marine / aviation weather briefings** for commercial use.
  Spacetrucker Galactic is a personal almanac.
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
