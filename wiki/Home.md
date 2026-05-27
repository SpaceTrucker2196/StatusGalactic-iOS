# Spacetrucker Galactic — Wiki

<p align="center">
  <img src="../StatusGalactic/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png" width="120" alt="Galactic app icon" />
</p>

<p align="center"><strong>The sky and the road, briefed.</strong></p>

---

**Galactic** is a native iOS personal almanac for amateur radio operators, space-weather watchers, sailors, and anyone who keeps an antenna outside. It combines live HF propagation data, APRS tracking, Parks on the Air / Summits on the Air spots, weather, marine forecasts, sun/moon/planet positions, and upcoming launches — all tuned to your current location.

The app runs **entirely on-device** with zero backend dependency. Every data source is fetched directly from its public origin, and all astronomy computations happen locally using validated Meeus-based algorithms.

---

## Quick Navigation

| Page | Description |
|------|-------------|
| [Features](Features.md) | Complete guide to every section of the Galactic brief |
| [Architecture](Architecture.md) | How the app is built — layers, patterns, data flow |
| [Data Sources](Data-Sources.md) | Every API endpoint the app contacts, what it returns, and how it's used |
| [Astronomy Engine](Astronomy-Engine.md) | Deep dive into the on-device sun, moon, and planet computation |
| [Getting Started](Getting-Started.md) | Setting up the project for development |
| [Widgets & Watch](Widgets-and-Watch.md) | Home-screen widgets and Apple Watch companion app |
| [Notifications](Notifications.md) | Local notification scheduling for golden hour, twilight, and space weather |
| [APRS & Callsigns](APRS-and-Callsigns.md) | Callsign tracking, APRS messaging, DX stats |

---

## Design Principles

1. **No backend.** The app calls public APIs directly — no intermediary server, no account, no login.
2. **No analytics.** Zero crash reporters, no telemetry, no third-party SDKs.
3. **On-device first.** Astronomy (sun, moon, planets, magnetic declination) works offline. Network sections gracefully degrade with a quiet banner.
4. **Pure Swift.** Swift 5.10+, SwiftUI, no third-party dependencies. iOS 17+, watchOS 10+.
5. **Polite client.** Rate-limited, proper User-Agent, credits each data provider.

---

## At a Glance

| Metric | Value |
|--------|-------|
| Minimum iOS version | 17.0 |
| Swift version | 5.10+ |
| Third-party dependencies | 0 |
| Brief sections | 12+ |
| Live data sources | 8+ public APIs |
| Local computations | Sun events, moon phase, 10 planetary positions, magnetic declination |
| Delivery surfaces | App, widget (small/medium), watchOS app, watch complications |

---

## Screenshots

| Brief View | POTA / SOTA Spots | Home-Screen Widget | Settings |
|:---:|:---:|:---:|:---:|
| ![Brief](../docs/assets/img/screens/07-brief-hero.png) | ![POTA/SOTA](../docs/assets/img/screens/03-pota-sota.png) | ![Widget](../docs/assets/img/screens/11-widget.png) | ![Settings](../docs/assets/img/screens/12-settings.png) |

---

## License

MIT. See [LICENSE](../LICENSE).

**73 — de SpaceTrucker**
