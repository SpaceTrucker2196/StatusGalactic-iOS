#!/bin/sh
# Xcode Cloud auto-runs this file after `git clone` and before
# resolving SPM packages / running `xcodebuild`. Apple's runner is a
# clean macOS VM, so we have to:
#
#   1. install xcodegen (Homebrew is preinstalled on Xcode Cloud)
#   2. regenerate StatusGalactic.xcodeproj from project.yml — it's
#      gitignored, so without this step xcodebuild has nothing to
#      open and the build fails immediately
#
# Anything we write to stdout/stderr shows up in the Xcode Cloud
# build log under the "Post-clone" step.

set -euo pipefail

echo "▶︎ ci_post_clone.sh: bootstrapping xcodegen build environment"

# Xcode Cloud invokes ci_scripts/ci_post_clone.sh with CWD set to
# the ci_scripts/ directory itself. Hop up to the repo root so
# `xcodegen generate` (which reads ./project.yml) finds the file.
cd "$(dirname "$0")/.."
echo "  • repo root: $(pwd)"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "  • installing xcodegen via Homebrew…"
  brew install xcodegen
else
  echo "  • xcodegen already on PATH ($(xcodegen --version))"
fi

echo "  • running xcodegen generate"
xcodegen generate

# Xcode Cloud disables automatic SPM resolution for reproducibility
# and refuses to build without a checked-in Package.resolved. We
# can't commit the file at its real path because the whole
# .xcodeproj/ directory is gitignored — xcodegen rebuilds it from
# scratch each clone. The workaround: keep a hand-committed copy at
# ci_scripts/Package.resolved and copy it into the generated
# workspace right after xcodegen finishes.
#
# When you bump or add a Swift package in Xcode locally, refresh
# the committed copy with:
#   cp StatusGalactic.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved \
#      ci_scripts/Package.resolved
echo "  • staging committed Package.resolved into the regenerated workspace"
SPM_DEST="StatusGalactic.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
mkdir -p "$SPM_DEST"
cp ci_scripts/Package.resolved "$SPM_DEST/Package.resolved"

echo "✓ StatusGalactic.xcodeproj is ready for xcodebuild"
