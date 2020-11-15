#!/bin/bash
if [ -z "$1" ]; then
        echo "Correct usage is $0 <Version>"
        exit -1
fi



VERSION=$1
VERSION_CODE=${VERSION//./}
VERSION_CODE=${VERSION_CODE//+/}


gsed -i  "s/^\( *s.version *= *\).*$/\1'$VERSION'/"                                     TauEngine.podspec
gsed -i  "s/^\( *s.dependency *'TauEngine', *\).*$/\1'$VERSION'/"                       flutter_sound/ios/flutter_sound.podspec
gsed -i  "s/^\( *versionName *\).*$/\1'$VERSION'/"                                      TauEngine/android/TauEngine/build.gradle
gsed -i  "s/^\( *versionCode *\).*$/\11$VERSION_CODE/"                                  TauEngine/android/TauEngine/build.gradle
gsed -i  "s/^\( *implementation 'xyz.canardoux:TauEngine:\).*$/\1$VERSION'/"            flutter_sound/android/build.gradle
gsed -i  "s/^\( *s.version *= *\).*$/\1'$VERSION'/"                                     flutter_sound/ios/flutter_sound.podspec
gsed -i  "s/^\( *version *\).*$/\1'$VERSION'/"                                          flutter_sound/android/build.gradle
gsed -i  "s/^\( *version: *\).*$/\1$VERSION/"                                           flutter_sound/pubspec.yaml
gsed -i  "s/^\( *flutter_sound_platform_interface: *#* *\).*$/\1$VERSION/"              flutter_sound/pubspec.yaml
gsed -i  "s/^\( *flauto_platform_interface: *#* *\).*$/\1$VERSION/"                     flutter_sound/pubspec.yaml
gsed -i  "s/^\( *flutter_sound_web: *#* *\).*$/\1$VERSION/"                             flutter_sound/pubspec.yaml
gsed -i  "s/^\( *flauto_web: *#* *\).*$/\1$VERSION/"                                    flutter_sound/pubspec.yaml
gsed -i  "s/^\( *version: *\).*$/\1$VERSION/"                                           flutter_sound/example/pubspec.yaml
gsed -i  "s/^\( *flutter_sound: *#* *\^*\).*$/\1$VERSION/"                              flutter_sound/example/pubspec.yaml
gsed -i  "s/^\( *#* *flutter_sound_platform_interface: *#* *\^*\).*$/\1$VERSION/"       flutter_sound/example/pubspec.yaml
gsed -i  "s/^\( *#* *flutter_sound_web: *#* *\^*\).*$/\1$VERSION/"                      flutter_sound/example/pubspec.yaml
gsed -i  "s/^\( *libraryVersion = \).*$/\1$VERSION/"                                    TauEngine/android/TauEngine/gradle.properties
gsed -i  "s/^\( *flutter_sound_lite: *#* *\^*\).*$/\1$VERSION/"                         flutter_sound/example/pubspec.yaml
gsed -i  "s/^\( *## \).*$/\1$VERSION/"                                                  flutter_sound/CHANGELOG.md
gsed -i  "s/^\( *## \).*$/\1$VERSION/"                                                  flutter_sound_platform_interface/CHANGELOG.md
gsed -i  "s/^\( *version: *\).*$/\1$VERSION/"                                           flutter_sound_platform_interface/pubspec.yaml
gsed -i  "s/^\( *version *= *\).*$/\1'$VERSION'/"                                       TauEngine/android/TauEngine/bintray.gradle
gsed -i  "s/^\( *version: *\).*$/\1$VERSION/"                                           flutter_sound_web/pubspec.yaml
gsed -i  "s/^\( *flutter_sound_platform_interface: *#* *\).*$/\1$VERSION/"              flutter_sound_web/pubspec.yaml
gsed -i  "s/^\( *flauto_platform_interface: *#* *\).*$/\1$VERSION/"                     flutter_sound_web/pubspec.yaml
gsed -i  "s/^\( *## \).*$/\1$VERSION/"                                                  flutter_sound_web/CHANGELOG.md
gsed -i  "s/^\( *\"version\": *\).*$/\1\"$VERSION\",/"                                  TauEngine/web/package.json
gsed -i  "s/^\( *<script src=\"https:\/\/cdn.jsdelivr.net\/npm\/tau_engine@\)[^\/]*/\1$VERSION/g" flutter_sound/example/web/index.html
gsed -i  "s/^\( *s\.version *= *\).*$/\1'$VERSION'/"                                    flutter_sound_web/ios/flutter_sound_web.podspec