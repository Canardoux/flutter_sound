#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sound_web'
  s.version          = '7.8.4'
  s.summary          = 'No-op implementation of flutter_sound_web web plugin to avoid build issues on iOS'
  s.description      = <<-DESC
temp fake flutter_sound_web plugin
                       DESC
                       s.homepage         = s.homepage         = 'https://github.com/Canardoux/tau/flutter_sound_web'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Larpoux' => 'larpoux@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '10.0'
end
