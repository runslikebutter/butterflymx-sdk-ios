# ButterflyMX iOS SDK

The ButterflyMX iOS SDK enables partners to integrate ButterflyMX video call and access control functionality into their iOS applications. Partners can authenticate residents, manage building/unit data, handle incoming video calls from ButterflyMX panels, and trigger door releases.

## Requirements

| Requirement | Minimum |
|---|---|
| iOS | 13.0+ |
| Swift | 5.0+ |
| Xcode | 14.0+ |

## Modules

| Module | Description |
|---|---|
| **BMXCore** | Authentication, user/tenant data, door control, webhooks |
| **BMXCall** | Incoming video call handling via Twilio WebRTC |

## Installation

### Swift Package Manager — Package.swift

Add the package as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/runslikebutter/butterflymx-sdk-ios.git", .upToNextMajor(from: "2.3.7"))
],
```

Then add the products to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "BMXCore", package: "butterflymx-sdk-ios"),
        .product(name: "BMXCall", package: "butterflymx-sdk-ios")
    ]
)
```

### Swift Package Manager — Xcode

1. In Xcode, go to **File > Add Package Dependencies...**
2. Paste the repository URL: `https://github.com/runslikebutter/butterflymx-sdk-ios.git`
3. Select version **2.3.7** or **Up to Next Major Version**
4. Select both **BMXCore** and **BMXCall** packages
5. Click **Add Package**

## App Permissions

Add the following keys to your app's `Info.plist`. Without them, the app will crash when the SDK attempts to access camera or microphone.

```xml
<key>NSCameraUsageDescription</key>
<string>Used for video calls with the building panel</string>

<key>NSMicrophoneUsageDescription</key>
<string>Used for audio during video calls with the building panel</string>
```

## Getting Started

### 1. Configure the SDK

Call `configure` early in your app lifecycle (e.g., `AppDelegate.application(_:didFinishLaunchingWithOptions:)`):

```swift
import BMXCore

BMXCoreKit.shared.configure(withEnvironment: BMXEnvironment(backendEnvironment: .production), logger: nil)
```

To receive SDK log output, implement `BMXCoreDelegate` and set it as the delegate separately:

```swift
class MyLogger: BMXCoreDelegate {
    func logging(_ data: String) {
        print("[BMX] \(data)")
    }
    func didCancelAuthorization() {
        // User cancelled the OAuth login flow
    }
}

BMXCoreKit.shared.configure(withEnvironment: BMXEnvironment(backendEnvironment: .production), logger: nil)
BMXCoreKit.shared.delegate = myLogger
```

### 2. Handle OAuth Callback URL

If you use the built-in OAuth2 browser flow, register a URL scheme in your app and forward callbacks:

```swift
// AppDelegate or SceneDelegate
func application(_ app: UIApplication, open url: URL, options: [...]) -> Bool {
    return BMXCoreKit.shared.handle(url: url)
}
```

## Authentication

### Option A — OAuth2 Browser Flow (recommended for end-user login)

Presents a Safari view controller for the ButterflyMX OAuth2 login page:

```swift
let authProvider = BMXAuthProvider(secret: "YOUR_CLIENT_SECRET", clientID: "YOUR_CLIENT_ID")

BMXCoreKit.shared.authorize(
    withAuthProvider: authProvider,
    callbackURL: URL(string: "yourapp://oauth-callback")!,
    viewController: self,
    promptLogin: true   // set false to skip login prompt if session exists
) { result in
    switch result {
    case .success:
        // User is authenticated; tokens are stored in Keychain
    case .failure(let error):
        print("Auth failed: \(error)")
    }
}
```

### Option B — Existing Tokens

If you already have valid OAuth tokens (e.g., obtained server-side):

```swift
let authProvider = BMXAuthProvider(
    secret: "YOUR_CLIENT_SECRET",
    clientID: "YOUR_CLIENT_ID",
    accessToken: "ACCESS_TOKEN",
    refreshToken: "REFRESH_TOKEN"
)

BMXCoreKit.shared.authorize(withAuthProvider: authProvider) { result in
    switch result {
    case .success:
        // Tokens accepted; SDK is ready
    case .failure(let error):
        print("Auth failed: \(error)")
    }
}
```

### Check Login Status

```swift
if BMXCoreKit.shared.isUserLoggedIn {
    // Proceed to load user data
}
```

### Refresh Access Token

```swift
BMXCoreKit.shared.refreshAccessToken { result in
    switch result {
    case .success:
        // Token refreshed
    case .failure(let error):
        print("Refresh failed: \(error)")
    }
}
```

### Logout

```swift
BMXCoreKit.shared.logoutUser()
```

## User & Tenant Data

### Fetch User Data

After authentication, reload user data (tenants, units, devices):

```swift
BMXCoreKit.shared.reloadUserData { result in
    switch result {
    case .success:
        let user = BMXUser.shared.getUser()
        let tenants = BMXUser.shared.getTenants()
    case .failure(let error):
        print("Failed to load user: \(error)")
    }
}
```

### Access Tenants and Devices

```swift
let tenants = BMXUser.shared.getTenants()

for tenant in tenants {
    print("Unit: \(tenant.unit?.label ?? "—")")
    print("Building: \(tenant.building?.id ?? "—")")

    let devices = BMXUser.shared.getDevices(from: tenant)
    for device in devices {
        print("Device: \(device.name ?? device.id)")
    }
}
```

> **Note:** `getPanels(from:)` is deprecated. Use `getDevices(from:)` instead.

## Door Release

Open a door (e.g., from a panel/device in a tenant):

```swift
let tenant = BMXUser.shared.getTenants().first!
let device = BMXUser.shared.getDevices(from: tenant).first!

BMXDoor.shared.openDoor(device: device, tenant: tenant, method: .frontDoorView) { result in
    switch result {
    case .success:
        print("Door opened")
    case .failure(let error):
        print("Door release failed: \(error)")
    }
}
```

`OpenDoorMethod` options:
- `.frontDoorView` — standard remote door release
- `.bluetooth` — Bluetooth-based release (when supported)

## Video Calls (BMXCall)

The `BMXCall` module handles incoming video calls from ButterflyMX panels over Twilio WebRTC.

### Setup

Assign delegates before processing any call:

```swift
import BMXCall

// Receives call lifecycle events
BMXCallKit.shared.callStatusDelegate = self

// Your view controller that renders the call UI
BMXCallKit.shared.incomingCallPresenter = myCallViewController
```

### Process an Incoming Call

When a push notification arrives with a ButterflyMX call, extract the `guid` and call type, then:

```swift
BMXCallKit.shared.processCall(guid: callGuid, callType: "incoming") { result in
    switch result {
    case .success:
        // Call is ready; present your call UI
    case .failure(let error):
        print("Call setup failed: \(error)")
    }
}
```

### Call Controls

```swift
BMXCallKit.shared.answerCall()          // Accept the incoming call
BMXCallKit.shared.endCall()             // Hang up

BMXCallKit.shared.connectSoundDevice()     // Activate audio session
BMXCallKit.shared.disconnectSoundDevice()  // Deactivate audio session

BMXCallKit.shared.muteMic()            // Mute microphone
BMXCallKit.shared.unmuteMic()          // Unmute microphone

BMXCallKit.shared.turnOnSpeaker()      // Route audio to speaker
BMXCallKit.shared.turnOffSpeaker()     // Route audio to earpiece

BMXCallKit.shared.showOutgoingVideo()  // Enable front camera
BMXCallKit.shared.hideOutgoingVideo()  // Disable front camera

// Open door during an active call
BMXCallKit.shared.openDoor { result in
    // handle result
}
```

### Call Status Delegate

Implement `CallStatusDelegate` to respond to call lifecycle events:

```swift
extension MyCallViewController: CallStatusDelegate {
    func callConnected() {
        // WebRTC connection established
    }

    func callAccepted(from call: Call, usingCallKit: Bool) {
        // Resident accepted the call; use call.panelName to get the panel name
    }

    func callCanceled(callId: String, reason: CallCancelReason, usingCallKit: Bool) {
        // Call was canceled before answer (reason: timeout, panel hung up, etc.)
        dismissCallUI()
    }

    func callEnded(callId: String, usingCallKit: Bool) {
        // Call ended after being answered
        dismissCallUI()
    }
}
```

### Incoming Call UI Protocol

Implement `IncomingCallUIInputs` on your call view controller to provide video rendering surfaces and respond to BMXCallKit's UI lifecycle callbacks:

```swift
extension MyCallViewController: IncomingCallUIInputs {
    var delegate: (IncomingCallUIDelegate & IncomingCallUIDataSource)? {
        return self
    }

    func setupWaitingForAnsweringCallUI() {
        // Configure your UI for the ringing/waiting state
    }

    func getInputVideoViewSize() -> CGSize {
        return remoteVideoView.bounds.size   // panel's outgoing video
    }

    func getOutputVideoViewSize() -> CGSize {
        return localVideoView.bounds.size    // resident's front camera
    }

    func displayIncomingVideo(from videoView: UIView) {
        remoteVideoContainer.addSubview(videoView)
    }

    func displayOutgoingVideo(from videoView: UIView) {
        localVideoContainer.addSubview(videoView)
    }

    func updateSpeakerControlStatus() { /* refresh speaker button */ }
    func updateMicrophoneControlStatus() { /* refresh mic button */ }
    func updateCameraControlStatus() { /* refresh camera button */ }
}
```

Also implement `IncomingCallUIDelegate` (user actions) and `IncomingCallUIDataSource` (UI state) on the same object:

```swift
extension MyCallViewController: IncomingCallUIDelegate {
    func pressCallAccept() { BMXCallKit.shared.answerCall() }
    func pressCallDecline() { BMXCallKit.shared.endCall() }
    func pressCallHungup() { BMXCallKit.shared.endCall() }
    func toggleFrontCamera() { /* toggle showOutgoingVideo */ }
    func toggleSpeaker() { /* toggle turnOnSpeaker/turnOffSpeaker */ }
    func toggleMicrophone() { /* toggle muteMic/unmuteMic */ }
    func pressOpenDoor(completion: @escaping (Result<Void, Error>) -> Void) {
        BMXCallKit.shared.openDoor(completion: completion)
    }
    func proximityChange(value: Bool) { /* handle proximity sensor */ }
}

extension MyCallViewController: IncomingCallUIDataSource {
    var speakerEnabled: Bool { /* current speaker state */ }
    var micEnabled: Bool { /* current mic state */ }
    var cameraEnabled: Bool { /* current camera state */ }
    var openDoorEnabled: Bool { BMXCallKit.shared.activeCall != nil }
    var currentCall: Call? { BMXCallKit.shared.activeCall }
    var currentPanelName: String? { BMXCallKit.shared.activeCall?.panelName }
    var currentPanelId: Int? { BMXCallKit.shared.activeCall?.panelId }
    var incomingVideoView: UIView? { remoteVideoContainer }
    var outgoingVideoView: UIView? { localVideoContainer }
}
```

## Webhooks

Register a webhook to receive push notifications for incoming calls:

```swift
BMXCoreKit.shared.registerWebhook(withTenantId: tenantId, urlString: "https://your-server.com/webhook") { result in
    switch result {
    case .success(let webhookId):
        print("Registered webhook: \(webhookId)")
    case .failure(let error):
        print("Registration failed: \(error)")
    }
}
```

Unregister when no longer needed:

```swift
BMXCoreKit.shared.unregisterWebhook(withTenantId: tenantId, webhookId: webhookId) { result in
    // handle result
}
```

## Environments

By default the SDK targets the **development** environment. Always configure with `.production` in release builds:

```swift
BMXCoreKit.shared.configure(withEnvironment: BMXEnvironment(backendEnvironment: .production), logger: nil)
```

To target a different environment:

```swift
BMXCoreKit.shared.configure(withEnvironment: BMXEnvironment(backendEnvironment: .development), logger: nil)
// or .sandbox, .production
```

| Environment | Description |
|---|---|
| `.production` | Live production API |
| `.development` | Staging/test API |
| `.sandbox` | Sandbox API (NA region) |

The SDK automatically routes requests to the correct regional endpoint (NA or EU) based on the authenticated user's account.

## License

Copyright 2024–present ButterflyMX

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
