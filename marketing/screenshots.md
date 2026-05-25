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

The repo ships an interactive driver:

```bash
tools/capture-screenshots.sh [output-dir]   # default: marketing/screenshots
```

It picks the first booted simulator, overrides the status bar to
**9:41 / full battery / full bars / no notifications** (Apple's
marketing convention), then walks through the 12 screens above —
press Enter at each prompt to capture the current frame, `s` to skip.
PNGs land as `01-rf-hero.png`, `02-aurora-kp.png`, etc.

To capture a second device size, boot a different simulator and re-run
with a different output dir:

```bash
xcrun simctl boot "iPhone 17 Pro"          # 6.1" class
tools/capture-screenshots.sh marketing/screenshots/iphone-17-pro
```

Manual fallback for one-off captures, with a simulator booted to the
right surface:

```bash
xcrun simctl io booted screenshot marketing/screenshots/manual.png
```

## Setup before capture

1. **Boot the right simulator.** iPhone 17 Pro Max (1320 × 2868) is
   the required size for App Store submission.
2. **Build + install + launch the app:**
   ```bash
   xcodebuild -project StatusGalactic.xcodeproj -scheme StatusGalactic \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
   APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name 'StatusGalactic.app' \
     -path '*Debug-iphonesimulator*' | head -1)
   xcrun simctl install booted "$APP_PATH"
   xcrun simctl launch booted com.spacetrucker.statusgalactic
   ```
3. **Configure once for the gallery:**
   - Settings → APRS.fi API key: paste your read key.
   - Settings → Default marine zone: `GMZ033` (Key West) so shot 10
     has data.
   - Callsigns tab: add at least 3 callsigns with real APRS activity
     so shots 5–6 look populated.
4. **Pin the simulator location** for shots 7–9 (Valley of the Gods)
   then again for shot 10 (Key West).
5. **Light vs Dark mode:** capture the canonical gallery in **dark
   mode** (matches the in-app neonCyan accent palette better). Re-run
   in light mode if you want an optional alternate gallery.

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
