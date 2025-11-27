#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint taudio.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sound'
  s.version          = '9.30.0'
  s.summary          = 'A complete api for audio playback and recording. Member of the `Tau` Family. Audio player, audio recorder. Pray for Ukraine.'
  s.description      = <<-DESC
A complete api for audio playback and recording. Member of the `Tau` Family. Audio player, audio recorder. Pray for Ukraine.
                       DESC
  s.homepage         = 'http://taudio.canardoux.xyz'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Canardoux' => 'larpoux@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'
  s.static_framework = true
  s.dependency 'flutter_sound_core', '9.30.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'taudio_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
