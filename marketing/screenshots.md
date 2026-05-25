# Spacetrucker Galactic — Screenshot Plan

App Store Connect requires screenshots for the **6.9" iPhone** class
(iPhone 17 Pro Max, 1320 × 2868). 6.1" is optional but recommended.
Watch app needs separate watchOS screenshots. 5–10 shots per device
size; we ship 12 to give Apple flexibility.

The order leads with the **RF / space-weather story** because that's
the target audience. Earth weather, marine, and sun/moon/planets are
supporting features — they appear later in the gallery.

## Shot list (in order)

| # | File | Surface | What it shows | Caption |
|---|---|---|---|---|
| 1 | `01-rf-hero.png` | RF tab | Station header + HF propagation conditions + Kp / SFI panel | **"Your station, briefed."** |
| 2 | `02-aurora-kp.png` | RF tab, scrolled | Aurora-likelihood flag + Kp index + A index | **"Know when the bands are about to go interesting."** |
| 3 | `03-pota-sota.png` | RF tab, scrolled | Parks On The Air + Summits On The Air active spots | **"POTA and SOTA, side by side."** |
| 4 | `04-dx-cluster.png` | RF tab, scrolled | DX Cluster recent spots | **"DX cluster, at a glance."** |
| 5 | `05-callsigns.png` | Callsigns tab | List with 3+ saved callsigns, APRS symbol icons | **"Track your crew by callsign."** |
| 6 | `06-callsign-detail.png` | Callsign detail | Map at last-known position, path stats, open-in-Maps | **"Last-known position. One tap to navigate."** |
| 7 | `07-brief-hero.png` | Brief tab | Earth weather + SunStrip at a hero location | **"The sky above. The road ahead."** |
| 8 | `08-sun-twilight.png` | Brief tab, scrolled | 24-hour SunStrip + twilight transitions | **"Sunrise to astronomical dusk, in your zone."** |
| 9 | `09-launches.png` | Brief tab, scrolled | Upcoming Launches section | **"Next five orbital launches."** |
| 10 | `10-marine.png` | Brief tab | Marine Weather (GMZ033 or similar) section | **"Marine forecasts for coastal use."** |
| 11 | `11-widget.png` | Home screen | Medium Spacetrucker Galactic widget on a clean home screen | **"Glance at the day."** |
| 12 | `12-settings.png` | Settings tab | APRS.fi key, marine zone, notification toggles, User-Agent | **"No accounts. No tracking. Your device, your data."** |

## Hero-location coordinates (for the simulator)

Use **Features → Location → Custom Location…** in Simulator.app, or
the location entry under the simulator's Debug menu:

| Shot | Location | Lat | Lng | TZ |
|---|---|---|---|---|
| 1–4 (RF) | Anywhere with decent NWS coverage — pick one with a non-trivial Kp story when you capture. Suggest **Bozeman, MT** for a slightly poleward read. | 45.68 | -111.04 | America/Denver |
| 5–6 (Callsigns) | Add a couple of real callsigns (e.g. your own + a friend's) so the detail view has a real APRS path. | — | — | — |
| 7–9 (Brief) | **Valley of the Gods, UT** — desert dusk reads beautifully on the SunStrip. | 37.23 | -109.89 | America/Denver |
| 10 (Marine) | **Key West, FL**, marine zone `GMZ033`. | 24.55 | -81.78 | America/New_York |
| 11 (Widget) | Whatever the device is at when you compose the home screen. | — | — | — |
| 12 (Settings) | Doesn't depend on location. | — | — | — |

## Watch shots (4 needed)

1. Watch app home view (brief loaded)
2. Scrolled to the RF / Kp glance card
3. Rectangular complication on a Modular or Infograph face
4. Circular complication on a different watch face

Capture from the **Watch Simulator** via Simulator.app → Devices →
the paired watch:

```bash
xcrun simctl io <watch-udid> screenshot marketing/screenshots/watch-01-home.png
```

## Capture procedure

The repo ships an XCUITest-driven pipeline. **No manual sim driving.**

```bash
scripts/screenshots.sh           # runs both 6.9" and 6.1"
scripts/screenshots.sh --6.9     # 6.9" only (iPhone 17 Pro Max)
scripts/screenshots.sh --6.1     # 6.1" only (iPhone 17 Pro)
```

How it works:

1. `StatusGalacticUITests/ScreenshotTests.swift` launches the app with
   `-UITEST_SCREENSHOT_MODE`. `StatusGalactic/Screenshots/ScreenshotMode.swift`
   detects the flag and seeds a deterministic hero brief + APRS state,
   so no network / API key / location prompt is required.
2. Each `test_NN_<name>` function navigates to one surface and attaches
   `XCUIScreen.main.screenshot()` as an `XCTAttachment` named to match
   the marketing slot (`01-rf-hero`, `02-aurora-kp`, …).
3. `scripts/screenshots.sh` orchestrates: boot the right sim, override
   the status bar to **9:41 / full battery / full bars** (Apple's
   marketing convention), `xcodebuild test`, extract attachments from
   the xcresult bundle, rename to clean names, resample to the App
   Store target size.
4. PNGs land in `marketing/screenshots/<device>/<name>.png`. The
   directory is gitignored — App Store uploads only.

The orchestrator is **idempotent**: it nukes the prior output for each
device before re-running, so stale PNGs never make it into the upload.

If the suite hits the Xcode 26 / iOS 26 SIGKILL flake on a launch, the
script auto-retries the failed tests in isolation (single-test
invocations are stable). The happy path stays a single suite run.

### Shot 11 — widget

Home-screen widget captures (`11-widget`) aren't covered by XCUITest —
the test runner can't drive SpringBoard. Capture manually with a
simulator booted to a clean home screen + the medium widget placed:

```bash
xcrun simctl io booted screenshot marketing/screenshots/iphone-6.9/11-widget.png
```

### Manual fallback

For one-off captures with a simulator already on the right surface:

```bash
xcrun simctl io booted screenshot marketing/screenshots/manual.png
```

### Legacy interactive script

`tools/capture-screenshots.sh` is the older interactive driver —
useful when you want to capture a *real* network-loaded brief instead
of the seeded fixture. Pass `DEVICE_UDID=...` to pin a specific sim.

## Setup before capture

The automated pipeline handles boot, install, launch, status-bar
override, and hero-data seeding. Prerequisites:

1. An available **iPhone 17 Pro Max** simulator instance (6.9" slot)
   and an **iPhone 17 Pro** simulator instance (6.1" slot). Both
   already ship with Xcode 26.
2. Xcode command-line tools on `PATH` (`xcrun simctl`, `xcodebuild`,
   `xcrun xcresulttool`, `sips`, `python3`).

No keys, no callsigns, no location pinning — `ScreenshotMode` (only
active when launched with `-UITEST_SCREENSHOT_MODE`) seeds:

- `K8RVR` as the user callsign, demo APRS key, marine zone `GMZ033`
- `CLLocation(45.68, -111.04)` — Bozeman, MT — as `lastLocation`
- A hero `Brief` covering every section the shots target (HF band
  conditions, POTA / SOTA / DX, Earth + Marine + Sun + Moon + Planets
  + Launches, aurora forecast, magnetic declination, …)
- Three saved callsigns and a small APRS thread+bulletin set

## Output paths

All shots land in `marketing/screenshots/<device>/NN-name.png`. The
directory is gitignored (see `.gitignore`) so PNG churn stays out of
the repo. Add the hero shot manually to `marketing/` if you want one
embedded in the README.

## Caption typography (when you composite)

- Title: **SF Pro Display, weight 700, 64 pt**
- Subtitle: **SF Pro Text, weight 400, 32 pt**
- Margin: 12% top, 6% horizontal
- Background: matte black, or a tint of `GalacticPalette.neonCyan`
  for the radio-themed shots (1–6).
