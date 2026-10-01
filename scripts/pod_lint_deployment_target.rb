# Lint-only workaround for `pod lib lint` on Xcode 26+/27+.
#
# Some dependency podspecs (Alamofire, Japx, OAuthSwift) still declare iOS 9/10 deployment
# targets, which recent Xcode versions refuse to build. `pod lib lint` generates its own
# throwaway Podfile, so there is no post_install hook to raise them. This file patches the
# validator to add one, raising every pod target to at least the SDK's own minimum.
#
# Usage (see docs/DEVELOPMENT.md):
#   RUBYOPT="-rlogger -r./scripts/pod_lint_deployment_target.rb" pod lib lint BMXCore.podspec ...

require 'cocoapods'

module BMXPodLintDeploymentTarget
  MIN_IOS = '15.0'

  def podfile_from_spec(*args)
    podfile = super
    podfile.post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          current = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
          if current.nil? || Gem::Version.new(current) < Gem::Version.new(MIN_IOS)
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = MIN_IOS
          end
        end
      end
    end
    podfile
  end
end

Pod::Validator.prepend(BMXPodLintDeploymentTarget)
