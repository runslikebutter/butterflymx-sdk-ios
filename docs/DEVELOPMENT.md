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
| Alamofire `5.6.1 ..< 6.0.0` | BMXCore | HTTP networking |
| OAuthSwift `~> 2.2` | BMXCore | OAuth2 flow |
| Japx `~> 4.0` (core module only) | BMXCore | JSON:API decoding |
| TwilioVideo `~> 5.8` | BMXCall | WebRTC video calls |

Dependency versions are defined in `Package.swift`. When upgrading, test against the demo app before releasing.

> **Note:** Japx 4.0.1's `JapxAlamofire` module doesn't compile with Alamofire 5.10+, and the upstream fix is unreleased. BMXCore therefore depends only on the Japx core module and vendors the `responseCodableJSONAPI` helper in `BMXCore/Vendor/JapxCodableAlamofire.swift`. Once Japx ships a release with the fix, this file can be replaced by the `JapxAlamofire` product again. [MT-3128](https://butterflymx.atlassian.net/browse/MT-3128) tracks the full revert, including raising the Japx minimum to the fixed release.

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

### CocoaPods lint

Some dependency podspecs (Alamofire, Japx, OAuthSwift) still declare iOS 9/10 deployment targets, which Xcode 26+ refuses to build. `scripts/pod_lint_deployment_target.rb` raises them to iOS 15.0 inside the throwaway project `pod lib lint` generates; it does not affect consumers.

```bash
LANG=en_US.UTF-8 RUBYOPT="-rlogger -r./scripts/pod_lint_deployment_target.rb" pod lib lint BMXCore.podspec --allow-warnings --skip-tests
LANG=en_US.UTF-8 RUBYOPT="-rlogger -r./scripts/pod_lint_deployment_target.rb" pod lib lint BMXCall.podspec --include-podspecs=BMXCore.podspec --allow-warnings --skip-tests
```

`-rlogger` works around an `activesupport` `Logger` load error in some CocoaPods installs. `--include-podspecs` lints `BMXCall` against the local `BMXCore` rather than the published one.

### Minimum iOS version

The minimum is **iOS 15.0** (the lowest Xcode 27 accepts). When changing it, keep these in sync: `Package.swift` (`platforms`), both `.podspec` files (`spec.ios.deployment_target`), `IPHONEOS_DEPLOYMENT_TARGET` in `BMXCore.xcodeproj` and `BMXCall.xcodeproj`, and the Requirements table in `README.md`. Raising it is a breaking change for consumers: it requires a MAJOR version bump (see [Versioning](#versioning)) and must be called out in the release notes.

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

The SDK follows **semantic versioning** (`MAJOR.MINOR.PATCH`). Current series is `3.x`.

- **PATCH** — bug fixes, non-breaking changes
- **MINOR** — new public API additions, backward-compatible
- **MAJOR** — breaking API changes, or raising the minimum iOS version

Current latest: **v3.0.0**

---

## Release Process

### 1. Merge to `main`

Ensure all changes are merged to `main` and CI is green.

### 2. Tag the release

Tags must use the format `vX.Y.Z` — this is what SPM resolves against.

```bash
git tag v3.0.1
git push origin v3.0.1
```

SPM consumers using `.upToNextMajor(from: "3.0.0")` will pick up new `3.x` tags automatically. A new MAJOR version is only picked up once they update their requirement.

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
