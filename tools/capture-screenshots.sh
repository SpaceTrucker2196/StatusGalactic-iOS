#!/usr/bin/env bash
# capture-screenshots.sh — produce App Store screenshots from a booted
# iOS simulator (or attached device via xcrun devicectl).
#
# Usage:
#   tools/capture-screenshots.sh [output-dir]
#
# What it does:
#   1. Finds the first booted iOS simulator. If none is booted, lists
#      the available simulators and asks you to boot one in
#      Simulator.app first (or run `xcrun simctl boot "iPhone 17 Pro
#      Max"`).
#   2. Overrides the simulator status bar to the canonical
#      9:41 / full battery / full bars / no notifications shown on
#      every Apple marketing screenshot.
#   3. Walks you through the screens listed in
#      marketing/screenshots.md and dumps a PNG for each into the
#      output directory.
#
# Like the Android counterpart this is interactive on purpose —
# SwiftUI doesn't have a stable headless way to drive the tab bar +
# sheets reliably across simulator OS versions, so you navigate the
# sim manually and the script captures the current frame on Enter.
#
# Resulting PNG resolution = whatever the booted simulator's panel
# size is. App Store Connect accepts:
#   - 6.9" iPhone (iPhone 17 Pro Max, 1320 × 2868) — required
#   - 6.5" / 6.1" iPhone (legacy slots, optional)
# Capture from each device size you intend to upload.
#
# Requires: Xcode command-line tools (`xcrun simctl`) on PATH.

set -euo pipefail

OUT_DIR="${1:-marketing/screenshots}"
mkdir -p "$OUT_DIR"

# ---- Find a booted simulator ----
# Honor $DEVICE_UDID if set so you can target a specific device when
# multiple sims are booted (e.g. picking the 6.9" Pro Max for the
# required App Store slot rather than whichever sim booted first).
echo "Looking for a booted iOS simulator…"
if [[ -n "${DEVICE_UDID:-}" ]]; then
    BOOTED="$DEVICE_UDID"
else
    BOOTED=$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/ {print $2; exit}')
fi

if [[ -z "$BOOTED" ]]; then
    echo
    echo "No simulator is booted. Open Simulator.app and start one"
    echo "(File → Open Simulator → iOS 17 → iPhone 17 Pro Max), or run:"
    echo
    echo "    xcrun simctl boot \"iPhone 17 Pro Max\""
    echo
    echo "Available device types in the current Xcode:"
    xcrun simctl list devicetypes \
        | awk -F '[()]' '/iPhone/ {print "  - " $1}' \
        | tail -20
    exit 1
fi

DEVICE_ID="$BOOTED"
DEVICE_NAME=$(xcrun simctl list devices booted \
    | awk -v id="$DEVICE_ID" '$0 ~ id { sub(/ *\(.*/, ""); sub(/^ */, ""); print; exit }')
echo "Device: $DEVICE_NAME ($DEVICE_ID)"

# ---- Status bar override ----
echo "Overriding status bar (9:41, full battery, full bars, no notifications)…"
xcrun simctl status_bar "$DEVICE_ID" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100 \
    >/dev/null

cleanup() {
    echo "Clearing status bar override…"
    xcrun simctl status_bar "$DEVICE_ID" clear || true
}
trap cleanup EXIT

# ---- Capture loop ----
# Order matches marketing/screenshots.md so file numbering lines up
# with the App Store Connect upload sequence. Lead with the RF /
# space-weather story since that's the target audience.
SCREENS=(
    "01-rf-hero:RF tab → station header, HF propagation conditions, Kp + SFI visible at top"
    "02-aurora-kp:RF tab → scrolled so the aurora-likelihood + Kp panel is centered"
    "03-pota-sota:RF tab → scrolled to Parks On The Air + Summits On The Air sections"
    "04-dx-cluster:RF tab → scrolled to DX Cluster section with recent spots"
    "05-callsigns:Callsigns tab → list with 3+ saved callsigns and APRS symbol icons"
    "06-callsign-detail:Callsigns tab → tap a callsign → detail with map and path stats"
    "07-brief-hero:Brief tab → loaded brief at a hero location, Earth weather + SunStrip visible"
    "08-sun-twilight:Brief tab → scrolled to Sun section showing 24-hour strip + twilight times"
    "09-launches:Brief tab → scrolled to Upcoming Launches section"
    "10-marine:Brief tab → with a marine zone configured, Marine Weather section visible"
    "11-widget:Home screen → medium Spacetrucker Galactic widget on a clean home screen"
    "12-settings:Settings tab → API key, marine zone, notification toggles visible"
)

echo
echo "About to capture ${#SCREENS[@]} screens. Navigate the simulator to"
echo "the surface each prompt asks for, then press Enter (or 's' to skip)."
echo "Files land in $OUT_DIR/."
echo

for entry in "${SCREENS[@]}"; do
    NAME="${entry%%:*}"
    PROMPT="${entry##*:}"
    PATH_OUT="$OUT_DIR/${NAME}.png"

    echo "[$NAME]"
    echo "  → $PROMPT"
    read -r -p "  press Enter when ready (or s to skip): " ANSWER
    if [[ "$ANSWER" == "s" || "$ANSWER" == "S" ]]; then
        echo "  skipped"
        continue
    fi
    xcrun simctl io "$DEVICE_ID" screenshot "$PATH_OUT"
    echo "  saved → $PATH_OUT ($(wc -c < "$PATH_OUT") bytes)"
done

echo
echo "Done. Output: $OUT_DIR"
echo "Drag each PNG into App Store Connect → your app → Screenshots."
echo "Re-run on a different simulator size to fill the 6.1\" slot."
