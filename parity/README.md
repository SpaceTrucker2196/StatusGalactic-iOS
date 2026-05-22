# Parity Workspace

Cross-platform parity tracking for Spacetrucker Galactic, modeled on the CareTime parity pattern.

## Why this exists

Two (eventually three) implementations consume the same backend Brief schema:
- **Backend** (Python/FastAPI, weathergalactic) — owns the schema and all computations
- **iOS** (Swift/SwiftUI, StatusGalactic-iOS) — owns client UX, ships first
- **Android** (Kotlin/Compose, future StatusGalactic-Android) — mirrors iOS

Without explicit tracking, the two clients drift: iOS adds a field handler; Android forgets; a Brief renders incomplete on Android. This workspace catches that.

## How to use it

### When you ship a parity-relevant change

1. Update `../FEATURE_MATRIX.md` for the feature row (set the right cell to ✅ / 🚧 / ⏳ / ⚠️).
2. Append a one-line entry to `log.md`:
   ```
   2026-05-19 — M6 callsign registry — iOS shipped; Android pending (no Android repo yet)
   ```
3. If the change required design choices that may drift later, add a detailed audit file under `audits/`:
   ```
   audits/2026-05-19-callsign-registry.md
   ```

### When you start the Android port

1. Create `StatusGalactic-Android/MIGRATION_PLAN.md` from the iOS `ROADMAP.md` template.
2. Append a kickoff entry to `log.md` linking the first audit file.
3. For each iOS feature, port and write an audit file documenting:
   - iOS commit hash being ported
   - Kotlin types/libraries chosen
   - Tests mirrored (iOS test file → Kotlin test file)
   - Known drift

## File index

- `log.md` — chronological session log (one line per session)
- `audits/` — detailed drift catalogs and design decisions, one file per audit
- (eventually) `../StatusGalactic-Android/MIGRATION_PLAN.md` — the authoritative iOS→Android mapping when porting begins
