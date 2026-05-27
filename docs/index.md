---
title: Galactic
description: Your space-weather and RF brief — wherever you set up the rig.
layout: default
---

<div class="hero">
  <span class="tag">iOS · watchOS · widgets</span>

# Galactic

  <p class="lead">
    A daily almanac for <strong>amateur radio operators</strong>,
    <strong>space-weather watchers</strong>, and anyone who keeps an
    antenna outside. Pull a single brief and see what the sun, the
    geomagnetic field, the ionosphere, the local weather, and your
    friends on the air are all doing right now — for wherever you are.
  </p>

  <div class="cta-row">
    <a href="#features">See what's inside</a>
    <a class="alt" href="mailto:support@river.io?subject=TestFlight%20invite%20—%20Galactic">Request a TestFlight invite</a>
  </div>

  <div class="pills">
    <span>No backend</span>
    <span>No accounts</span>
    <span>No analytics</span>
    <span>On-device</span>
    <span>iOS 17+</span>
  </div>
</div>

---

## The brief

> Built on the road, tested in the field. Galactic runs **entirely
> on-device** and talks directly to NOAA SWPC, NWS, aprs.fi, POTA,
> SOTA, and the DX cluster as a polite public-API client. No
> Galactic server stands between you and the data.

<a id="features"></a>

## For radio operators

<div class="cards">
  <div class="card">
    <div class="glyph">∿</div>
    <h3>HF propagation summary</h3>
    <p>Live planetary Kp, A index, 10.7 cm solar flux (SFI), plus a
    plain-English read on band conditions and noise floor — straight
    from NOAA SWPC, refreshed when you tap.</p>
  </div>
  <div class="card">
    <div class="glyph">◌</div>
    <h3>Aurora-likelihood flag</h3>
    <p>Kp-driven heads-up when the auroral oval is pushing south and
    HF is about to go interesting (or sideways).</p>
  </div>
  <div class="card">
    <div class="glyph">◰</div>
    <h3>DX cluster</h3>
    <p>Recent DX spots so you can see what's audible right now —
    without firing up a separate client.</p>
  </div>
  <div class="card">
    <div class="glyph">⛰</div>
    <h3>POTA &amp; SOTA</h3>
    <p>Live Parks On The Air and Summits On The Air spots, sorted by
    distance. Tap a row for the detail page — distance, bearing from
    your QTH, frequency, mode, comments, and a map pin where the
    spot carries coordinates.</p>
  </div>
  <div class="card">
    <div class="glyph">⌖</div>
    <h3>Magnetic declination</h3>
    <p>Computed on-device against the World Magnetic Model. For beam
    headings, portable directional antennas, and azimuth math.</p>
  </div>
  <div class="card">
    <div class="glyph">◉</div>
    <h3>APRS callsign tracking</h3>
    <p>Save your friends' callsigns. One tap pulls their last-known
    APRS position from aprs.fi (your read key, your account), with an
    APRS-symbol icon and path-derived DX stats.</p>
  </div>
</div>

## Space weather, sun, and sky

- **Sunrise, sunset, golden hour**, and all three twilight transitions
  (civil, nautical, astronomical) — shown as a 24-hour color strip so
  your operating window reads at a glance.
- **Moon phase**, illumination, and surface features rendered on a
  starfield (Mare Imbrium, Mare Tranquillitatis, Tycho, the rest of
  the near-side face).
- **Ten planetary positions** (Sun, Moon, Mercury through Pluto) in
  zodiac signs at their current degree — Meeus's formulas, computed
  locally.
- **Upcoming launches.** Next five orbital launches from The Space
  Devs, with provider, pad, and status.

## Weather, for the rest of the kit

- **Earth weather** — six-period NWS forecast for your coordinates.
- **Marine forecasts** — NWS coastal-zone text bulletins (GMZ, AMZ,
  PZZ, AN, …) parsed as readable periods with seas, wind, and weather.

## Where the brief lives

- **Home-screen widget** in small and medium sizes — current
  temperature, sun events, Kp, moon phase, at a glance.
- **Apple Watch app** with five glance cards and **four complication
  families** (circular, corner, inline, rectangular) so the brief is
  always on your wrist during field ops.
- **Local notifications** for golden hour and astronomical dusk,
  scheduled fourteen days ahead.

## Why on-device

Galactic was written for a 2025 Coachmen Remote pulled across the
Southwest by a 4Runner. Cell coverage at a POTA park or a campground
picnic table is what it is, so the app is built to:

- Cache the last brief and surface an **offline banner** when the
  network round-trip fails, while sun/moon/planet math (which runs
  locally) keeps working.
- Talk directly to public services — there's nothing for us to take
  down because we don't run a server.
- Use only **system frameworks** — no third-party SDKs, no telemetry,
  no ad identifiers, no crash reporters.
- Treat your **aprs.fi API key as yours** — stored in `UserDefaults`
  on this device only, never transmitted anywhere except aprs.fi
  itself.

Full privacy notes: **[Privacy](./privacy)** · Operating notes and
FAQ: **[Support](./support)**

## Pricing

**Free at launch.** No in-app purchases, no subscriptions.

## System requirements

- iPhone running **iOS 17 or later**
- Apple Watch with **watchOS 10 or later** *(optional)*
- An **aprs.fi read API key** *(free, register at [aprs.fi](https://aprs.fi/))* if you want callsign position lookups — the rest of the app works without one

## Contact &amp; feedback

- Bug reports and feature requests:
  **[GitHub Issues](https://github.com/SpaceTrucker2196/StatusGalactic-iOS/issues)**
- General questions:
  **[support@river.io](mailto:support@river.io)** — replies within a
  few business days

<div class="cta-row">
  <a class="alt" href="mailto:support@river.io?subject=TestFlight%20invite%20—%20Galactic">Get on the TestFlight list</a>
  <a href="https://github.com/SpaceTrucker2196/StatusGalactic-iOS">Read the source</a>
</div>

---

*Galactic is not affiliated with the National Weather Service, NOAA,
aprs.fi, POTA, SOTA, The Space Devs, or the DX cluster network. It
consumes their public services as a polite client.*

**73 — de SpaceTrucker**
