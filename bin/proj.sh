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

        exit 0

else
        echo "Correct syntax is $0 [TAU | FLUTTER_SOUND]"
        exit -1
fi
