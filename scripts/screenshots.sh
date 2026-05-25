#!/bin/bash
#
# Run the StatusGalacticUITests/ScreenshotTests suite against every App
# Store screenshot size and write the extracted PNGs to
# ./marketing/screenshots/<device>/.
#
# Usage:   scripts/screenshots.sh [--6.9|--6.1]
# Output:  marketing/screenshots/<device>/NN-name.png
#
# Idempotent — nukes the prior output for each device before re-running
# so stale PNGs never make it to the App Store upload.
#
# Required tools (all ship with Xcode): xcodebuild, xcrun simctl,
# xcrun xcresulttool, /usr/bin/python3, sips.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

SCHEME="StatusGalactic"
TEST_TARGET="StatusGalacticUITests"
TEST_CLASS="ScreenshotTests"
OUTPUT_ROOT="marketing/screenshots"

# Device matrix — (sim name | folder name | target W | target H).
#
# App Store Connect currently requires the **6.9"** slot (iPhone 17 Pro
# Max, native 1320 × 2868) and accepts the older **6.7"** size (1290 × 2796)
# as a fallback in that slot. We render natively and resample with `sips`
# to the 6.7" target size for broadest compatibility — the aspect ratio
# diff is ~3% and visually imperceptible.
#
# The optional **6.1"** slot fills with iPhone 17 Pro at 1206 × 2622.
DEVICES=(
  "iPhone 17 Pro Max|iphone-6.9|1290|2796"
  "iPhone 17 Pro|iphone-6.1|1206|2622"
)

case "${1:-}" in
  --6.9)  DEVICES=("${DEVICES[0]}") ;;
  --6.1)  DEVICES=("${DEVICES[1]}") ;;
  "" )    ;;
  *)      echo "Unknown flag: $1" >&2; exit 64 ;;
esac

echo "==> Workspace: $REPO_ROOT"
xcodebuild -version 2>/dev/null | head -1 || true

for spec in "${DEVICES[@]}"; do
  IFS='|' read -r device folder target_w target_h <<< "$spec"

  echo ""
  echo "==> $device  →  $OUTPUT_ROOT/$folder  (target ${target_w}x${target_h})"

  device_dir="$OUTPUT_ROOT/$folder"
  rm -rf "$device_dir"
  mkdir -p "$device_dir"

  # Resolve to a specific UDID — when more than one sim shares the same
  # name (common after Xcode upgrades), xcodebuild's launch-services
  # routing gets confused and fails with FBSOpenApplicationServiceError.
  udid=$(xcrun simctl list devices available -j | \
    /usr/bin/python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d.get('name') == '$device' and d.get('isAvailable', True):
            print(d['udid']); sys.exit(0)
")
  if [ -z "$udid" ]; then
    echo "    !! no available simulator named '$device'" >&2
    exit 70
  fi
  echo "    udid: $udid"

  # Pre-boot and wait for the sim to be fully ready — running
  # `xcodebuild test` against a cold sim can race the bootloader and
  # refuse to launch xctrunner.
  echo "    booting simulator (waiting for full boot)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" >/dev/null 2>&1
  xcrun simctl status_bar "$udid" override \
    --time "9:41" \
    --batteryState charged \
    --batteryLevel 100 \
    --cellularBars 4 \
    --wifiBars 3 \
    --dataNetwork wifi >/dev/null 2>&1 || true

  # Fresh result bundle per device, kept in a tempdir.
  result_bundle="$(mktemp -d)/result.xcresult"

  echo "    running $TEST_TARGET/$TEST_CLASS"
  set +e
  xcodebuild test \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$udid" \
    -only-testing:"$TEST_TARGET/$TEST_CLASS" \
    -resultBundlePath "$result_bundle" \
    -quiet
  set -e
  # Suite exit is allowed to be non-zero — Xcode 26 + iOS 26 sim sporadically
  # SIGKILLs individual tests under back-to-back launches. We harvest whatever
  # passed, then retry each failed test on its own.

  echo "    extracting attachments"
  attachments_dir="$(mktemp -d)"
  xcrun xcresulttool export attachments \
    --path "$result_bundle" \
    --output-path "$attachments_dir" >/dev/null

  /usr/bin/python3 scripts/rename_screenshots.py \
    "$attachments_dir" "$device_dir"

  # Identify failed test cases and re-run them in isolation. A single-test
  # invocation always passes locally, so this loop is a deterministic fix
  # for the suite-mode SIGKILL flake without slowing down the happy path.
  failed_tests=$(xcrun xcresulttool get test-results tests --path "$result_bundle" \
    | /usr/bin/python3 -c "
import json, sys
data = json.load(sys.stdin)
def walk(node, out):
    if node.get('nodeType') == 'Test Case' and node.get('result') == 'Failed':
        out.append(node.get('name','').rstrip('()'))
    for c in node.get('children', []):
        walk(c, out)
out = []
for d in data.get('testNodes', []):
    walk(d, out)
print(' '.join(out))
")

  if [ -n "$failed_tests" ]; then
    echo "    retrying flaky tests in isolation:" $failed_tests
    for t in $failed_tests; do
      retry_bundle="$(mktemp -d)/retry-$t.xcresult"
      set +e
      xcodebuild test \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$udid" \
        -only-testing:"$TEST_TARGET/$TEST_CLASS/$t" \
        -resultBundlePath "$retry_bundle" \
        -quiet
      set -e
      retry_attachments="$(mktemp -d)"
      xcrun xcresulttool export attachments \
        --path "$retry_bundle" \
        --output-path "$retry_attachments" >/dev/null 2>&1 || true
      /usr/bin/python3 scripts/rename_screenshots.py \
        "$retry_attachments" "$device_dir" >/dev/null
    done
  fi

  count=$(find "$device_dir" -name "*.png" | wc -l | tr -d ' ')
  echo "    wrote $count PNGs at native sim resolution"

  echo "    resampling to ${target_w}x${target_h} for App Store"
  for f in "$device_dir"/*.png; do
    sips --resampleHeightWidth "$target_h" "$target_w" "$f" \
      --out "$f" >/dev/null 2>&1
  done
done

echo ""
echo "==> done. Open the folder:"
echo "    open $OUTPUT_ROOT"
