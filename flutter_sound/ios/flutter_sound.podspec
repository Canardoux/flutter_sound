#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
s.name = 'flutter_sound'
  s.version          = '7.6.4+2'
  s.summary          = 'Flutter plugin that relates to sound like audio and recorder.'
  s.description      = <<-DESC
Flutter plugin that relates to sound like audio and recorder.
                       DESC
  s.homepage         = 'https://github.com/dooboolab/flutter_sound/flutter_sound'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dooboolab' => 'dooboolab@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '10.0'
  s.static_framework = true
  s.dependency 'tau_sound_core', '7.6.4+2'
  s.dependency 'mobile-ffmpeg-full', '4.4.LTS'
end
