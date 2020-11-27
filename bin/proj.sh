#!/bin/bash


if [ "_$1" = "_TAU" ] ; then
        echo 'Tau project'
        echo '-----------'
        gsed -i  "s/^\( *name: \).*$/\1flauto/" flutter_sound/pubspec.yaml
        gsed -i  "s/^ *flutter_sound_platform_interface: \(.*\)$/  flauto_platform_interface: \1/" flutter_sound/pubspec.yaml
        gsed -i  "s/^ *flutter_sound_web: \(.*\)$/  flauto_web: \1/" flutter_sound/pubspec.yaml
        gsed -i  "s/^\( *name: \).*$/\1flauto_platform_interface/" flutter_sound_platform_interface/pubspec.yaml
        gsed -i  "s/^\( *name: \).*$/\1flauto_web/" flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *flutter_sound_platform_interface: \(.*\)$/  flauto_platform_interface: \1/" flutter_sound_web/pubspec.yaml
        mv  tau_sound_core.podspec  tau_core.podspec 2>/dev/null
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/g" tau_core.podspec
        gsed -i  "s/^\( *s.name *= *\)'tau_sound_core'$/\1'tau_core'/" tau_core.podspec
        gsed -i  "s/^\( *rootProject.name = \).*$/\1'tau_core'/" tau_core/android/settings.gradle
        gsed -i  "s/^\( *libraryName = \).*$/\1tau_core/" tau_core/android/gradle.properties
        gsed -i  "s/^\( *PUBLISH_ARTIFACT_ID = \).*$/\1'tau_core'/" tau_core/android/build.gradle
        gsed -i  "s/^\( *artifactId = \).*$/\1'tau_core'/" tau_core/android/build.gradle
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" tau_core/android/bintray.gradle


        gsed -i  "s/^ *flutter_sound: \(.*\)$/  flauto: \1/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *#* *\)flutter_sound_platform_interface/\1flauto_platform_interface/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *#* *\)flutter_sound_web/\1flauto_web/" flutter_sound/example/pubspec.yaml
        mv flutter_sound/ios/flutter_sound.podspec flutter_sound/ios/flauto.podspec 2>/dev/null
        mv flutter_sound/ios/flutter_sound_lite.podspec flutter_sound/ios/flauto_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound'$/\1'flauto'/" flutter_sound/ios/flauto.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound_lite'$/\1'flauto_lite'/" flutter_sound/ios/flauto.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound'$/\1'flauto'/" flutter_sound/ios/flauto_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound_lite'$/\1'flauto_lite'/" flutter_sound/ios/flauto.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound_lite'$/\1'flauto_lite'/" flutter_sound/ios/flauto_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *rootProject.name *= *\).*$/\1'flauto'/" flutter_sound/android/settings.gradle
        gsed -i  "s/^\( *\"name\": \)\"tau_sound_core\"/\1\"tau_core\"/" tau_core/web/package.json
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound\.git/https:\/\/github.com\/canardoux\/tau\.git/" tau_core/web/package.json

        gsed -i  "s/^pod 'tau_sound_core',/pod 'tau_core',/" flutter_sound/example/ios/Podfile

        for f in $(find flutter_sound -name '*.dart' ); do gsed -i  "s/package\:flutter_sound/package:flauto/" $f; done
        for f in $(find flutter_sound -name '*.md' )
                gsed -i  "s/https:\/\/dooboolab.github.io\/flutter_sound/https:\/\/canardoux.github.io\/tau/" $f
                gsed -i  "s/https:\/\/pub.dartlang.org\/packages\/flutter_sound/https:\/\/pub.dartlang.org\/packages\/flauto/" $f
                gsed -i  "s/https:\/\/img.shields.io\/pub\/v\/flutter_sound.svg/https:\/\/img.shields.io\/pub\/v\/flauto.svg/" $f
         do gsed -i  "s/package\:flutter_sound/package:flauto/" $f;
         done


        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" flutter_sound/pubspec.yaml
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" flutter_sound_web/pubspec.yaml
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" flutter_sound_platform_interface/pubspec.yaml

        gsed -i  "s/https:\/\/dooboolab.github.io\/flutter_sound/https:\/\/canardoux.github.io\/tau/"   doc/SUMMARY.md
        gsed -i  "s/https:\/\/dooboolab.github.io\/flutter_sound/https:\/\/canardoux.github.io\/tau/"   doc/README.md


        for f in $(find doc -name '*.md' )
        do
                        gsed -i  "s/https:\/\/dooboolab.github.io\/flutter_sound/https:\/\/canardoux.github.io\/tau/"   $f
                        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" $f
        done

        exit 0

#========================================================================================================================================================================================================


elif [ "_$1" = "_FLUTTER_SOUND" ]; then
        echo 'Flutter Sound Project'
        echo '---------------------'
        gsed -i  "s/^\( *name: \).*$/\1flutter_sound/" flutter_sound/pubspec.yaml
        gsed -i  "s/^ *flauto_platform_interface: \(.*\)$/  flutter_sound_platform_interface: \1/" flutter_sound/pubspec.yaml
        gsed -i  "s/^ *flauto_web: \(.*\)$/  flutter_sound_web: \1/" flutter_sound/pubspec.yaml
        gsed -i  "s/^\( *name: \).*$/\1flutter_sound_platform_interface/" flutter_sound_platform_interface/pubspec.yaml
        gsed -i  "s/^\( *name: \).*$/\1flutter_sound_web/" flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *flauto_platform_interface: \(.*\)$/  flutter_sound_platform_interface: \1/" flutter_sound_web/pubspec.yaml
        mv  tau_core.podspec  tau_sound_core.podspec 2>/dev/null
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/g" tau_sound_core.podspec
        gsed -i  "s/^\( *s.name *= *\)'tau_core'$/\1'tau_sound_core'/" tau_sound_core.podspec
        gsed -i  "s/^\( *rootProject.name = \).*$/\1'tau_sound_core'/" tau_core/android/settings.gradle
        gsed -i  "s/^\( *libraryName = \).*$/\1tau_sound_core/" tau_core/android/gradle.properties
        gsed -i  "s/^\( *PUBLISH_ARTIFACT_ID = \).*$/\1'tau_sound_core'/" tau_core/android/build.gradle
        gsed -i  "s/^\( *artifactId = \).*$/\1'tau_sound_core'/" tau_core/android/build.gradle
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/" tau_core/android/bintray.gradle


        gsed -i  "s/^ *flauto: \(.*\)$/  flutter_sound: \1/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *#* *\)flauto_platform_interface/\1flutter_sound_platform_interface/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *#* *\)flauto_web/\1flutter_sound_web/" flutter_sound/example/pubspec.yaml
        mv flutter_sound/ios/flauto.podspec flutter_sound/ios/flutter_sound.podspec 2>/dev/null
        mv flutter_sound/ios/flauto_lite.podspec flutter_sound/ios/flutter_sound_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flauto'$/\1'flutter_sound'/" flutter_sound/ios/flutter_sound.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flauto_lite'$/\1'flutter_sound_lite'/" flutter_sound/ios/flutter_sound.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flauto'$/\1'flutter_sound'/" flutter_sound/ios/flutter_sound_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flauto_lite'$/\1'flutter_sound_lite'/" flutter_sound/ios/flutter_sound_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *rootProject.name *= *\).*$/\1'flutter_sound'/" flutter_sound/android/settings.gradle
        gsed -i  "s/^\( *\"name\": \)\"tau_core\"/\1\"tau_sound_core\"/" tau_core/web/package.json
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau\.git/https:\/\/github.com\/dooboolab\/flutter_sound\.git/" tau_core/web/package.json

        gsed -i  "s/^pod 'tau_core',/pod 'tau_sound_core',/" flutter_sound/example/ios/Podfile

        for f in $(find flutter_sound -name '*.dart' ); do gsed -i  "s/package\:flutter_sound/package:flutter_sound/" $f; done
        for f in $(find flutter_sound -name '*.md' )
        do
                gsed -i  "s/https:\/\/canardoux.github.io\/tau/https:\/\/dooboolab.github.io\/flutter_sound/" $f
                gsed -i  "s/https:\/\/pub.dartlang.org\/packages\/flauto/https:\/\/pub.dartlang.org\/packages\/flutter_sound/" $f
                gsed -i  "s/https:\/\/img.shields.io\/pub\/v\/flauto.svg/https:\/\/img.shields.io\/pub\/v\/flutter_sound.svg/" $f
        done


        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  flutter_sound/pubspec.yaml
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  flutter_sound_web/pubspec.yaml
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  flutter_sound_platform_interface/pubspec.yaml

        gsed -i  "s/https:\/\/canardoux.github.io\/tau/https:\/\/dooboolab.github.io\/flutter_sound/"   doc/SUMMARY.md
        gsed -i  "s/https:\/\/canardoux.github.io\/tau/https:\/\/dooboolab.github.io\/flutter_sound/"   doc/README.md

        for f in $(find doc -name '*.md' )
        do
                        gsed -i  "s/https:\/\/canardoux.github.io\/tau/https:\/\/dooboolab.github.io\/flutter_sound/"   $f
                        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  $f
        done

        exit 0

else
        echo "Correct syntax is $0 [TAU | FLUTTER_SOUND]"
        exit -1
fi
