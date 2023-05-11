platform :ios, '13.0' #webrtc requeire 9 +
use_frameworks!

workspace 'ButterflyMXSDK'

target 'BMXCore' do
  project 'BMXCore.xcodeproj'
  pod 'Alamofire'
  pod 'OAuthSwift', '2.1.0'
  pod 'Japx/Alamofire'
end

target 'ButterflyMX Demo Internal' do
  project 'Submodules/ios-demo-app/ButterflyMX Demo.xcodeproj'
  pod 'Alamofire'
  pod 'SVProgressHUD'
  pod 'OAuthSwift', '2.1.0'
  pod 'TwilioVideo', '~> 5.1'
  pod 'Japx/Alamofire'
end

target 'BMXCall' do
  project 'BMXCall.xcodeproj'
  pod 'Alamofire'
  pod 'TwilioVideo', '~> 5.1'
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'YES'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end

