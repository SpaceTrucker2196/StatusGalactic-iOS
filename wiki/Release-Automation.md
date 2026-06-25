# Release Automation (Xcode Cloud)

Spacetrucker Galactic ships to the App Store via **Xcode Cloud**. A
build is triggered by pushing a git tag whose name matches the
pattern `AppStore-Release-*`. Xcode Cloud archives the iOS app +
widget extension, signs them with the team profile
(`U3Z59VXPUB`), and submits the build to App Store Connect.

---

## How a release happens

1. Bump `CFBundleShortVersionString` and/or `CFBundleVersion` in
   `project.yml` and run `xcodegen generate`.
2. Commit and merge to `main`.
3. Tag the release commit:
   ```bash
   git tag AppStore-Release-v0.2.1
   git push origin AppStore-Release-v0.2.1
   ```
4. Xcode Cloud picks up the tag push, runs the workflow, and
   uploads the resulting build to App Store Connect. Watch progress
   in **Xcode → Report Navigator → Cloud** or in App Store Connect
   under **Xcode Cloud → Builds**.

The free Apple Developer tier includes 25 compute hours/month — a
full archive build is ~5–10 minutes, so there's a wide margin
before any paid tier is needed.

---

## Repo-side: `ci_scripts/ci_post_clone.sh`

The `.xcodeproj` is gitignored (it's generated from `project.yml`
by xcodegen — see `Getting-Started.md`). Xcode Cloud clones a bare
repo into a clean macOS VM, so we have to regenerate the project
file before `xcodebuild` runs.

Xcode Cloud automatically executes any executable script at
`ci_scripts/ci_post_clone.sh` (relative to the repo root) after
clone and before package resolution. Our script:

1. Hops up to the repo root (Xcode Cloud invokes the script with
   `CWD = ci_scripts/`).
2. Installs xcodegen via the preinstalled Homebrew if it isn't
   already on `PATH`.
3. Runs `xcodegen generate`.

Output lands in the **Post-clone** section of the build log. To
debug locally, simulate Xcode Cloud's invocation:

```bash
rm -rf StatusGalactic.xcodeproj
(cd ci_scripts && bash ci_post_clone.sh)
ls -d StatusGalactic.xcodeproj   # should now exist
```

---

## One-time: Xcode Cloud workflow setup

Xcode Cloud workflows live in **App Store Connect**, not in the
repo. You only need to set this up once.

1. Open the project in Xcode.
2. **Report Navigator** (⌘9) → **Cloud** tab → **Create
   Workflow** for `StatusGalactic`.
3. **General**
   - Name: `App Store Release`
   - Description: `Tag-triggered archive + App Store upload`
   - Repository: SpaceTrucker2196/StatusGalactic-iOS
4. **Environment**
   - Xcode: *Latest Release*
   - macOS: *Latest Release*
5. **Start Conditions** — delete the default branch condition,
   then add:
   - **Tag Changes**
     - Source repository: this repo
     - Tag pattern: `AppStore-Release-*`
   - Leave "Auto-cancel builds" on.
6. **Actions** — add:
   - **Archive**
     - Scheme: `StatusGalactic`
     - Platform: iOS
     - Distribution preparation: *App Store Connect*
7. **Post-Actions** — add:
   - **TestFlight Internal Testing** with the internal group of
     your choice. (Optional: add **TestFlight External Testing**
     and/or **App Store** submission to push straight to review.)
8. **Save**. Xcode Cloud will ask permission to connect to App
   Store Connect — accept once.

Subsequent pushes of any `AppStore-Release-*` tag will fire the
workflow automatically. Pushing other tags or pushing to `main`
without a matching tag does nothing.

### Why a tag pattern, not the exact string

Git tags are unique per repo, so a single literal tag like
`AppStore-Release` can only be pushed once. The `*` suffix lets
each release carry its version (`AppStore-Release-v0.2.1`,
`AppStore-Release-2026.06.25`, etc.) and still match the trigger.

---

## Signing

`project.yml` sets `DEVELOPMENT_TEAM: "U3Z59VXPUB"` on every
target. Xcode Cloud uses managed App Store distribution profiles
issued automatically by App Store Connect for the team — no
profiles need to live in the repo. If signing fails, double-check
that the Xcode Cloud workflow's "Distribution preparation" is set
to **App Store Connect** rather than **Developer ID** or
**Enterprise**.

---

## Local fallback

If Xcode Cloud is unavailable (outage, free-tier exhausted), you
can archive and upload from a developer Mac the same way:

```bash
xcodegen generate
xcodebuild \
  -project StatusGalactic.xcodeproj \
  -scheme StatusGalactic \
  -configuration Release \
  -archivePath build/StatusGalactic.xcarchive \
  archive
xcrun altool --upload-app \
  -f build/StatusGalactic.ipa \
  --type ios \
  --apiKey <KEY_ID> \
  --apiIssuer <ISSUER_ID>
```

(You'll need an App Store Connect API key in `~/.appstoreconnect/private_keys/`.)
