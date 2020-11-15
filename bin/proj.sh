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
        gsed -i  "s/'https:\/\/github.com\/dooboolab\/flutter_sound.git'/'https:\/\/github.com\/Canardoux\/tau.git'/" TauEngine.podspec
        gsed -i  "s/^ *flutter_sound: \(.*\)$/  flauto: \1/" flutter_sound/example/pubspec.yaml


        for f in flutter_sound/lib/*.dart
        do
                gsed -i  "s/package\:flutter_sound/package:flauto/" $f
        done
        for f in flutter_sound/lib/src/*.dart
        do
                gsed -i  "s/package\:flutter_sound/package:flauto/" $f
        done
        for f in flutter_sound/lib/src/ui/*.dart
        do
                gsed -i  "s/package\:flutter_sound/package:flauto/" $f
        done
        for f in flutter_sound/lib/src/util/*.dart
        do
                gsed -i  "s/package\:flutter_sound/package:flauto/" $f
        done
        for f in flutter_sound_web/lib/*.dart
        do
                gsed -i  "s/package\:flutter_sound/package:flauto/" $f
        done

        for f in flutter_sound/example/lib/*.dart
        do
                gsed -i  "s/package\:flutter_sound/package:flauto/" $f
        done
        for f in flutter_sound/example/lib/widgetUI/demo_util/*.dart
        do
                gsed -i  "s/package\:flutter_sound/package:flauto/" $f
        done

        for d in flutter_sound/example/lib/*/
        do
                for f in $d/*.dart
                do
                        gsed -i  "s/package\:flutter_sound/package:flauto/" $f
                done
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
        gsed -i  "s/'https://github.com/Canardoux/tau.git'/'https://github.com/dooboolab/flutter_sound.git'/" TauEngine.podspec
        gsed -i  "s/^ *flauto: \(.*\)$/  flutter_sound: \1/" flutter_sound/example/pubspec.yaml

        for f in flutter_sound/lib/*.dart
        do
                gsed -i  "s/package\:flauto/package:flutter_sound/" $f
        done
        for f in flutter_sound/lib/src/*.dart
        do
                gsed -i  "s/package\:flauto/package:flutter_sound/" $f
        done
        for f in flutter_sound/lib/src/util/*.dart
        do
                gsed -i  "s/package\:flauto/package:flutter_sound/" $f
        done
        for f in flutter_sound/lib/src/ui/*.dart
        do
                gsed -i  "s/package\:flauto/package:flutter_sound/" $f
        done
        for f in flutter_sound_web/lib/*.dart
        do
                gsed -i  "s/package\:flauto/package:flutter_sound/" $f
        done

        for f in flutter_sound/example/lib/*.dart
        do
                gsed -i  "s/package\:flauto/package:flutter_sound/" $f
        done
        for f in flutter_sound/example/lib/widgetUI/demo_util/*.dart
        do
                gsed -i  "s/package\:flauto/package:flutter_sound/" $f
        done

        for d in flutter_sound/example/lib/*/
        do
                for f in $d/*.dart
                do
                        gsed -i  "s/package\:flauto/package:flutter_sound/" $f
                done
        done



        exit 0

else
        echo "Correct syntax is $0 [TAU | FLUTTER_SOUND]"
        exit -1
fi
