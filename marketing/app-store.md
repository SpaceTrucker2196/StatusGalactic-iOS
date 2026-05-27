# Galactic — App Store Metadata

Drop-in copy for the App Store Connect listing. Lines are length-tuned
to Apple's enforced limits.

---

## Name (30 char max)

**Galactic**

## Subtitle (30 char max)

**Space weather. RF. The brief.**

## Promotional Text (170 char max — can be updated without resubmission)

Live Kp, SFI, aurora flag, POTA & SOTA spots, DX cluster, magnetic declination, APRS — plus sun, moon, marine, and weather. One brief, your location. On-device.

### Alternates (170 char) for A/B copy

- Your space-weather and RF brief, wherever you set up the rig. Live propagation, POTA & SOTA, APRS callsigns, sun events, marine, moon. No backend.
- Built for radio operators. HF propagation, aurora warning, POTA, SOTA, DX cluster, declination, APRS. All on-device — no accounts, no analytics, no servers.

## Category

Primary: **Weather**
Secondary: **Reference**

## Keywords (100 chars total, comma-separated)

```
aprs,ham,radio,propagation,space weather,kp,sfi,pota,sota,dx,nws,marine,sun,moon,almanac
```

(Exactly 99 chars including commas.)

---

## Description (4000 char max)

**Your space-weather and RF brief, wherever you set up the rig.**

Galactic is a daily almanac for amateur radio operators, space-weather
watchers, and anyone who keeps an antenna outside. It pulls the
forecasts and ephemerides that normally live in eight separate tabs
into one quiet view, tuned to your location.

**For radio operators:**

· HF propagation summary. Live planetary Kp, A index, and 10.7 cm
solar flux (SFI) from NOAA SWPC, plus a plain-English read on band
conditions and noise floor.

· Aurora-likelihood flag. Kp-driven heads-up when the auroral oval is
pushing south and HF is about to get interesting.

· DX cluster. Recent DX spots so you can see what's audible without
firing up a separate client.

· Parks On The Air & Summits On The Air. Live spots sorted by
distance. Tap a row for the detail page — distance, bearing from your
QTH, frequency, mode, and a map pin where the spot carries
coordinates.

· Magnetic declination at your location, computed on-device against
the World Magnetic Model — for beam headings, portable directional
antennas, and azimuth math.

· APRS callsign tracking. Save your friends' callsigns; one tap pulls
their last-known APRS position from aprs.fi (your read key, your
account), with an APRS-symbol icon and path-derived DX stats.

**Space weather, sun, and sky:**

· Sunrise, sunset, golden-hour windows, and the three twilight
transitions (civil, nautical, astronomical) on a 24-hour color strip.

· Moon phase, illumination percentage, and surface features rendered
on a starfield — Mare Imbrium, Mare Tranquillitatis, Tycho, the rest
of the near-side face.

· Ten planetary positions (Sun, Moon, Mercury through Pluto) in
zodiac signs at their current degree, computed locally with Meeus's
formulas.

· Upcoming launches. Next five orbital launches from The Space Devs.

**Weather, for the rest of the kit:**

· Earth weather. Six-period NWS forecast for your coordinates.

· Marine forecasts. NWS coastal-zone bulletins (GMZ, AMZ, PZZ, AN, …)
parsed as readable periods with seas, wind, and weather.

**Where the brief lives:**

· Home-screen widget — small and medium sizes with current
temperature, sun events, Kp, and moon phase at a glance.

· Apple Watch app with five glance cards and four complication
families (circular, corner, inline, rectangular).

· Local notifications for golden hour and astronomical dusk,
scheduled fourteen days ahead.

**Built for the field:**

Galactic runs entirely on your device. No backend, no accounts, no
analytics, no third-party SDKs. Outbound requests go only to NOAA,
NWS, aprs.fi, The Space Devs, POTA, SOTA, and the DX cluster — the
public services that produce the data. Your aprs.fi API key is yours,
stored in iOS UserDefaults on this device only.

73 — de SpaceTrucker.

---

## What's New in this Version (4000 char max)

### v0.2 — Standalone

· Galactic now runs entirely on your device. Every data source is
fetched directly from its public origin; nothing is routed through a
Galactic server.

· Brand-new RF tab leading with the radio-operator story: HF
propagation, aurora flag, POTA, SOTA, DX cluster, magnetic
declination, APRS callsign tracking and receive-only messaging.

· POTA & SOTA detail pages — distance, bearing from your QTH,
frequency, mode, comments, and a map pin where coordinates are
available.

· Moon surface features rendered on the moon hero — Mare Imbrium,
Tranquillitatis, Procellarum, Tycho, and the rest of the near-side
face.

· Apple Watch app with five glance cards and four complication
families.

· Apple Maps deep linking from any callsign's last-known position.

· Local notifications for golden hour and astronomical dusk,
scheduled fourteen days ahead.

· Accessibility: the Sun day strip reads sunrise, sunset, and the
current twilight phase to VoiceOver. Every tab's interactive surface
now has stable identifiers and labels.

· Haptic feedback on refresh, success, and error.

· Offline banner when the network round-trip fails — sun, moon,
planet, and declination math keep working.

---

## Privacy

See `marketing/privacy.md` (and the live policy at
[spacetrucker2196.github.io/StatusGalactic-iOS/privacy](https://spacetrucker2196.github.io/StatusGalactic-iOS/privacy)).

---

## Marketing URL

```
https://spacetrucker2196.github.io/StatusGalactic-iOS/
```

## Support URL

```
https://spacetrucker2196.github.io/StatusGalactic-iOS/support
```

## Privacy Policy URL

```
https://spacetrucker2196.github.io/StatusGalactic-iOS/privacy
```

## Copyright

`© 2026 Jeff`

---

## Age Rating

- **4+** — no objectionable content
- No tracking, no user-generated content, no purchases

## Sign-in Required

No.

## App Tracking Transparency

Not required — the app does not perform tracking as defined by Apple's
framework.

---

## Promotional artwork notes

Screenshots live in `marketing/screenshots/`:

- `iphone-6.9/` — 1284 × 2778, twelve shots (RF hero, aurora/Kp, POTA
  & SOTA, DX cluster, callsigns list, callsign detail, Brief hero,
  sun & twilight, launches, marine, widget, settings)
- `iphone-6.1/` — 1242 × 2688, same set

Both are gitignored; regenerate via `scripts/screenshots.sh`.
