#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_sound_advanced.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sound_advanced'
  s.version          = '10.0.2'
  s.summary          = 'A complete api for audio playback and recording. Member of the `Tau` Family. Audio player, audio recorder. Pray for Ukraine.'
  s.description      = <<-DESC
A complete api for audio playback and recording. Member of the `Tau` Family. Audio player, audio recorder. Pray for Ukraine.
                       DESC
  s.homepage         = 'https://github.com/nafiskabbo/flutter_sound_advanced'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nafis Kabbo' => 'nafiskabbo30@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files = 'flutter_sound_advanced/Sources/flutter_sound_advanced/**/*'
  s.resource_bundles = {'flutter_sound_advanced_privacy' => ['flutter_sound_advanced/Sources/flutter_sound_advanced/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
