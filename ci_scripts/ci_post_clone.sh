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

# Xcode Cloud runs xcodebuild with automatic SPM resolution disabled
# for reproducibility, and refuses to build without a checked-in
# Package.resolved. xcodegen doesn't produce one (the .xcodeproj is
# regenerated from scratch on every clone), so we resolve once here
# to populate
# StatusGalactic.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
# before the archive step runs. Without this the archive fails with
# "a resolved file is required when automatic dependency resolution
# is disabled".
echo "  • resolving Swift Package Manager dependencies"
xcodebuild \
  -resolvePackageDependencies \
  -project StatusGalactic.xcodeproj \
  -scheme StatusGalactic \
  -clonedSourcePackagesDirPath SourcePackages

echo "✓ StatusGalactic.xcodeproj is ready for xcodebuild"
