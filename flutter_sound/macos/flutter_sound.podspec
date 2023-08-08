#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
s.name = 'flutter_sound'
  s.version          = '9.2.13'
  s.summary          = 'Flutter plugin that relates to sound like audio and recorder.'
  s.description      = <<-DESC
Flutter plugin that relates to sound like audio and recorder.
                       DESC
  s.homepage         = 'https://taudio-waa.thetatau.xyz/index.html'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Canardoux' => 'canardoux.xyz' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '11.4'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.frameworks = 'AVFoundation', 'MediaPlayer'

end
