#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
s.name = 'flutter_sound'
  s.version          = '9.23.0'
  s.summary          = 'Flutter plugin that relates to sound like audio and recorder.'
  s.description      = <<-DESC
Flutter plugin that relates to sound like audio and recorder.
                       DESC
  s.homepage         = 'https://taudio-waa.thetatau.xyz/index.html'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Canardoux' => 'larpoux@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '12.0'
  s.static_framework = true
  s.dependency 'flutter_sound_core', '9.23.0'
end
