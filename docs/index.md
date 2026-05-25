---
title: Spacetrucker Galactic — iOS
layout: default
---

# Spacetrucker Galactic (iOS)

*The sky and the road, briefed.*

A daily almanac for travelers, photographers, sailors, and ham operators.
Earth weather, marine forecasts, space weather, sunrise through
astronomical dusk, moon phase, ten planetary positions, and upcoming
launches — in one quiet view, tuned to where you are.

> As of v0.2, Spacetrucker Galactic runs **entirely on your device**.
> Every data source is fetched directly from its public origin
> (NWS, NOAA SWPC, NWS marine bulletins, aprs.fi, The Space Devs), and
> all astronomy math (sun events, moon phase, planet positions) is
> computed locally. There is no Spacetrucker Galactic server.

---

## What's in the brief

- **Earth weather** — six-period NWS forecast for your coordinates.
- **Marine forecasts** — NWS coastal-zone bulletins (GMZ, AMZ, PZZ, AN,
  …), parsed as readable periods with seas, wind, and weather.
- **Space weather** — planetary Kp index and 10.7 cm solar flux from
  NOAA SWPC, plus an HF propagation summary and an aurora-likelihood
  flag.
- **Sun** — sunrise, sunset, golden hour, and the three twilight
  transitions (civil, nautical, astronomical) on a 24-hour color strip.
- **Moon** — phase, illumination percentage, and the right SF Symbol.
- **Planets** — ten bodies (Sun, Moon, Mercury through Pluto) in zodiac
  signs at their current degree, from Meeus's formulas on-device.
- **Launches** — the next five orbital launches from The Space Devs
  Launch Library, with provider, pad, and status.
- **Callsigns (APRS)** — add ham radio callsigns and load a brief at
  their last-known position via aprs.fi (your key, your account).

## How it fits the day

- **Local notifications** for golden hour and astronomical dusk,
  scheduled fourteen days ahead.
- **Home-screen widget** in small and medium sizes with the headline
  brief.
- **Apple Watch app** with five glance cards and four complication
  families.
- **Open in Maps** to navigate to a callsign's coordinates.

## How Spacetrucker Galactic treats your data

Spacetrucker Galactic is a **strictly-local, single-device app**.

- No backend. No accounts. No sign-in.
- No third-party SDKs — no analytics, no crash reporters, no ads, no
  trackers.
- No data is ever transmitted to a Spacetrucker Galactic server
  because there isn't one.
- Outbound requests go only to the public services that produce the
  data (NWS, SWPC, aprs.fi, The Space Devs). Your User-Agent is
  configurable in Settings.

Full details: **[Privacy](./privacy)** · **[Support](./support)**

## Pricing

Free at launch.

## Contact

Email **[support@river.io](mailto:support@river.io)** — we respond
within a few business days. Bugs and feature requests can also go on
**[GitHub Issues](https://github.com/SpaceTrucker2196/StatusGalactic-iOS/issues)**.

---

*This page is the marketing / support landing for App Store review and
TestFlight invitees. Spacetrucker Galactic is not affiliated with the
National Weather Service, NOAA, aprs.fi, or The Space Devs; it consumes
their public services as a client.*
