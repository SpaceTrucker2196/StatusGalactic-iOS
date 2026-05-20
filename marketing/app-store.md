# Status Galactic — App Store Metadata

Drop-in copy for the App Store Connect listing.

---

## Name (30 char max)

**Status Galactic**

## Subtitle (30 char max)

**The sky and the road, briefed.**

## Promotional Text (170 char max, can be updated without resubmission)

Earth weather, marine forecasts, space weather, sunrise to astronomical dusk, moon phase, planetary positions, and live launches. One brief, your location.

## Category

Primary: **Weather**
Secondary: **Travel**

## Keywords (100 char comma-separated)

```
weather,marine,nws,aprs,space weather,sunrise,sunset,twilight,moon,planets,kp,launches,almanac,ham
```

---

## Description (4000 char max)

**One brief. Everything above and below the horizon.**

Status Galactic is a daily almanac for travelers, photographers, and anyone who likes to know what the sky is doing. It pulls together the forecasts and ephemerides that normally live in eight separate tabs, and gives them to you in one quiet view, tuned to where you are.

**Earth weather.** Pulled straight from the National Weather Service's forecast grid for your coordinates. Six periods, temperature, wind, conditions.

**Marine forecasts.** For coastal users and sailors: the NWS coastal-zone bulletins (GMZ, AMZ, PZZ, AN, and others), parsed and presented as readable periods with seas, wind, and weather.

**Space weather.** Planetary Kp index and 10.7 cm solar flux from NOAA SWPC. Includes an HF propagation summary and an aurora-likelihood flag.

**Sun.** Sunrise, sunset, golden-hour windows, and the three twilight transitions (civil, nautical, astronomical), shown as a colored 24-hour strip and individual times in your local zone.

**Moon.** Phase, illumination percentage, and the right SF Symbol glyph.

**Planetary positions.** Ten bodies (Sun, Moon, Mercury through Pluto) in zodiac signs at their current degree, computed from Meeus's formulas right on your device.

**Upcoming launches.** Next five orbital launches from The Space Devs Launch Library, with provider, pad, and status.

**APRS-friendly.** Add your friends' ham radio callsigns and load a brief at their last-known position. Lookup uses the aprs.fi read API (your key, your account).

**Designed to disappear into the day.**

- **Local notifications** for golden hour and astronomical dusk, scheduled fourteen days ahead.
- **Home-screen widget** in small and medium sizes with the headline brief.
- **Watch app and complications** for the four accessory families on Apple Watch.
- **Open in Maps** for navigation to a callsign's coordinates.
- **No tracking, no analytics, no accounts.** The app talks directly to public weather and APRS services. Nothing is sent to a Status Galactic server because there isn't one.

**Built for the road.**

Originally written for a 2025 Coachmen Remote pulled by a 4Runner across the Southwest. Designed to be useful on a campground picnic table at dusk, in a marina at dawn, and from a watch face on the trail.

---

## What's New in this Version (4000 char)

### v0.2 — Standalone

- Status Galactic now runs entirely on your device. Every data source is fetched directly from its public origin; nothing is routed through a Status Galactic server.
- All astronomy math (sun, moon, planets, twilight) computed locally with Meeus and NOAA formulas. No ephemeris file required.
- New Apple Watch app with five glance cards and four complication families.
- Apple Maps deep linking: drop a pin or get driving directions from a callsign's last-known position.
- Accessibility: the Sun day strip now reads sunrise, sunset, and the current twilight phase to VoiceOver.
- Haptic feedback on refresh, success and error.
- Clearer error messaging when the aprs.fi API key is missing.

---

## Privacy

See `marketing/privacy.md`.

---

## Support URL

Recommend a GitHub Issues link:

```
https://github.com/SpaceTrucker2196/StatusGalactic-iOS/issues
```

## Marketing URL

The repo URL works:

```
https://github.com/SpaceTrucker2196/StatusGalactic-iOS
```

## Copyright

`© 2026 Jeff`

---

## Age Rating

- **4+** — no objectionable content
- No tracking, no user-generated content, no purchases.

## Sign-in Required

No.

## App Tracking Transparency

Not required — the app does not perform tracking as defined by Apple's framework.
