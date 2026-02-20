# ButterflyMX iOS SDK — Developer Guide

Internal reference for building, maintaining, and releasing the SDK.

---

## Repository Structure

```
butterflymx-sdk-ios/
├── BMXCore/              # Authentication, user data, door control, webhooks
│   ├── Auth/
│   ├── Environment/
│   ├── Models/
│   └── Utils/
├── BMXCall/              # Twilio WebRTC video call handling
│   ├── CallProcessors/
│   │   └── WebRTC/
│   ├── Models/
│   └── Helpers/
├── BMXLiveView/          # Live view component
├── Submodules/
│   └── ios-demo-app/     # Partner-facing demo application
├── Package.swift         # SPM manifest (used by partners and as source of truth for deps)
├── BMXCore.xcodeproj     # Xcode project for BMXCore — used by the workspace
├── BMXCall.xcodeproj     # Xcode project for BMXCall — used by the workspace
├── ButterflyMXSDK.xcworkspace  # Development workspace (SDK + demo app)
└── docs/
    └── DEVELOPMENT.md    # This file
```

## Project Setup

### Prerequisites

- Xcode 14+
- Swift 5.7+
- Git with LFS if large binaries are ever added

### Clone

```bash
git clone --recurse-submodules https://github.com/runslikebutter/butterflymx-sdk-ios.git
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

### Open in Xcode

Open `ButterflyMXSDK.xcworkspace` — it includes `BMXCore`, `BMXCall`, and the demo app submodule together, making it the best option for development and integration testing.

Alternatively, open `Package.swift` directly if you only need to work on the SDK packages in isolation.

---

## Dependencies

| Package | Used by | Purpose |
|---|---|---|
| Alamofire `5.6.1 ..< 5.10.0` | BMXCore | HTTP networking |
| OAuthSwift `~> 2.2` | BMXCore | OAuth2 flow |
| Japx `~> 4.0` | BMXCore | JSON:API decoding |
| TwilioVideo `~> 5.8` | BMXCall | WebRTC video calls |

Dependency versions are defined in `Package.swift`. When upgrading, test against the demo app before releasing.

> **Important:** `BMXCore.xcodeproj` has its own SPM dependency declarations (used when opening via `ButterflyMXSDK.xcworkspace`). When changing a dependency version in `Package.swift`, update the matching constraint in `BMXCore.xcodeproj` too, otherwise the workspace will resolve a different version than `Package.swift`.

---

## Build

### SPM (Xcode)

1. Open `Package.swift` in Xcode
2. Select the `BMXCore` or `BMXCall` scheme
3. Build with ⌘B

### SPM (CLI)

```bash
swift build
```

---

## Demo App

The demo app lives in `Submodules/ios-demo-app`. It is a separate repository added as a git submodule and is the primary integration testing environment.

```bash
cd Submodules/ios-demo-app
open DemoApp.xcworkspace   # adjust name as needed
```

To update the submodule to its latest commit:

```bash
git submodule update --remote Submodules/ios-demo-app
git add Submodules/ios-demo-app
git commit -m "chore: update demo app submodule"
```

---

## Versioning

The SDK uses **SPM with git tags** — a single tag versions both `BMXCore` and `BMXCall` together, since SPM resolves at the repository level rather than per-package.

The SDK follows **semantic versioning** (`MAJOR.MINOR.PATCH`). Current series is `2.x`.

- **PATCH** — bug fixes, non-breaking changes
- **MINOR** — new public API additions, backward-compatible
- **MAJOR** — breaking API changes

Current latest: **v2.3.7**

---

## Release Process

### 1. Merge to `main`

Ensure all changes are merged to `main` and CI is green.

### 2. Tag the release

Tags must use the format `vX.Y.Z` — this is what SPM resolves against.

```bash
git tag v2.3.8
git push origin v2.3.8
```

SPM consumers using `.upToNextMajor(from: "2.3.7")` will pick up the new tag automatically.

### 3. GitHub Release (optional but recommended)

Create a GitHub Release from the tag with a changelog summary. Helps partners track what changed between versions.

---

## Key Architecture Notes

- **Singletons**: `BMXCoreKit.shared`, `BMXUser.shared`, `BMXDoor.shared`, `BMXCallKit.shared` — all entry points are singletons
- **Async pattern**: The SDK uses a custom `Future<Value>` / `Promise<Value>` implementation (`FutureKit.swift`) rather than `async/await`; public API surfaces use completion handlers
- **Token storage**: OAuth tokens are stored in Keychain via `BMXAuthProvider` + `Keychain.swift`
- **Disk caching**: User/tenant data is persisted to disk between sessions via `DiskCaching.swift`
- **OAuth token refresh**: Handled transparently by `OAuth2Handler` (an Alamofire `RequestInterceptor`) — it intercepts 401 responses and retries after refreshing
- **Call state machine**: `BMXCall` uses `SimpleStateMachine.swift` to manage call states; Twilio integration is in `TwilioIncomingCallProcessor.swift`
- **Multi-region**: The SDK supports NA and EU regions; the region is determined after login via `getUserRegion()` and persisted in `UserDefaults` via `BMXEnvironment`

---

## Common Pitfalls

**Wrong region after login**: `BMXEnvironment` persists the region to `UserDefaults`. If a test account switches regions, clear `UserDefaults` or call `logoutUser()` to reset.

**`getPanels` deprecation**: `TenantModel.panels` and `BMXUser.getPanels(from:)` are deprecated. Use `devices`/`getDevices(from:)` instead. Don't add new code using the panels API.

**Twilio binary size**: `TwilioVideo` is a large binary XCFramework. This affects app size for partners — mention it in partner communications when relevant.

**Submodule state**: After pulling, always check `git submodule status` — a `+` prefix means the submodule is ahead of what's recorded in the parent repo.
