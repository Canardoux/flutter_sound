#!/bin/bash


#cd ../flutter_sound_web
#git checkout main
#cd ../flutter_sound_platform_interface
#git checkout main
#cd ../flutter_sound_core
#git checkout master
#cd ../taudio



if [ "_$1" = "_REL" ] ; then
        echo 'REL mode'



        gsed -i  "s/^ *project(':flutter_sound_core').projectDir\(.*\)$/\/\/ project(':flutter_sound_core').projectDir\1/" example/android/settings.gradle
        gsed -i  "s/^ *include 'flutter_sound_core'$/\/\/ include 'flutter_sound_core'/" example/android/settings.gradle

        gsed -i  "s/^ *project(':flutter_sound_core').projectDir = /\/\/project(':flutter_sound_core').projectDir = /" android/settings.gradle

        gsed -i  "s/^ *pod 'flutter_sound_core',\(.*\)$/# pod 'flutter_sound_core',\1/"  example/ios/Podfile

        gsed -i  "s/^ *\(implementation project(':flutter_sound_core'\)/    \/\/\1/" android/build.gradle

        gsed -i  "s/^ *\/\/ *implementation 'com.github.canardoux:flutter_sound_core:/    implementation 'com.github.canardoux:flutter_sound_core:/"  android/build.gradle

# ../flutter_sound_web/pubspec.yaml
#-------------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: \1/"                                                          ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/#    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"        ../flutter_sound_web/pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: \1/"                                                                                        ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/tau\/etau # etau Dir$/#    path: \.\.\/\.\.\/tau\/etau # etau Dir/"                                      ../flutter_sound_web/pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: \1/"                                                                                        ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir$/#    path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      ../flutter_sound_web/pubspec.yaml



# pubspec.yaml
#---------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: \1/"                                                          pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/#    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"        pubspec.yaml

        gsed -i  "s/^ *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: \1/"                                                                                        pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flutter_sound_web # Flutter Sound Dir$/#    path: \.\.\/flutter_sound_web # Flutter Sound Dir/"                                      pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: \1/"                                                                                        pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/tau\/etau # etau Dir$/#    path: \.\.\/\.\.\/tau\/etau # etau Dir/"                                      pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: \1/"                                                                                        pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir$/#    path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      pubspec.yaml




# example/pubspec.yaml
#-----------------------------------
        gsed -i  "s/^ *flutter_sound: *#* *\(.*\)$/  flutter_sound: \1/"                                                                                                example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/ # Taudio Dir$/#    path: \.\.\/ # Taudio Dir/"                                                                        example/pubspec.yaml

        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: \1/"                                                                                                example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/flutter_sound_platform_interface$/#    path: \.\.\/\.\.\/flutter_sound_platform_interface/"                                                                        example/pubspec.yaml

        gsed -i  "s/^ *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: \1/"                                                                                   example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir$/#    path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir/"                  example/pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: \1/"                                                                                        example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/\.\.\/tau\/etau # etau Dir$/#    path: \.\.\/\.\.\/\.\.\/tau\/etau # etau Dir/"                                      example/pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: \1/"                                                                                        example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/\.\.\/tau\/tau_web # tau_web Dir$/#    path: \.\.\/\.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      example/pubspec.yaml



#========================================================================================================================================================================================================


elif [ "_$1" = "_DEV" ]; then
        echo 'DEV mode'


        gsed -i  "s/^ *\/\/ *project(':flutter_sound_core').projectDir\(.*\)$/   project(':flutter_sound_core').projectDir\1/" example/android/settings.gradle
        gsed -i  "s/^ *\/\/ *include 'flutter_sound_core'$/   include 'flutter_sound_core'/" example/android/settings.gradle

        gsed -i  "s/^ *\/\/ *project(':flutter_sound_core').projectDir = /    project(':flutter_sound_core').projectDir = /" android/settings.gradle


        gsed -i  "s/^ *# pod 'flutter_sound_core',\(.*\)$/pod 'flutter_sound_core',\1/" example/ios/Podfile

       gsed -i  "s/^ *\/\/ *\(implementation project(':flutter_sound_core'\)/    \1/" android/build.gradle



        gsed -i  "s/^ *implementation 'com.github.canardoux:flutter_sound_core:/    \/\/implementation 'com.github.canardoux:flutter_sound_core:/"  android/build.gradle


# ../flutter_sound_web/pubspec.yaml
#-------------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                         ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"            ../flutter_sound_web/pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: # \1/"                                                                                      ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/tau\/etau # etau Dir$/    path: \.\.\/\.\.\/tau\/etau # etau Dir/"                                      ../flutter_sound_web/pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: # \1/"                                                                                      ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir$/    path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      ../flutter_sound_web/pubspec.yaml


# pubspec.yaml
#---------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                        pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"        pubspec.yaml

        gsed -i  "s/^ *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: # \1/"                                                                                      pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flutter_sound_web # Flutter Sound Dir$/    path: \.\.\/flutter_sound_web # Flutter Sound Dir/"                                      pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: # \1/"                                                                                      pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/tau\/etau # etau Dir$/    path: \.\.\/\.\.\/tau\/etau # etau Dir/"                                      pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: # \1/"                                                                                      pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir$/    path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      pubspec.yaml


# example/pubspec.yaml
#-----------------------------------
        gsed -i  "s/^ *flutter_sound: *#* *\(.*\)$/  flutter_sound: # \1/"                                                                                              example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/ # Taudio Dir$/    path: \.\.\/ # Taudio Dir/"                                                                        example/pubspec.yaml

        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                                                              example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/flutter_sound_platform_interface$/    path: \.\.\/\.\.\/flutter_sound_platform_interface/"                                                                        example/pubspec.yaml

        gsed -i  "s/^ *#* *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: # \1/"                                                                                  example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir$/    path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir/"                  example/pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: # \1/"                                                                                      example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/\.\.\/tau\/etau # etau Dir$/    path: \.\.\/\.\.\/\.\.\/tau\/etau # etau Dir/"                                      example/pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: # \1/"                                                                                      example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/\.\.\/tau\/tau_web # tau_web Dir$/    path: \.\.\/\.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      example/pubspec.yaml

else
        echo "Correct syntax is $0 [REL | DEV]"
        exit -1
fi

#flutter clean
#flutter pub get
#cd example
#flutter clean
#flutter pub get

echo "Done"
