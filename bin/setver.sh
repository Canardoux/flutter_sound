#!/bin/bash
if [ -z "$1" ]; then
        echo "Correct usage is $0 <Version>"
        exit -1
fi



VERSION=$1
VERSION_CODE=${VERSION//./}
VERSION_CODE=${VERSION_CODE//+/}



gsed -i  "s/^\( *\/* *implementation 'com.github.canardoux:flutter_sound_core:\).*$/\1$VERSION'/"             android/build.gradle


gsed -i  "s/^\( *version *\).*$/\1'$VERSION'/"                                          android/build.gradle

gsed -i  "s/^\( *s.version *= *\).*$/\1'$VERSION'/"                                     ios/flutter_sound.podspec 2>/dev/null
gsed -i  "s/^\( *s.dependency *'flutter_sound_core', *\).*$/\1'$VERSION'/"                        ios/flutter_sound.podspec 2>/dev/null

gsed -i  "s/^\( *version: *\).*$/\1$VERSION/"                                           pubspec.yaml
gsed -i  "s/^\( *flutter_sound_platform_interface: *#* *\).*$/\1$VERSION/"              pubspec.yaml
gsed -i  "s/^\( *flutter_sound_web: *#* *\).*$/\1$VERSION/"                             pubspec.yaml


gsed -i  "s/^\( *version: *\).*$/\1$VERSION/"                                           example/pubspec.yaml
gsed -i  "s/^\( *flutter_sound: *#* *\^*\).*$/\1$VERSION/"                              example/pubspec.yaml
gsed -i  "s/^\( *#* *flutter_sound_platform_interface: *#* *\^*\).*$/\1$VERSION/"       example/pubspec.yaml
gsed -i  "s/^\( *#* *flutter_sound_web: *#* *\^*\).*$/\1$VERSION/"                      example/pubspec.yaml



gsed -i  "s/^\( *## \).*$/\1$VERSION/"                                                  ../flutter_sound_platform_interface/CHANGELOG.md
gsed -i  "s/^\( *## \).*$/\1$VERSION/"                                                  ../flutter_sound_web/CHANGELOG.md
gsed -i  "s/^\( *## \).*$/\1$VERSION/"                                                  ../flutter_sound/CHANGELOG.md

gsed -i  "s/^\( *version: *\).*$/\1$VERSION/"                                           ../flutter_sound_platform_interface/pubspec.yaml
gsed -i  "s/^\( *version *= *\).*$/\1'$VERSION'/"                                       ../flutter_sound_core/android/bintray.gradle 2>/dev/null
gsed -i  "s/^\( *version: *\).*$/\1$VERSION/"                                           ../flutter_sound_web/pubspec.yaml
gsed -i  "s/^\( *flutter_sound_platform_interface: *#* *\).*$/\1$VERSION/"              ../flutter_sound_web/pubspec.yaml
gsed -i  "s/^\( *## \).*$/\1$VERSION/"                                                  ../flutter_sound_web/CHANGELOG.md
gsed -i  "s/^\( *\"version\": *\).*$/\1\"$VERSION\",/"                                  ../flutter_sound_web/package.json
gsed -i  "s/^\( *s\.version *= *\).*$/\1'$VERSION'/"                                    ../flutter_sound_core/flutter_sound_core.podspec

gsed -i  "s/^title: Flutter Sound - .*$/title: Flutter Sound - $VERSION/"               ../fs-doc/index.md
gsed -i  "s/^title: Flutter Sound - .*$/title: Flutter Sound - $VERSION/"               ../fs-doc/bin/cp.sh

gsed -i  "s/^const version = .*$/const version = '$VERSION';/"                example/lib/main.dart