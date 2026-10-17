#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_sound_advanced.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sound_advanced'
  s.version          = '10.0.3'
  s.summary          = 'A complete api for audio playback and recording. Member of the `Tau` Family. Audio player, audio recorder. Free Palestine.'
  s.description      = <<-DESC
A complete api for audio playback and recording. Member of the `Tau` Family. Audio player, audio recorder. Free Palestine.
                       DESC
  s.homepage         = 'https://github.com/nafiskabbo/flutter_sound_advanced'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nafis Kabbo' => 'nafiskabbo30@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_sound_advanced/Sources/flutter_sound_advanced/**/*'
  s.public_header_files = 'flutter_sound_advanced/Sources/flutter_sound_advanced/include/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.ios.deployment_target = '13.0'
  s.static_framework = true
  s.dependency 'flutter_sound_core', '9.30.0'
  s.resource_bundles = {'flutter_sound_advanced_privacy' => ['flutter_sound_advanced/Sources/flutter_sound_advanced/PrivacyInfo.xcprivacy']}
end
