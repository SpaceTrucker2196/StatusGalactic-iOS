---
title: Privacy (Android)
layout: default
---

# Status Galactic (Android) — Privacy Policy

_Last updated: 2026-07-12_

Status Galactic is a thin, on-device Android app. It talks to public weather, space-weather, and astronomy services directly. It has **no backend server, no analytics SDK, and no user account**. This document is the source of truth for the Google Play Data Safety form and the in-app disclosure — update it if any statement stops being true.

## Plain-English summary

- **No tracking.** No SDKs that track you across apps or websites. No advertising ID is read.
- **No analytics or crash reporting.** No Firebase, Crashlytics, Sentry — nothing.
- **No data goes to us.** Status Galactic operates no servers and has no telemetry.
- **No accounts.** No sign-in.
- **No purchases.** No billing, no in-app purchases.
- **No third-party SDKs.** Only Google/AndroidX (Jetpack) libraries and Google Play Services Location are linked; no ad, analytics, or tracking SDKs.

## What the app sends out

Every outbound request goes to a single public service, on your behalf:

| Destination | What is sent | Why |
|-------------|--------------|-----|
| `api.weather.gov` | Your latitude/longitude (rounded to ~4 decimals) | NWS forecast for your area |
| `tgftp.nws.noaa.gov` | A marine zone ID (e.g. `GMZ033`), only if you set one | NWS marine bulletin |
| `services.swpc.noaa.gov` | Nothing identifying — a generic GET | Space weather, aurora oval, D-RAP, SUVI imagery |
| `sdo.gsfc.nasa.gov` | Nothing identifying — a generic GET | Live sun imagery |
| `ll.thespacedevs.com`, `api.pota.app`, SOTA/DX/USGS/NOAA feeds | Nothing identifying — generic GETs | Launches, POTA/SOTA/DX spots, earthquakes, river gauges, etc. |
| `api.nasa.gov` | The NASA API key you optionally enter | APOD / NEO / DONKI |
| `api.aprs.fi` | A callsign you added + your aprs.fi API key | Ham radio position lookup |
| `www.repeaterbook.com` | Your city/state + your RepeaterBook token | Nearby repeaters |

Your User-Agent (which NWS requires) is included on every request. It identifies the app and version.

## What the app stores on your device

All app data lives in the app's private storage (Jetpack DataStore / app files) and never leaves the device except as described above.

| Data | Purpose | How to delete |
|------|---------|---------------|
| Saved callsigns | Quick selection in the Callsigns tab | Remove in the app, or uninstall |
| aprs.fi / NASA / RepeaterBook keys | Optional API access you opt into | Clear in Settings, or uninstall |
| Default marine zone, aurora/storm thresholds | Convenience | Clear in Settings, or uninstall |
| Notification toggles + scheduled times | Local reminders (golden hour, dusk, storms) | Turn off in Settings, or uninstall |
| Last brief snapshot | Powers the home-screen widget without a re-fetch | Uninstall |

## Permissions

- **Location (fine/coarse), when-in-use only** — used for one-shot fixes when you open or refresh the app, to fetch a brief for where you are. No background location.
- **Notifications** — to fire the local reminders you enable.
- **Internet / network state** — to fetch the public data above.

The app does **not** access Contacts, Calendar, Photos, Microphone, Camera, or health/motion data, and does not request background location.

## Children's privacy

The app has no functionality intended for children and no user-generated content.

## Contact

Questions: jeff@river.io
