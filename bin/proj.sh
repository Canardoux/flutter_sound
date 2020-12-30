#!/bin/bash


if [ "_$1" = "_TAU" ] ; then
        echo 'Tau project'
        echo '-----------'

        gsed -i  "s/^ *implementation project(':tau_sound_core')$/    implementation project(':tau_core')/" flutter_sound/example/android/app/build.gradle
        gsed -i  "s/^ *\/\/ *implementation project(':tau_sound_core')$/    \/\/ implementation project(':tau_core')/" flutter_sound/example/android/app/build.gradle

        gsed -i  "s/^ *include 'tau_sound_core'$/    include 'tau_core'/" flutter_sound/example/android/settings.gradle
        gsed -i  "s/^ *\/\/ *include 'tau_sound_core'$/    \/\/ include 'tau_core'/" flutter_sound/example/android/settings.gradle

        gsed -i  "s/^ *project(':tau_sound_core').projectDir = /    project(':tau_core').projectDir = /" flutter_sound/example/android/settings.gradle
        gsed -i  "s/^ *\/\/ *project(':tau_sound_core').projectDir = /    \/\/ project(':tau_core').projectDir = /" flutter_sound/example/android/settings.gradle

        gsed -i  "s/^ *project(':tau_sound_core').projectDir = /    project(':tau_core').projectDir = /" flutter_sound/android/settings.gradle
        gsed -i  "s/^ *\/\/ *project(':tau_sound_core').projectDir = /    \/\/ project(':tau_core').projectDir = /" flutter_sound/android/settings.gradle

        gsed -i  "s/^ *implementation project(':tau_sound_core')$/    implementation project(':tau_core')/" flutter_sound/android/build.gradle
        gsed -i  "s/^ *\/\/ *implementation project(':tau_sound_core')$/    \/\/ implementation project(':tau_core')/" flutter_sound/android/build.gradle

        gsed -i  "s/^ *\/\/ *implementation 'xyz.canardoux:tau_sound_core:/    \/\/implementation 'xyz.canardoux:tau_core:/" flutter_sound/android/build.gradle
        gsed -i  "s/^ *implementation 'xyz.canardoux:tau_sound_core:/    implementation 'xyz.canardoux:tau_core:/" flutter_sound/android/build.gradle



        mv flutter_sound/ios/flutter_sound.podspec flutter_sound/ios/flauto.podspec 2>/dev/null
        mv flutter_sound/ios/flutter_sound_lite.podspec flutter_sound/ios/flauto_lite.podspec 2>/dev/null

        gsed -i  "s/ *s\.dependency 'tau_sound_core',/  s.dependency 'tau_core',/" flutter_sound/ios/flauto.podspec
        gsed -i  "s/ \/\/ *s\.dependency 'tau_sound_core',/  \/\/s.dependency 'tau_core',/" flutter_sound/ios/flauto.podspec


        gsed -i  "s/^\( *rootProject.name *= *\).*$/\1'flauto'/" flutter_sound/android/settings.gradle
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
        gsed -i  "s/^\( *artifactId \).*$/\1'tau_core'/" tau_core/android/install.gradle
        gsed -i  "s/^\( *name \)'tau_sound_core'$/\1'tau_core'/" tau_core/android/install.gradle
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/g" tau_core/android/install.gradle

        gsed -i  "s/^bintrayName = tau_sound_core$/bintrayName = tau_core/" tau_core/android/gradle.properties
        gsed -i  "s/^artifact = tau_sound_core$/artifact = tau_core/" tau_core/android/gradle.properties

        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" tau_core/android/bintray.gradle
        gsed -i  "s/^\( *name = \).*$/\1'xyz.canardoux.tau_core'/" tau_core/android/bintray.gradle


        gsed -i  "s/^ *flutter_sound: \(.*\)$/  flauto: \1/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *#* *\)flutter_sound_platform_interface/\1flauto_platform_interface/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *#* *\)flutter_sound_web/\1flauto_web/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *s.name = \)'flutter_sound'$/\1'flauto'/" flutter_sound/ios/flauto.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound_lite'$/\1'flauto_lite'/" flutter_sound/ios/flauto.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound'$/\1'flauto'/" flutter_sound/ios/flauto_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound_lite'$/\1'flauto_lite'/" flutter_sound/ios/flauto.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flutter_sound_lite'$/\1'flauto_lite'/" flutter_sound/ios/flauto_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *\"name\": \)\"tau_sound_core\"/\1\"tau_core\"/" tau_core/web/package.json
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound\.git/https:\/\/github.com\/canardoux\/tau\.git/" tau_core/web/package.json

        gsed -i  "s/^\(#* *pod \)'tau_sound_core',/\1'tau_core',/" flutter_sound/example/ios/Podfile

        for f in $(find . -name '*.dart' )
        do
                gsed -i  "s/package\:flutter_sound/package:flauto/" "$f"
        done

        for f in $(find . -name '*.md' )
        do
                gsed -i  "s/https:\/\/dooboolab.github.io\/flutter_sound/https:\/\/canardoux.github.io\/tau/" "$f"
                gsed -i  "s/https:\/\/pub.dartlang.org\/packages\/flutter_sound/https:\/\/pub.dartlang.org\/packages\/flauto/" "$f"
                gsed -i  "s/https:\/\/img.shields.io\/pub\/v\/flutter_sound.svg/https:\/\/img.shields.io\/pub\/v\/flauto.svg/" "$f"
                gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" "$f"
                gsed -i  "s/www.canardoux.xyz\/tau_sound\/doc/www.canardoux.xyz\/tau\/doc/g" "$f"
        done

        # We want to keep links to flutter_sound in the changelog.md
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  doc/CHANGELOG.md
        gsed -i  "s/https:\/\/github.com\/Canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  doc/CHANGELOG.md



        for f in flutter_sound/ios/Classes/*
        do
                gsed -i  "s/tau_sound_core\//tau_core\//" "$f"
        done



        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" flutter_sound/pubspec.yaml
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" flutter_sound_web/pubspec.yaml
        gsed -i  "s/https:\/\/github.com\/dooboolab\/flutter_sound/https:\/\/github.com\/canardoux\/tau/" flutter_sound_platform_interface/pubspec.yaml

        gsed -i  "s/\/soft\/www\/canardoux.xyz\/tau_sound\/doc/\/soft\/www\/canardoux.xyz\/tau\/doc/g" bin/doc.sh
        gsed -i  "s/\/canardoux.xyz\/tau_sound\/doc\//\/canardoux.xyz\/tau\/doc\//g" flutter_sound/pubspec.yaml
        gsed -i  "s/github.com\/dooboolab\/flutter_sound/github.com\/canardoux\/tau/g" doc/_data/topnav.yml
        gsed -i  "s/github.com\/dooboolab\/flutter_sound/github.com\/canardoux\/tau/g" doc/_data/sidebars/mydoc_sidebar.yml

        gsed -i  "s/^\( *<script src=\"https:\/\/cdn\.jsdelivr\.net\/npm\/\)tau_sound_core@/\1tau_core@/"  flutter_sound/example/web/index.html


        exit 0

#========================================================================================================================================================================================================


elif [ "_$1" = "_FLUTTER_SOUND" ]; then
        echo 'Flutter Sound Project'
        echo '---------------------'

        gsed -i  "s/^ *implementation project(':tau_core')$/    implementation project(':tau_sound_core')/" flutter_sound/example/android/app/build.gradle
        gsed -i  "s/^ *\/\/ *implementation project(':tau_core')$/    \/\/ implementation project(':tau_sound_core')/" flutter_sound/example/android/app/build.gradle

        gsed -i  "s/^ *include 'tau_core'$/    include 'tau_sound_core'/" flutter_sound/example/android/settings.gradle
        gsed -i  "s/^ *\/\/ *include 'tau_core'$/    \/\/ include 'tau_sound_core'/" flutter_sound/example/android/settings.gradle

        gsed -i  "s/^ *project(':tau_core').projectDir = /    project(':tau_sound_core').projectDir = /" flutter_sound/example/android/settings.gradle
        gsed -i  "s/^ *\/\/ *project(':tau_core').projectDir = /    \/\/ project(':tau_sound_core').projectDir = /" flutter_sound/example/android/settings.gradle

        gsed -i  "s/^ *project(':tau_core').projectDir = /    project(':tau_sound_core').projectDir = /" flutter_sound/android/settings.gradle
        gsed -i  "s/^ *\/\/ *project(':tau_core').projectDir = /    \/\/ project(':tau_sound_core').projectDir = /" flutter_sound/android/settings.gradle

        gsed -i  "s/^ *implementation project(':tau_core')$/    implementation project(':tau_sound_core')/" flutter_sound/android/build.gradle
        gsed -i  "s/^ *\/\/ *implementation project(':tau_core')$/    \/\/ implementation project(':tau_sound_core')/" flutter_sound/android/build.gradle

        gsed -i  "s/^ *implementation 'xyz.canardoux:tau_core:/    implementation 'xyz.canardoux:tau_sound_core:/" flutter_sound/android/build.gradle
        gsed -i  "s/^ *\/\/ *implementation 'xyz.canardoux:tau_core:/    \/\/ implementation 'xyz.canardoux:tau_sound_core:/" flutter_sound/android/build.gradle


        mv flutter_sound/ios/flauto.podspec flutter_sound/ios/flutter_sound.podspec 2>/dev/null
        mv flutter_sound/ios/flauto_lite.podspec flutter_sound/ios/flutter_sound_lite.podspec 2>/dev/null



        gsed -i  "s/ *s\.dependency 'tau_core',/  s.dependency 'tau_sound_core',/" flutter_sound/ios/flutter_sound.podspec
        gsed -i  "s/ \/\/ *s\.dependency 'tau_core',/  \/\/s.dependency 'tau_sound_core',/" flutter_sound/ios/flutter_sound.podspec


        gsed -i  "s/^\( *rootProject.name *= *\).*$/\1'flutter_sound'/" flutter_sound/android/settings.gradle
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
        gsed -i  "s/^\( *artifactId \).*$/\1'tau_sound_core'/" tau_core/android/install.gradle
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/" tau_core/android/bintray.gradle
        gsed -i  "s/^\( *name = \).*$/\1'xyz.canardoux.tau_sound_core'/" tau_core/android/bintray.gradle
        gsed -i  "s/^\( *name \)'tau_core'$/\1'tau_sound_core'/" tau_core/android/install.gradle

        gsed -i  "s/^ *\/\/ implementation 'xyz.canardoux:tau_core:\(.*\)$/    \/\/implementation 'xyz.canardoux:tau_sound_core:\1/" flutter_sound/android/build.gradle
        gsed -i  "s/^bintrayName = tau_core$/bintrayName = tau_sound_core/" tau_core/android/gradle.properties
        gsed -i  "s/^artifact = tau_core$/artifact = tau_sound_core/" tau_core/android/gradle.properties
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/g" tau_core/android/install.gradle



        gsed -i  "s/^ *flauto: \(.*\)$/  flutter_sound: \1/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *#* *\)flauto_platform_interface/\1flutter_sound_platform_interface/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *#* *\)flauto_web/\1flutter_sound_web/" flutter_sound/example/pubspec.yaml
        gsed -i  "s/^\( *s.name = \)'flauto'$/\1'flutter_sound'/" flutter_sound/ios/flutter_sound.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flauto_lite'$/\1'flutter_sound_lite'/" flutter_sound/ios/flutter_sound.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flauto'$/\1'flutter_sound'/" flutter_sound/ios/flutter_sound_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *s.name = \)'flauto_lite'$/\1'flutter_sound_lite'/" flutter_sound/ios/flutter_sound_lite.podspec 2>/dev/null
        gsed -i  "s/^\( *\"name\": \)\"tau_core\"/\1\"tau_sound_core\"/" tau_core/web/package.json
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau\.git/https:\/\/github.com\/dooboolab\/flutter_sound\.git/" tau_core/web/package.json

        gsed -i  "s/^\(#* *pod \)'tau_core',/\1'tau_sound_core',/" flutter_sound/example/ios/Podfile

        for f in $(find . -name '*.dart' )
        do
                gsed -i  "s/package\:flauto/package:flutter_sound/" "$f"
        done

        for f in $(find . -name '*.md' )
        do
                gsed -i  "s/https:\/\/canardoux.github.io\/tau/https:\/\/dooboolab.github.io\/flutter_sound/" "$f"
                gsed -i  "s/https:\/\/Canardoux.github.io\/tau/https:\/\/dooboolab.github.io\/flutter_sound/" "$f"
                gsed -i  "s/https:\/\/pub.dartlang.org\/packages\/flauto/https:\/\/pub.dartlang.org\/packages\/flutter_sound/" "$f"
                gsed -i  "s/https:\/\/img.shields.io\/pub\/v\/flauto.svg/https:\/\/img.shields.io\/pub\/v\/flutter_sound.svg/" "$f"
                gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  "$f"
                gsed -i  "s/https:\/\/github.com\/Canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  "$f"
                gsed -i  "s/www.canardoux.xyz\/tau\/doc/www.canardoux.xyz\/tau_sound\/doc/g" "$f"
        done

        for f in flutter_sound/ios/Classes/*
        do
                gsed -i  "s/tau_core\//tau_sound_core\//" "$f"
        done




        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  flutter_sound/pubspec.yaml
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  flutter_sound_web/pubspec.yaml
        gsed -i  "s/https:\/\/github.com\/canardoux\/tau/https:\/\/github.com\/dooboolab\/flutter_sound/"  flutter_sound_platform_interface/pubspec.yaml

        gsed -i  "s/\/soft\/www\/canardoux.xyz\/tau\/doc/\/soft\/www\/canardoux.xyz\/tau_sound\/doc/g" bin/doc.sh
        gsed -i  "s/\/canardoux.xyz\/tau\/doc\//\/canardoux.xyz\/tau_sound\/doc\//g" flutter_sound/pubspec.yaml
        gsed -i  "s/github.com\/canardoux\/tau/github.com\/dooboolab\/flutter_sound/g" doc/_data/topnav.yml
        gsed -i  "s/github.com\/canardoux\/tau/github.com\/dooboolab\/flutter_sound/g" doc/_data/sidebars/mydoc_sidebar.yml

        gsed -i  "s/^\( *<script src=\"https:\/\/cdn\.jsdelivr\.net\/npm\/\)tau_core@/\1tau_sound_core@/"  flutter_sound/example/web/index.html

        exit 0

else
        echo "Correct syntax is $0 [TAU | FLUTTER_SOUND]"
        exit -1
fi
