# Data Sources

Galactic contacts the following public APIs directly from the device. There is no intermediary backend. Each source is independently fetched, independently cached, and independently error-handled.

---

## Table of Contents

- [Weather & Earth](#weather--earth)
- [Space Weather & Solar](#space-weather--solar)
- [Amateur Radio](#amateur-radio)
- [Astronomy & Space](#astronomy--space)
- [On-Device Computation](#on-device-computation)

---

## Weather & Earth

### National Weather Service (api.weather.gov)

| Field | Value |
|-------|-------|
| **Base URL** | `https://api.weather.gov` |
| **Authentication** | User-Agent header only (NWS policy) |
| **Client** | `NWSClient.swift` |
| **Returns** | `EarthWeather` — six-period forecast, current conditions |
| **Endpoint flow** | `GET /points/{lat},{lng}` → resolves grid office → `GET /gridpoints/{office}/{x},{y}/forecast` |

The NWS API requires a descriptive User-Agent string. Galactic sends: `StatusGalactic-iOS/0.2 (+https://github.com/SpaceTrucker2196/StatusGalactic-iOS)`

### Weather Alerts (api.weather.gov)

| Field | Value |
|-------|-------|
| **Client** | `WeatherAlertsClient.swift` |
| **Endpoint** | `GET /alerts/active?point={lat},{lng}` |
| **Returns** | `[WeatherAlert]` — active watches, warnings, advisories |

### NWS Marine Bulletins (tgftp.nws.noaa.gov)

| Field | Value |
|-------|-------|
| **Base URL** | `https://tgftp.nws.noaa.gov` |
| **Authentication** | None |
| **Client** | `MarineClient.swift` |
| **Returns** | `MarineWeather` — parsed text bulletin with forecast periods |
| **Format** | Raw NWS text bulletin, parsed client-side |
| **Zones** | GMZ (Gulf of Mexico), AMZ (Atlantic), PZZ (Pacific), AN (Arctic), etc. |

### NOAA Tides (tidesandcurrents.noaa.gov)

| Field | Value |
|-------|-------|
| **Client** | `TidesClient.swift` |
| **Returns** | `Tides` — upcoming high/low predictions for nearest station |
| **Station lookup** | Matched from `TideStationCatalog.swift` by proximity |

### USGS River Gauges (waterservices.usgs.gov)

| Field | Value |
|-------|-------|
| **Client** | `RiverGaugeClient.swift` |
| **Returns** | `RiverGauge` — stage, flow, flood status |
| **Station lookup** | Matched from `RiverGaugeCatalog.swift` by proximity |

### USGS Earthquakes (earthquake.usgs.gov)

| Field | Value |
|-------|-------|
| **Client** | `EarthquakeClient.swift` |
| **Returns** | `[Earthquake]` — recent significant events sorted by proximity |

---

## Space Weather & Solar

### NOAA SWPC (services.swpc.noaa.gov)

| Field | Value |
|-------|-------|
| **Base URL** | `https://services.swpc.noaa.gov` |
| **Authentication** | None |
| **Client** | `SWPCClient.swift` |
| **Returns** | `SpaceWeather` — Kp index, 10.7 cm solar flux, R/S/G storm scales |
| **Endpoints** | `/products/noaa-planetary-k-index.json`, `/products/solar-cycle/observed-solar-cycle-indices.json`, etc. |

### OVATION Aurora Model (services.swpc.noaa.gov)

| Field | Value |
|-------|-------|
| **Client** | `OVATIONClient.swift` |
| **Returns** | `AuroraForecast` — probability at your latitude + global peak |

### Active Regions (services.swpc.noaa.gov)

| Field | Value |
|-------|-------|
| **Client** | `ActiveRegionsClient.swift` |
| **Returns** | `[ActiveRegion]` — numbered sunspot regions with classifications |

### Space Weather Forecasts (services.swpc.noaa.gov)

| Field | Value |
|-------|-------|
| **Client** | `SpaceWeatherForecastClient.swift` |
| **Returns** | `[KpForecastDay]`, `FlareProbability` |

### Solar Wind (services.swpc.noaa.gov)

| Field | Value |
|-------|-------|
| **Client** | `SolarWindClient.swift` |
| **Returns** | `SolarWind` — speed, density, Bz, temperature |

### X-Ray & Proton Flux (services.swpc.noaa.gov)

| Field | Value |
|-------|-------|
| **Client** | `GOESParticleClient.swift` |
| **Returns** | `XRayState`, `ProtonState` — GOES satellite particle measurements |

### WWV Solar-Terrestrial Bulletin

| Field | Value |
|-------|-------|
| **Client** | `WWVClient.swift` |
| **Returns** | `WWVBulletin` — the text bulletin broadcast on WWV/WWVH |

### Solar Outlook (services.swpc.noaa.gov)

| Field | Value |
|-------|-------|
| **Client** | `SolarOutlookClient.swift` |
| **Returns** | `[SolarOutlookDay]` — multi-day solar activity outlook |

### Solar Cycle Data

| Field | Value |
|-------|-------|
| **Client** | `SolarCycleClient.swift` |
| **Returns** | `[SolarCyclePoint]` — monthly sunspot numbers for cycle plotting |

### NASA DONKI (CME Events)

| Field | Value |
|-------|-------|
| **Base URL** | `https://api.nasa.gov` |
| **Authentication** | NASA API key (free, configurable in Settings) |
| **Client** | `DONKIClient.swift` |
| **Returns** | `[CMEEvent]` — coronal mass ejection reports |

### Ionosondes

| Field | Value |
|-------|-------|
| **Client** | `IonosondeClient.swift` |
| **Returns** | `[IonosondeStation]` — live ionogram data (foF2, MUF, heights) |

---

## Amateur Radio

### aprs.fi (api.aprs.fi)

| Field | Value |
|-------|-------|
| **Base URL** | `https://api.aprs.fi` |
| **Authentication** | Read API key (free, register at aprs.fi) |
| **Client** | `APRSClient.swift` |
| **Returns** | Station last-known position, path, comment, symbol |
| **Endpoint** | `GET /api/get?name={CALL}&what=loc&apikey={KEY}&format=json` |

### APRS Messaging

| Field | Value |
|-------|-------|
| **Client** | `APRSMessaging.swift` |
| **Returns** | Message threads between stations |

### APRS DX Statistics

| Field | Value |
|-------|-------|
| **Client** | `APRSDXStats.swift` |
| **Returns** | Path-derived distance/direction stats |

### POTA (api.pota.app)

| Field | Value |
|-------|-------|
| **Base URL** | `https://api.pota.app` |
| **Authentication** | None |
| **Client** | `POTAClient.swift` |
| **Returns** | `[POTASpot]` — live Parks on the Air activations |

### SOTA (api2.sota.org.uk)

| Field | Value |
|-------|-------|
| **Base URL** | `https://api2.sota.org.uk` |
| **Authentication** | None |
| **Client** | `SOTAClient.swift` |
| **Returns** | `[SOTASpot]` — live Summits on the Air activations |

### DX Cluster (dxsummit.fi)

| Field | Value |
|-------|-------|
| **Base URL** | `https://www.dxsummit.fi` |
| **Authentication** | None |
| **Client** | `DXClusterClient.swift` |
| **Returns** | `[DXSpot]` — recent DX spots across bands |

### RepeaterBook

| Field | Value |
|-------|-------|
| **Client** | `RepeaterBookClient.swift` |
| **Returns** | `[Repeater]` — nearby amateur radio repeaters |

### Band Conditions

| Field | Value |
|-------|-------|
| **Client** | `BandConditions.swift` |
| **Returns** | `[BandCondition]` — derived HF band status from SWPC indices |

---

## Astronomy & Space

### The Space Devs (ll.thespacedevs.com)

| Field | Value |
|-------|-------|
| **Base URL** | `https://ll.thespacedevs.com/2.2.0` |
| **Authentication** | None |
| **Client** | `LaunchesClient.swift` |
| **Returns** | `[Launch]` — upcoming orbital launches |

### NASA APOD (api.nasa.gov)

| Field | Value |
|-------|-------|
| **Authentication** | NASA API key |
| **Client** | `APODClient.swift` |
| **Returns** | `APOD` — Astronomy Picture of the Day (image URL + explanation) |

### Mars Weather

| Field | Value |
|-------|-------|
| **Client** | `MarsWeatherClient.swift` |
| **Returns** | `MarsWeather` — surface temperature, pressure, wind |

### ISS Position & Passes

| Field | Value |
|-------|-------|
| **Client** | `ISSClient.swift` |
| **Returns** | `[CrewedObject]` — ISS position and pass predictions |

### NEO (Near-Earth Objects)

| Field | Value |
|-------|-------|
| **Authentication** | NASA API key |
| **Client** | `NEOClient.swift` |
| **Returns** | `[NearEarthObject]`, `[InterstellarObject]` |

### Constellations

| Field | Value |
|-------|-------|
| **Client** | `ConstellationsClient.swift` |
| **Returns** | `[ConstellationSummary]` — currently visible constellations |

### Magnetic Declination

| Field | Value |
|-------|-------|
| **Client** | `MagneticDeclinationClient.swift` |
| **Returns** | `MagneticDeclination` — WMM-based true/magnetic north offset |

---

## On-Device Computation

These require **no network access** and work offline:

| Computation | Source File | Algorithm | Accuracy |
|-------------|-------------|-----------|----------|
| Sunrise / Sunset | `SunEvents.swift` | NOAA solar position approximation | ~1 min below 60° lat |
| Civil / Nautical / Astronomical twilight | `SunEvents.swift` | Same, different zenith angles | ~1-2 min mid-latitude |
| Golden hour window | `SunEvents.swift` | Sunset ± 30 min | Approximate |
| Sun ecliptic longitude | `SunEvents.swift` | Meeus 25 + equation of center | < 0.01° |
| Moon ecliptic longitude & phase | `MoonPhase.swift` | Meeus 47 major periodic terms | < 0.5° |
| Moon illumination percentage | `MoonPhase.swift` | Derived from phase angle | ~1% |
| Planet positions (10 bodies) | `Planets.swift` | Mean orbital elements + EoC | ~1-3° |
| Julian Date | `JulianDate.swift` | Standard conversion | Exact |
| Local Sidereal Time | `SiderealClock.swift` | GMST + longitude offset | < 1 sec |

---

## API Rate Limits & Politeness

| Service | Rate Limit | Galactic Behavior |
|---------|-----------|-------------------|
| NWS | Undocumented; User-Agent required | One call per user-initiated refresh |
| SWPC | Generous public access | One call per refresh |
| aprs.fi | Key-based, generous for reads | One call per callsign lookup |
| NASA APIs | 1000/hour with key; 30/hour without | Used sparingly (APOD, NEO, DONKI) |
| POTA | Public, no documented limit | One call per refresh |
| The Space Devs | 15/hour without key | One call per refresh |

Galactic never polls in the background. All API calls are user-initiated (pull-to-refresh, app launch, widget timeline update every 30 min).
