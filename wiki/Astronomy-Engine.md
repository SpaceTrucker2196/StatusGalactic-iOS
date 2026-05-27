# Astronomy Engine

Galactic computes sun, moon, and planetary positions entirely on-device using classical astronomical algorithms. This page documents the implementation, accuracy, and validation methodology.

---

## Table of Contents

- [Why On-Device?](#why-on-device)
- [Source Files](#source-files)
- [Julian Date (`JulianDate.swift`)](#julian-date-juliandateswift)
- [Sun Events (`SunEvents.swift`)](#sun-events-suneventsswift)
- [Moon Phase (`MoonPhase.swift`)](#moon-phase-moonphaseswift)
- [Planetary Positions (`Planets.swift`)](#planetary-positions-planetsswift)
- [Sidereal Clock (`SiderealClock.swift`)](#sidereal-clock-siderealclockswift)
- [Accuracy & Validation](#accuracy--validation)
- [Design Decisions](#design-decisions)

---

## Why On-Device?

1. **Offline operation.** An operator in a canyon with no cell coverage still gets sunrise/sunset, moon phase, and planet positions.
2. **No API dependency.** Astronomy never fails because a server is down.
3. **Instant computation.** Sub-millisecond results — no network latency.
4. **Privacy.** Your coordinates never leave the device for this computation.

---

## Source Files

```
StatusGalactic/Services/Astronomy/
├── JulianDate.swift      # Calendar ↔ Julian Date conversion
├── SunEvents.swift       # Sunrise, sunset, twilight, golden hour
├── MoonPhase.swift       # Lunar phase, illumination, ecliptic longitude
├── Planets.swift         # 10-body ecliptic longitude in zodiac signs
└── SiderealClock.swift   # Greenwich Mean Sidereal Time + local offset
```

---

## Julian Date (`JulianDate.swift`)

The foundation for all astronomical computation. Converts between calendar dates and Julian Day Numbers — a continuous count of days since January 1, 4713 BC.

**Key functions:**
- `fromDate(_ date: Date) -> Double` — Swift `Date` → JD
- `centuriesSinceJ2000(_ jd: Double) -> Double` — fractional centuries since J2000.0 (2000 Jan 1.5 TT)

The J2000.0 epoch (JD 2451545.0) is the reference point for all modern orbital element tables.

---

## Sun Events (`SunEvents.swift`)

Implements the **NOAA solar position approximation** — a simplified algorithm derived from Jean Meeus's *Astronomical Algorithms* that the US Naval Observatory and NOAA use for their online calculators.

### What it computes:

| Event | Zenith Angle | Description |
|-------|:---:|-------------|
| Sunrise / Sunset | 90.833° | Upper limb touches horizon (includes refraction) |
| Civil twilight start/end | 96° | Enough light for outdoor activities without artificial light |
| Nautical twilight start/end | 102° | Horizon visible at sea; bright stars visible |
| Astronomical twilight start/end | 108° | Sky fully dark; faintest stars visible |
| Golden hour start | ~86° (sunset - 30 min) | Warm, low-angle light for photography |

### Algorithm outline:

1. Compute Julian Day Number and fractional century from J2000.0
2. Calculate solar geometric mean longitude and mean anomaly
3. Apply equation of center (5 terms) to get true longitude
4. Convert to right ascension
5. Calculate solar declination
6. Compute hour angle for the desired zenith angle
7. Combine with longitude and equation of time to get UTC event time
8. Convert to local time using the provided timezone

### Accuracy:

- **±1 minute** for sunrise/sunset below 60° latitude
- **±2 minutes** for twilight transitions at mid-latitudes
- Degrades at extreme latitudes (polar regions) where the sun barely crosses the horizon

---

## Moon Phase (`MoonPhase.swift`)

Implements **Jean Meeus's chapter 47** algorithm using the major periodic terms for lunar ecliptic longitude and latitude.

### What it computes:

- **Ecliptic longitude** of the Moon (degrees)
- **Phase angle** (elongation from the Sun)
- **Illumination fraction** (0.0 to 1.0)
- **Named phase** (New, Waxing Crescent, First Quarter, Waxing Gibbous, Full, Waning Gibbous, Last Quarter, Waning Crescent)
- **Age** in days (0–29.53)

### Algorithm outline:

1. Compute centuries since J2000.0
2. Calculate mean longitude (L'), mean anomaly of Moon (M'), mean anomaly of Sun (M), and argument of latitude (F)
3. Sum the largest periodic correction terms (≈6 terms from Meeus Table 47.A) to get true longitude
4. Compute Sun's ecliptic longitude
5. Phase angle = Moon longitude - Sun longitude (normalized to 0–360°)
6. Illumination = (1 - cos(phase_angle)) / 2

### Named phase determination:

| Phase Angle Range | Name |
|:-:|---|
| 0° – 22.5° | New Moon |
| 22.5° – 67.5° | Waxing Crescent |
| 67.5° – 112.5° | First Quarter |
| 112.5° – 157.5° | Waxing Gibbous |
| 157.5° – 202.5° | Full Moon |
| 202.5° – 247.5° | Waning Gibbous |
| 247.5° – 292.5° | Last Quarter |
| 292.5° – 337.5° | Waning Crescent |
| 337.5° – 360° | New Moon |

### Accuracy:

- Ecliptic longitude: **< 0.5°**
- Illumination: **< 3%** compared to JPL ephemeris
- Named phase: always correct (boundaries are generous)

---

## Planetary Positions (`Planets.swift`)

Computes ecliptic longitude for **10 bodies** (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto) using **mean orbital elements** with an **equation of center** correction.

### What it returns:

For each body:
- Ecliptic longitude in degrees (0–360°)
- Zodiac sign (Aries through Pisces, 30° per sign)
- Degree within the sign (0°–29°)

### Algorithm outline (for each planet):

1. Look up mean orbital elements at epoch J2000.0:
   - Mean longitude (L₀)
   - Semi-major axis (a)
   - Eccentricity (e)
   - Inclination (i)
   - Longitude of ascending node (Ω)
   - Longitude of perihelion (ω̃)
2. Compute mean anomaly: M = L₀ + rate × T - ω̃
3. Apply equation of center: ν ≈ M + (2e - e³/4) sin M + (5e²/4) sin 2M + (13e³/12) sin 3M
4. Heliocentric longitude = ν + ω̃
5. For outer planets: convert heliocentric → geocentric (add Earth's position)
6. Map longitude to zodiac sign

### Accuracy:

- **~1-3°** for most planets — sufficient for zodiac sign assignment
- May be off near sign boundaries (e.g., reporting "29° Aries" when the true position is "1° Taurus")
- **Intentionally simplified** — the app avoids VSOP87 complexity to stay dependency-free

### Why not a full ephemeris?

A full planetary ephemeris (VSOP87 or JPL DE series) would require either:
- A large lookup table (several MB of coefficients), or
- A third-party astronomy library

Neither fits the app's "pure Swift, no dependencies, small binary" philosophy. The simplified approach is accurate enough for casual zodiac-sign display and will only disagree with a full ephemeris near sign boundaries.

---

## Sidereal Clock (`SiderealClock.swift`)

Computes **Local Sidereal Time (LST)** — the right ascension currently on the meridian at your location. Used for constellation visibility and observational planning.

### Algorithm:

1. Compute Julian Date for the current moment
2. Calculate Greenwich Mean Sidereal Time (GMST) from J2000.0 centuries
3. Add observer's longitude (east positive) to get Local Sidereal Time
4. Normalize to 0–24 hours

### Accuracy: < 1 second

---

## Accuracy & Validation

All astronomy routines are validated against the legacy `weathergalactic` backend which uses **Skyfield + JPL DE421** — a professional-grade ephemeris.

| Quantity | Galactic (on-device) | Reference (Skyfield/DE421) | Maximum Error |
|----------|---------------------|---------------------------|:---:|
| Sunrise | NOAA approximation | USNO validated | ±1 min |
| Sunset | NOAA approximation | USNO validated | ±1 min |
| Civil twilight | Same + zenith=96° | USNO | ±2 min |
| Nautical twilight | Same + zenith=102° | USNO | ±2 min |
| Astronomical twilight | Same + zenith=108° | USNO | ±2 min |
| Sun ecliptic longitude | Meeus 25 | Skyfield | < 0.01° |
| Moon ecliptic longitude | Meeus 47 | Skyfield | < 0.5° |
| Moon illumination | Derived | Skyfield | < 3% |
| Planet sign assignment | Mean elements | Skyfield | Correct except near boundaries |
| Planet degree | Mean elements + EoC | Skyfield | ±1-3° |

Full audit data is in `parity/audits/2026-05-19-standalone-iOS.md`.

---

## Design Decisions

1. **No external astronomy library.** Keeps the binary small, avoids dependency rot, and ensures the app compiles with zero package fetches.

2. **Meeus as primary reference.** Jean Meeus's *Astronomical Algorithms* (2nd edition) is the de facto standard for compact, accurate astronomical computation. The NOAA and USNO solar calculators are based on the same formulas.

3. **Accuracy vs. complexity trade-off.** For planetary positions, ~2° accuracy is acceptable for zodiac-sign display. Users who need arc-second precision are using Stellarium, not a phone app.

4. **Julian Date as the internal time scale.** All computations use JD/centuries-from-J2000.0 internally, converting to/from Swift `Date` only at the boundaries.

5. **Pure functions.** All astronomy computations are pure (no side effects, no state). Input: coordinates + time. Output: events or positions. This makes them trivially testable and thread-safe.
