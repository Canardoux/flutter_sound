#
# Be sure to run `pod lib lint flutter_engine.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'flutter_sound_core'
  s.version          = '9.4.7'
  s.summary          = 'Provides simple recorder and player functionalities for iOS platform.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This plugin provides simple recorder and player functionalities for both Android and iOS platforms.
This code was originally inside the flutter_sound/ios directory.
It has been extracted to be isolated from Flutter and can be used with other frameworks.
                       DESC

  s.homepage         = 'https://github.com/canardoux/flutter_sound/flutter_sound_web'
  s.license          = { :type => 'MPL2', :file => 'LICENSE' }
  s.author           = { 'larpoux' => 'larpoux@gmail.com' }
  s.source           = { :git => 'https://github.com/canardoux/flutter_sound_web.git', :tag => s.version}

  s.ios.deployment_target = '12.0'

  s.source_files = 'ios/Classes/*'
  s.frameworks = 'AVFoundation', 'MediaPlayer'


end
