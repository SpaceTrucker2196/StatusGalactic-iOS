# Spacetrucker Galactic — Privacy Disclosure

This document is the source of truth for the App Store privacy questionnaire and the in-app/repo privacy disclosure. Update if any of these statements stop being true.

---

## Plain-English summary

Spacetrucker Galactic is a thin, on-device app. It talks to public weather and astronomy services directly. It does not have a backend server, an analytics SDK, or a user account.

- **No tracking.** No SDKs that track you across apps or websites. No advertising identifier reads.
- **No analytics.** No Firebase, no Mixpanel, no Sentry, no anything.
- **No data leaves the app to Spacetrucker Galactic.** Spacetrucker Galactic operates no servers and has no telemetry.
- **No accounts.** No sign-in.
- **No purchases.** No StoreKit, no IAP.
- **One third-party Swift package, scoped to one tab.** Apple's Apache-2.0 [`swift-protobuf`](https://github.com/apple/swift-protobuf) is linked solely so the Meshtastic tab can decode its node's protobuf wire format. It is a serialisation library — no telemetry, no network of its own.

## What the app sends out

Every outbound request goes to a single public service:

| Destination | What is sent | Why |
|-------------|--------------|-----|
| `api.weather.gov` | Your latitude and longitude (rounded to 4 decimals) | NWS forecast for your area |
| `tgftp.nws.noaa.gov` | A marine zone ID (e.g. `GMZ033`), only if you set one | NWS marine bulletin |
| `services.swpc.noaa.gov` | Nothing identifying — just a generic GET | Space weather (Kp, 10.7 cm flux) |
| `ll.thespacedevs.com` | Nothing identifying — generic GET | Upcoming launches list |
| `api.aprs.fi` | A callsign you have added + the aprs.fi API key you entered in Settings | Ham radio position lookup |

Your User-Agent is included on every request (NWS requires one). The default identifies the app and version; you can change it in Settings.

**Meshtastic tab — Bluetooth LE only, never the internet.** Mesh messages you send are handed to a paired Meshtastic node over a short Bluetooth LE link; the node transmits them on the mesh radio network. The iPhone makes no internet request for any of this.

## What the app stores on your device

| Data | Where | Purpose | When deleted |
|------|-------|---------|--------------|
| Saved APRS callsigns (call, label, notes) | `UserDefaults` | Quick selection in the Callsigns tab | Remove from the Callsigns tab, or delete the app |
| Your aprs.fi API key | `UserDefaults` (SecureField on input) | Callsign position lookups | Clear it in Settings, or delete the app |
| Default marine zone | `UserDefaults` | Convenience | Clear it in Settings |
| User-Agent string | `UserDefaults` | Sent with HTTP requests | Reset in Settings |
| Notification enable flags + the next-fire times | `UserDefaults` | Schedule local reminders | Turn off in Settings, or delete the app |
| Pending local notifications | iOS notification center (system-managed) | Fire golden-hour and astro-dusk alerts | Turn off in Settings; iOS clears the queue |
| Meshtastic traffic + chat history | SwiftData store under `Library/Application Support/Meshtastic.store` (the app's own sandbox, *not* the App Group) | Show recent mesh activity when you reopen the Mesh tab | Tap "Clear history" in the Mesh tab, or delete the app |

## What the app does NOT do

- Does not request location updates in the background.
- Does not request the user's precise location historically — only one-shot fixes when you tap refresh or open the app.
- Does not request `authorizedAlways` location. Only when-in-use.
- Does not access Contacts, Calendar, Photos, Microphone, Camera, HealthKit, or Motion data.
- Does not request push notification permission (M13 push was explicitly cut).
- Does not include analytics, crash-reporting, or advertising SDKs. The one third-party Swift package linked into the app is Apple's Apache-2.0 `swift-protobuf`, used solely by the Meshtastic tab to serialise the node's wire format.
- Does not access Bluetooth unless the user opens the Mesh tab. When they do, it is used solely to pair with a Meshtastic node — no general Bluetooth scanning, no beacon-based location, no advertising.

## Children's privacy

The app has no functionality intended for children, and no user-generated content. Age rating: 4+.

---

## App Store Privacy Questionnaire — exact answers

Apple's privacy questionnaire breaks data into categories. Here are the right answers as of v0.3.

**Do you or your third-party partners collect data from this app?**
**No.**

(Justification: location is read on-device and sent only to the public weather APIs above on the user's behalf. Apple's questionnaire defines "collect" as "transmit data off the device in a way that allows you to access it" — Spacetrucker Galactic never receives any of this data. The Meshtastic tab's Bluetooth traffic is local-only and never traverses any of our servers — there are no servers.)

If Apple's review insists on a more conservative answer because location is transmitted to third parties:

**Data Linked to You: Location > Precise Location**
- Used for **App Functionality**.
- Not used for tracking.

That is the maximum reasonable disclosure. All other categories: not collected.

### Bluetooth usage description (Info.plist)

The `NSBluetoothAlwaysUsageDescription` string shipped in the build:

> *"StatusGalactic uses Bluetooth to connect to your Meshtastic node and exchange mesh messages."*

This prompt is presented only when the user first opens the Mesh tab. The app does not scan for, advertise to, or connect to Bluetooth peripherals other than Meshtastic nodes.
