---
title: Spacetrucker Galactic — iOS
layout: default
---

# Spacetrucker Galactic

*Your space weather and RF brief, wherever you set up the rig.*

A native iOS app for **amateur radio operators**, **space-weather watchers**,
and anyone who keeps an antenna outside. Pull a single brief and see what
the sun, the geomagnetic field, the ionosphere, the local weather, and
your friends on the air are all doing right now — for wherever you are.

> Built on the road, tested in the field. No backend, no accounts, no
> sign-in. Spacetrucker Galactic runs **entirely on-device** and talks
> directly to NOAA SWPC, NWS, aprs.fi, POTA, SOTA, and the DX cluster
> as a polite public-API client.

[Download on the App Store →](#) (TestFlight invite available — email
[support@river.io](mailto:support@river.io))

---

## What's in the brief

### For radio operators

- **HF propagation summary.** Live planetary Kp, A index, 10.7 cm
  solar flux (SFI), and a plain-English read on band conditions and
  noise floor — straight from NOAA SWPC, refreshed when you tap.
- **Aurora-likelihood flag.** Kp-driven heads-up when the auroral oval
  is pushing south and HF is about to go interesting (or sideways).
- **DX cluster.** Recent DX spots so you can see what's audible right
  now without firing up a separate client.
- **Parks On The Air (POTA).** Live spot list — who's activating
  what, on what band.
- **Summits On The Air (SOTA).** Same, for the summit crowd.
- **Magnetic declination** at your location, computed on-device — for
  beam headings, portable directional antennas, and azimuth math.
- **APRS callsign tracking.** Save your friends' callsigns. One tap
  pulls their last-known APRS position from aprs.fi (your read key,
  your account), with an APRS-symbol icon and path-derived DX stats.
- **APRS messaging surface.** Read recent APRS bulletins and
  conversations from your callsign's network neighborhood.

### Space weather, sun, and sky

- **Sunrise, sunset, golden hour**, and all three twilight transitions
  (civil, nautical, astronomical) — shown as a 24-hour color strip so
  you can see your operating window at a glance.
- **Moon phase**, illumination, and the right SF Symbol glyph.
- **Ten planetary positions** (Sun, Moon, Mercury through Pluto) in
  zodiac signs at their current degree — Meeus formulas, computed
  locally.
- **Upcoming launches.** Next five orbital launches from The Space
  Devs, with provider, pad, and status.

### Weather, for the rest of the kit

- **Earth weather** — six-period NWS forecast for your coordinates.
- **Marine forecasts** — NWS coastal-zone text bulletins (GMZ, AMZ,
  PZZ, AN, …) parsed as readable periods with seas, wind, and weather.

### Where the brief lives

- **Home-screen widget** in small and medium sizes — current
  temperature, sun events, Kp, moon phase, at a glance.
- **Apple Watch app** with five glance cards and **four complication
  families** (circular, corner, inline, rectangular) so the brief is
  always on your wrist during field ops.
- **Local notifications** for golden hour and astronomical dusk,
  scheduled fourteen days ahead. Useful for antenna work that should
  not happen in the dark.

---

## Why on-device

Spacetrucker Galactic was written for a 2025 Coachmen Remote pulled
across the Southwest by a 4Runner. Cell coverage at a POTA park or a
campground picnic table is what it is, so the app is built to:

- Cache the last brief and surface an **offline banner** when the
  network round-trip fails, while sun/moon/planet math (which runs
  locally) keeps working.
- Talk directly to public services — **no Spacetrucker Galactic
  server stands between you and NOAA SWPC**, so there's nothing for us
  to take down.
- Use only **system frameworks** — no third-party SDKs, no telemetry,
  no ad identifiers, no crash reporters.
- Treat your **aprs.fi API key as yours** — stored in `UserDefaults`
  on this device only, never transmitted anywhere except aprs.fi
  itself.

Full privacy details: **[Privacy](./privacy)** · Operating notes and
FAQ: **[Support](./support)**

---

## Pricing

**Free at launch.** No in-app purchases, no subscriptions.

## System requirements

- iPhone running **iOS 17 or later**
- Apple Watch with **watchOS 10 or later** (optional, for the watch
  app and complications)
- An **aprs.fi read API key** (free, register at
  [aprs.fi](https://aprs.fi/)) if you want callsign position lookups —
  the rest of the app works without one

## Contact and feedback

- Bug reports and feature requests:
  **[GitHub Issues](https://github.com/SpaceTrucker2196/StatusGalactic-iOS/issues)**
- General questions:
  **[support@river.io](mailto:support@river.io)** — replies within a
  few business days

---

*Spacetrucker Galactic is not affiliated with the National Weather
Service, NOAA, aprs.fi, POTA, SOTA, The Space Devs, or the DX cluster
network. It consumes their public services as a polite client.*

73 — de SpaceTrucker
