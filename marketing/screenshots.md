# Spacetrucker Galactic — Screenshot Plan

App Store Connect requires screenshots for at least the 6.7" iPhone class (currently iPhone 17 Pro Max, 1320 × 2868) and 6.1" (iPhone 17 Pro). 5–10 shots per device size. Watch app needs separate watchOS screenshots.

## Shot list (in order)

1. **Hero: brief loaded at Valley of the Gods**
   - Source: simulate at lat 37.23, lng -109.89, tz America/Denver
   - Caption: "**The sky above. The road ahead.**"
   - Visible sections: location header, Earth Weather (5 periods), SunStrip, Sun (with twilight), Moon, Planets

2. **Marine forecast at Key West**
   - Source: simulate at lat 24.55, lng -81.78, zone GMZ033, tz America/New_York
   - Caption: "**Marine forecasts for coastal users.**"
   - Visible: Marine Weather (GMZ033) section expanded

3. **Sun + twilight detail**
   - Same as shot 1 scrolled to Sun section
   - Caption: "**Sunrise to astronomical dusk, in your zone.**"

4. **Callsign list + map detail**
   - Add two callsigns (W9FJC, KJ7CMR), tap to detail
   - Caption: "**Track friends by callsign.**"

5. **Widget on home screen**
   - Set up iOS 17 Pro home screen with medium Spacetrucker Galactic widget
   - Caption: "**Glance at the day.**"

6. **Settings**
   - Caption: "**No accounts. No tracking. Your data, your device.**"

## Watch shots (4 needed)

1. Watch app home view (brief loaded)
2. Sun card scrolled into view
3. Rectangular complication on a watch face (Modular, Infograph, or X-Large)
4. Circular complication on a different watch face

## Capture procedure

Once watchOS SDK and a paired sim are installed:

```bash
# Boot sim
xcrun simctl boot "iPhone 17 Pro"

# Wait until SpringBoard is ready (one option)
xcrun simctl bootstatus "iPhone 17 Pro" -b

# Install app
xcodebuild -project StatusGalactic.xcodeproj -scheme StatusGalactic \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/.../StatusGalactic.app

# Launch
xcrun simctl launch booted io.river.statusgalactic

# Capture
xcrun simctl io booted screenshot screenshots/01-hero.png
```

For consistent backgrounds use **Status Bar Override** before capture:

```bash
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
```

Reset when done:

```bash
xcrun simctl status_bar booted clear
```

## Output paths

All shots land in `marketing/screenshots/<device>/NN-name.png`. The dir is gitignored to keep PNG churn out of the repo (add a single hero image manually if you want one in the README).

## Caption typography (when you composite)

- Title: **SF Pro Display, weight 700, 64 pt**
- Subtitle: **SF Pro Text, weight 400, 32 pt**
- Margin: 12% top, 6% horizontal
- Background: matte black or a light tint of the in-shot accent
