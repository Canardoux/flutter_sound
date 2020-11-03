#!/bin/bash


# Podfile sometimes disapeers !???!
if [ ! -f flutter_sound/example/ios/Podfile ]; then
    echo "Podfile not found!"
    cp flutter_sound/example/ios/Podfile.keep flutter_sound/example/ios/Podfile
fi

grep "pod 'TauEngine'," flutter_sound/example/ios/Podfile > /dev/null
if [ $? -ne 0 ]; then
        echo "Podfile is not patched"
        echo "" >> flutter_sound/example/ios/Podfile
        echo "# =====================================================" >> flutter_sound/example/ios/Podfile
        echo "# The following instruction is only for Tau debugging." >> flutter_sound/example/ios/Podfile
        echo "# Do not insert such a line in a real App." >> flutter_sound/example/ios/Podfile
        echo "pod 'TauEngine', :path => '../../..'"  >> flutter_sound/example/ios/Podfile
        echo "# =====================================================" >> flutter_sound/example/ios/Podfile
fi


if [ "_$1" = "_REL" ] ; then
        echo 'REL mode'

        echo '--------'
        gsed -i  "s/^ *implementation project(':TauEngine')$/    \/\/ implementation project(':TauEngine')/" flutter_sound/example/android/app/build.gradle
        gsed -i  "s/^ *project(':TauEngine').projectDir\(.*\)$/\/\/ project(':TauEngine').projectDir\1/" flutter_sound/example/android/settings.gradle
        gsed -i  "s/^ *include 'TauEngine'$/\/\/ include 'TauEngine'/" flutter_sound/example/android/settings.gradle
        gsed -i  "s/^ *pod 'TauEngine',\(.*\)$/# pod 'TauEngine',\1/"  flutter_sound/example/ios/Podfile
        gsed -i  "s/^ *implementation project(':TauEngine')$/    \/\/ implementation project(':TauEngine')/" flutter_sound/android/build.gradle
        gsed -i  "s/^ *project(':TauEngine').projectDir\(.*\)$/\/\/ project(':TauEngine').projectDir\1/" flutter_sound/android/settings.gradle

# flutter_sound_web/pubspec.yaml
#-------------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: \1/"                                                          flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/#    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"            flutter_sound_web/pubspec.yaml

# flutter_sound/pubspec.yaml
#---------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: \1/"                                                          flutter_sound/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/#    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"        flutter_sound/pubspec.yaml
        gsed -i  "s/^ *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: \1/"                                                                                        flutter_sound/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flutter_sound_web # Flutter Sound Dir$/#    path: \.\.\/flutter_sound_web # Flutter Sound Dir/"                                      flutter_sound/pubspec.yaml

# flutter_sound/example/pubspec.yaml
#-----------------------------------
        gsed -i  "s/^ *flutter_sound: *#* *\(.*\)$/  flutter_sound: \1/"                                                                                                flutter_sound/example/pubspec.yaml
        gsed -i  "s/^ *flutter_sound_lite: *#* *\(.*\)$/  flutter_sound_lite: \1/"                                                                                      flutter_sound/example/pubspec.yaml

        gsed -i  "s/^ *path: \.\.\/ # Flutter Sound Dir$/#    path: \.\.\/ # Flutter Sound Dir/"                                                                        flutter_sound/example/pubspec.yaml

        gsed -i  "s/^ *#* *flutter_sound_platform_interface: *#* *\(.*\)$/#  flutter_sound_platform_interface: \1/"                                                     flutter_sound/example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/flutter_sound_platform_interface # flutter_sound_platform_interface Dir$/#    path: \.\.\/\.\.\/flutter_sound_platform_interface # flutter_sound_platform_interface Dir/" flutter_sound/example/pubspec.yaml

        gsed -i  "s/^ *#* *flutter_sound_web: *#* *\(.*\)$/#  flutter_sound_web: \1/"                                                                                   flutter_sound/example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir$/#    path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir/"                  flutter_sound/example/pubspec.yaml

        exit 0

#========================================================================================================================================================================================================


elif [ "_$1" = "_DEV" ]; then
        echo 'DEV mode'
        echo '--------'

        gsed -i  "s/^ *\/\/ implementation project(':TauEngine')$/    implementation project(':TauEngine')/" flutter_sound/example/android/app/build.gradle
        gsed -i  "s/^ *\/\/ *project(':TauEngine').projectDir\(.*\)$/   project(':TauEngine').projectDir\1/" flutter_sound/example/android/settings.gradle
        gsed -i  "s/^ *\/\/ *include 'TauEngine'$/   include 'TauEngine'/" flutter_sound/example/android/settings.gradle
        gsed -i  "s/^ *# pod 'TauEngine',\(.*\)$/pod 'TauEngine',\1/" flutter_sound/example/ios/Podfile
        gsed -i  "s/^ *\/\/ implementation project(':TauEngine')$/    implementation project(':TauEngine')/" flutter_sound/android/build.gradle
        gsed -i  "s/^ *\/\/ *project(':TauEngine').projectDir\(.*\)$/   project(':TauEngine').projectDir\1/" flutter_sound/android/settings.gradle

# flutter_sound_web/pubspec.yaml
#-------------------------------
       gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                         flutter_sound_web/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"            flutter_sound_web/pubspec.yaml

# flutter_sound/pubspec.yaml
#---------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                        flutter_sound/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"        flutter_sound/pubspec.yaml
        gsed -i  "s/^ *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: # \1/" flutter_sound/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flutter_sound_web # Flutter Sound Dir$/    path: \.\.\/flutter_sound_web # Flutter Sound Dir/"                                      flutter_sound/pubspec.yaml


# flutter_sound/example/pubspec.yaml
#-----------------------------------
        gsed -i  "s/^ *flutter_sound: *#* *\(.*\)$/  flutter_sound: # \1/"                                                                                              flutter_sound/example/pubspec.yaml
        gsed -i  "s/^ *flutter_sound_lite: *#* *\(.*\)$/  flutter_sound_lite: # \1/"                                                                                    flutter_sound/example/pubspec.yaml

        gsed -i  "s/^# *path: \.\.\/ # Flutter Sound Dir$/    path: \.\.\/ # Flutter Sound Dir/"                                                                        flutter_sound/example/pubspec.yaml

        gsed -i  "s/^ *#* *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                    flutter_sound/example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/flutter_sound_platform_interface # flutter_sound_platform_interface Dir$/    path: \.\.\/\.\.\/flutter_sound_platform_interface # flutter_sound_platform_interface Dir/" flutter_sound/example/pubspec.yaml

        gsed -i  "s/^ *#* *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: # \1/"                                                                                  flutter_sound/example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir$/    path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir/"                  flutter_sound/example/pubspec.yaml

        exit 0

else
        echo "Correct syntax is $0 [REL | DEV]"
        exit -1
fi
