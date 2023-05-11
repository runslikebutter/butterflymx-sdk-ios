# intercom-ios-sdk
Butterflymx intercom iOS SDK

Instruction:
1. Download SDK, run pod install to install dependencies.
2. Build for Generic iOS Device, get ButterflyMXSDK.framework.
3. Together with LICENSE file, pjsip headers(includes module map) and static lib, zip the framework and upload to a public accessible git repository.
4. Upload a podspec file to the repository for CocoaPods use.
5. From the demo app, add 'ButterflyMXSDK' to the Podfile, import ButterflyMXSDK, all the API functions should be able to use by the app.


API Functions:

BMXCore.shared.loginUser(email, password) { (accessToken, refreshToken, error) }

BMXCore.shared.logoutUser()

BMXCore.shared.registerPushNotification()

BMXCall.shared.getCallInfo(payload) { (error) }

BMXCall.shared.previewCall(guid)

BMXCall.shared.answerCall()

BMXCall.shared.hangupCall()

BMXCall.shared.umuteMic()

BMXCall.shared.muteMic()

BMXCall.shared.turnOnSpeaker()

BMXCall.shared.turnOffSpeaker()

BMXCall.shared.showOutgoingVideo()

BMXCall.shared.hideOutgoingVideo()


Also conform to BMXCoreDelegate, BMXCallDelegate, to get logging functionality and other callbacks.

