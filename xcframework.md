BMX XCFramework supports the following architectures:
Device - armv7, arm64
Simulator - x86_64

**How to Install BMXCall and BMXCore XCFrameworks using Cocoapods**

1. Add the following to your Podfile (inside the target section):

```
pod "BMXCall", '~> 1.0.12'
pod 'Japx/CodableAlamofire', :git => 'https://github.com/runslikebutter/Japx'
```

Until `Japx/CodableAlamofire` BMX dependency original repo is not updated with support of XCFramework you must use our fork with a fix.

2. Add the following to the bottom of your Podfile:

```
post_install do |installer|
    installer.pods_project.targets.each do |target|
      if ['BMXCall', 'BMXCore', 'Alamofire', 'Japx', 'OAuthSwift'].include? target.name
        target.build_configurations.each do |config|
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        end
      end
    end
end
```

**MODULE STABILITY WORKAROUND**: You must add this code, because BMXCall and BMXCore support module stability, but it is not directly supported in Cocoapods. This code will manually enable module stability for all of BMX's dependencies.

3. Run `pod install`

**Possible issues:**

1. "No such module `BMXCore` or `BMXCall`" compile error when building for simulator.
Xcode tries to find new arm64 arch for simulators in sdk but for now we do not support it, to fix the error you need to exclude arm64 arch for simulator sdk in the projects target build settings like on the image below.

2. "`BMXCall` does not contain bitcode. You must rebuild it with bitcode enabled"
`BMXCall` does not support bitcode, disable Bitcode target build settings.

3. Module `BMXCore` has no member named `shared`, Module `BMXCall` has no member named `shared`
In xcode 12 a class/struct in the framework can not has the same name as the framework, so
`BMXCore` class was renamed to `BMXCoreKit`
`BMXCall` class was renamed to `BMXCallKit`
