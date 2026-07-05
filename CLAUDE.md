# StatusGalactic-iOS — agent instructions

Spacetrucker Galactic: Swift/SwiftUI personal-almanac app (Earth,
marine, and space weather; astronomy; Meshtastic mesh). Shipped on the
App Store. On-device-only data architecture — keep it that way.

## Working rules

1. **Shipped production app.** Changes must build clean and pass the
   unit suite before commit; no autonomous pushes to `main` — the human
   reviews first. This overrides workspace-level autonomy conventions
   in `AGENTS.md` for product code.
2. Astronomy behavior keeps parity with the legacy `../weathergalactic`
   backend; cross-check before changing calculations.
3. `FEATURE_MATRIX.md` tracks the iOS ↔ Android feature matrix — update
   it when a user-facing feature lands.
4. User-supplied API keys (see `StatusGalactic/Features/Settings/
   APIKeyHelp.swift`) stay on-device; never add telemetry or outbound
   calls that carry them anywhere but the intended provider.

## Build / test

```bash
xcodebuild test -project StatusGalactic.xcodeproj \
  -scheme StatusGalactic \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skip-testing:StatusGalacticUITests
```

CI (`.github/workflows/ci.yml`) runs unit tests on push/PR to `main`.

## Token / Cost Ledger

The owner bills from `LEDGER.md` (exact, never estimated). After every
substantive commit: run `~/.claude/billing/ledger.py --append --summary
"<desc>"`, then commit `LEDGER.md` as its own `chore(ledger): <sha>`
commit. Never hand-author, estimate, or rewrite rows (append-only); if
the script can't produce a row, stop and surface it. See
`ledger.py --help` for flags (`--dry-run`, `--commit <sha>`).
