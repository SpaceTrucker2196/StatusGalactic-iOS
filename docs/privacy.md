---
title: Privacy
layout: default
---

# Spacetrucker Galactic (iOS) — Privacy Policy

*Effective date: 2026-06-18. Version 1.1 (v0.3 release — adds the Meshtastic tab).*

> This is a plain-language privacy policy describing what Spacetrucker
> Galactic actually does with data. The factual statements below are
> accurate to the current release build and match the in-app and App Store
> privacy disclosures.

---

## Summary in one sentence

Spacetrucker Galactic talks to public weather, space-weather, marine,
launch, and APRS services on your behalf — it has no backend, no
accounts, and no analytics, and nothing about you is ever sent to a
Spacetrucker Galactic server because there isn't one.

---

## What we collect

**Nothing.** Spacetrucker Galactic has no backend, no analytics, no
crash reporters, and no advertising SDKs. The app developer
(SpaceTrucker2196) operates no servers, no user database, and has no
way to see what's in your Spacetrucker Galactic install.

The only third-party Swift package linked into the app is Apple's
Apache-2.0 [`swift-protobuf`](https://github.com/apple/swift-protobuf),
scoped to the Meshtastic tab so it can decode the wire format your
Meshtastic node speaks. `swift-protobuf` is a pure-Swift serialisation
library — it has no telemetry, no analytics, and never makes a network
request of its own.

## What the app sends out

Every outbound request goes to a single public service:

| Destination | What is sent | Why |
|-------------|--------------|-----|
| `api.weather.gov` | Your latitude and longitude (rounded to 4 decimals) | NWS forecast for your area |
| `tgftp.nws.noaa.gov` | A marine zone ID (e.g. `GMZ033`), only if you set one | NWS marine bulletin |
| `services.swpc.noaa.gov` | Nothing identifying — a generic GET | Space weather (Kp index, 10.7 cm flux) |
| `ll.thespacedevs.com` | Nothing identifying — a generic GET | Upcoming launches list |
| `api.aprs.fi` | A callsign you've added + the aprs.fi API key you entered in Settings | Ham radio position lookup |

Your User-Agent is included on every request (NWS requires one). The
default identifies the app and version; you can change it in Settings.

**Meshtastic tab — Bluetooth only, never the internet.** When you use
the Mesh tab, the app pairs with a nearby Meshtastic node over
Bluetooth LE. The node is short-range hardware you own. Messages you
send go from your iPhone to that node, and from there onto the mesh
radio network — they never traverse the internet through Spacetrucker
Galactic. Other apps on your phone do not see this Bluetooth
connection.

## What the app stores on your device

| Data | Where | Purpose | When deleted |
|------|-------|---------|--------------|
| Saved APRS callsigns (call, label, notes) | `UserDefaults` | Quick selection in the Callsigns tab | Remove from the Callsigns tab, or delete the app |
| Your aprs.fi API key | `UserDefaults` (SecureField on input) | Callsign position lookups | Clear it in Settings, or delete the app |
| Default marine zone | `UserDefaults` | Convenience | Clear it in Settings |
| User-Agent string | `UserDefaults` | Sent with HTTP requests | Reset in Settings |
| Notification enable flags + next-fire times | `UserDefaults` | Schedule local reminders | Turn off in Settings, or delete the app |
| Pending local notifications | iOS notification center (system-managed) | Fire golden-hour and astronomical-dusk alerts | Turn off in Settings; iOS clears the queue |
| Meshtastic traffic + chat history | SwiftData store under the app's `Library/Application Support/Meshtastic.store` | Show recent mesh activity when you reopen the Mesh tab | Tap "Clear history" in the Mesh tab's STATUS section, or delete the app |

All of the above is stored inside the app's private container on this
device (iOS sandbox; no other app can read it without jailbreaking).
The Meshtastic store is pinned to the app's own sandbox — *not* the
App Group container that the widget reads from — so Mesh chat and
traffic stay private to the main app.

## What the app does not do

- **No account.** You don't sign up. There's no sign-in button.
- **No analytics.** We don't know how often you open the app or what
  tabs you use.
- **No crash reports.** The app does not phone home when something
  goes wrong.
- **No advertising identifier reads.** IDFA is never requested.
- **No tracking across other apps or websites.** App Tracking
  Transparency permission is never requested because the app does no
  tracking.
- **No background location.** Permission is "when in use" only, and
  the app reads one fix per refresh — never continuously.
- **No `authorizedAlways` location.** Only when-in-use.
- **No Contacts, Calendar, Photos, Microphone, Camera, HealthKit, or
  Motion access.**
- **Bluetooth access is requested only when you open the Mesh tab.**
  The app uses Bluetooth solely to talk to a Meshtastic node you've
  paired with. It does not scan for nearby Bluetooth devices for any
  other purpose, does not advertise, and does not contact Bluetooth
  beacons for location. If you never open the Mesh tab, the prompt
  is never shown.
- **No push notifications.** Reminders use local notifications
  scheduled on-device.
- **No purchases.** No StoreKit, no IAP.
- **No analytics or advertising SDKs.** The single third-party Swift
  package linked into the app is Apple's Apache-2.0 `swift-protobuf`,
  used to serialise the Meshtastic wire format. It performs no
  network requests of its own.

## When data leaves the device

The only paths data takes off your device are user-initiated, and they
go to public services rather than to us:

1. **Forecast requests.** When you refresh, your latitude/longitude
   goes to NWS, your marine zone (if set) goes to the NOAA marine
   text bulletin server, and generic requests go to SWPC and The
   Space Devs.
2. **Callsign lookups.** When you tap a saved callsign, the callsign
   and your aprs.fi API key go to aprs.fi.
3. **Meshtastic mesh radio.** When you tap **Send** in the Mesh tab,
   the message goes over a short Bluetooth LE link to your paired
   Meshtastic node, which then transmits it on the mesh radio
   network. Spacetrucker Galactic is not in that radio path — it
   only hands the bytes to your node.
4. **iCloud Backup.** Apple's standard device backup may include the
   app's `UserDefaults` and SwiftData stores if you have iCloud
   Backup enabled in iOS Settings. That is the operating system
   doing this, not Spacetrucker Galactic — the app never uploads
   anything to iCloud directly.

## Children

Spacetrucker Galactic is not directed at children. The expected user is
an adult traveler, sailor, photographer, or ham operator. Age rating:
**4+**, with no objectionable content, no user-generated content, and
no in-app purchases.

## Cookies, beacons, web tracking

The Spacetrucker Galactic iOS app does not embed a web view that loads
remote content. Taps on links open in your default browser (Safari),
and Spacetrucker Galactic sends no data with those URLs.

## Changes to this policy

If what Spacetrucker Galactic does with data changes, this page will be
updated and the version number above will be bumped. The App Store will
require re-confirmation of the privacy disclosures for the next
release.

## Contact

This policy is hosted at
**[spacetrucker2196.github.io/StatusGalactic-iOS/privacy](https://spacetrucker2196.github.io/StatusGalactic-iOS/privacy)**.

To ask a question about this policy or about how Spacetrucker Galactic
handles data, email
**[support@river.io](mailto:support@river.io)**. We respond within a
few business days.

---

[← back to Spacetrucker Galactic](./)
