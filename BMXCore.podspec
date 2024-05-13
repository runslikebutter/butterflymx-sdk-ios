Pod::Spec.new do |spec|

  spec.name         = "BMXCore"
  spec.version      = "2.3.6"
  spec.swift_versions = ['5']

  spec.cocoapods_version = '>= 1.13.0'
  spec.ios.deployment_target = '14.0'

  spec.summary      = 'A Swift framework to implement ButterflyMX SDK'
  spec.homepage     = "https://github.com/runslikebutter/butterflymx-sdk-ios"

  spec.license      = "Apache-2.0 license"
  spec.author       = { "ButterflyMX" => "admin@butterflymx.com" }
  spec.source       = { :git => "https://github.com/runslikebutter/butterflymx-sdk-ios.git", :tag => 'v' + spec.version.to_s }

  spec.source_files  = "BMXCore/**/*.swift"

  spec.dependency 'Japx/Alamofire'
  spec.dependency 'Alamofire', '~> 5.2'
  spec.dependency 'OAuthSwift', '~> 2.1'

  spec.resource_bundles = {'BMXCore' => ['BMXCore/PrivacyInfo.xcprivacy']}

end
