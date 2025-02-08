#!/bin/bash


# Podfile sometimes disapeers !???!
if [ ! -f example/ios/Podfile ]; then
    echo "Podfile not found."
    cp example/ios/Podfile.keep example/ios/Podfile
fi

grep "pod 'flutter_sound_core'," example/ios/Podfile > /dev/null
#if [ $? -ne 0 ]; then

#    grep "pod 'flutter_sound_core'," example/ios/Podfile > /dev/null
    if [ $? -ne 0 ]; then

            echo "Podfile is not patched"
            echo "" >> example/ios/Podfile
            echo "# =====================================================" >> example/ios/Podfile
            echo "# The following instruction is only for Tau debugging." >> example/ios/Podfile
            echo "# Do not insert such a line in a real App." >> example/ios/Podfile
            echo "# pod 'flutter_sound_core', :path => '../../../flutter_sound_core'"  >> example/ios/Podfile
            echo "# =====================================================" >> example/ios/Podfile
    fi
#fi
gsed -i  "s/^#* *platform :ios,.*$/platform :ios, '14.2'/" example/ios/Podfile


if [ "_$1" = "_REL" ] ; then
        echo 'REL mode'

        echo '--------'


        gsed -i  "s/^ *implementation project(':flutter_sound_core')$/    \/\/ implementation project(':flutter_sound_core')/" example/android/app/build.gradle


        gsed -i  "s/^ *project(':flutter_sound_core').projectDir\(.*\)$/\/\/ project(':flutter_sound_core').projectDir\1/" example/android/settings.gradle

        gsed -i  "s/^ *include 'flutter_sound_core'$/\/\/ include 'flutter_sound_core'/" example/android/settings.gradle

        gsed -i  "s/^ *project(':flutter_sound_core').projectDir = /\/\/project(':flutter_sound_core').projectDir = /" android/settings.gradle

        gsed -i  "s/^ *\(implementation project(':flutter_sound_core'\)/    \/\/\1/" android/build.gradle

         gsed -i  "s/^ *\/\/ *implementation 'com.github.canardoux:flutter_sound_core:/    implementation 'com.github.canardoux:flutter_sound_core:/"  android/build.gradle






        gsed -i  "s/^ *pod 'flutter_sound_core',\(.*\)$/# pod 'flutter_sound_core',\1/"  example/ios/Podfile

        gsed -i  "s/^\(<\!-- static\) -->$/\1/" example/web/index.html
        gsed -i  "s/^\(<\!-- dynamic\)$/\1 -->/" example/web/index.html

# ../flutter_sound_web/pubspec.yaml
#-------------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: \1/"                                                          ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/#    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"        ../flutter_sound_web/pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: \1/"                                                                                        ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/tau\/etau # etau Dir$/#    path: \.\.\/\.\.\/tau\/etau # etau Dir/"                                      ../flutter_sound_web/pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: \1/"                                                                                        ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir$/#    path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      ../flutter_sound_web/pubspec.yaml

# ---

        gsed -i  "s/^ *flauto_platform_interface: *#* *\(.*\)$/  flauto_platform_interface: \1/"                                                                        ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flauto_platform_interface # Flutter Sound Dir$/#    path: \.\.\/flauto_platform_interface # Flutter Sound Dir/"                      ../flutter_sound_web/pubspec.yaml



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


# ---
        gsed -i  "s/^ *flauto_platform_interface: *#* *\(.*\)$/  flauto_platform_interface: \1/"                                                                        pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flauto_platform_interface # Flutter Sound Dir$/#    path: \.\.\/flauto_platform_interface # Flutter Sound Dir/"                      pubspec.yaml
        gsed -i  "s/^ *flauto_web: *#* *\(.*\)$/  flauto_web: \1/"                                                                                                      pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/flauto_web # Flutter Sound Dir$/#    path: \.\.\/flauto_web # Flutter Sound Dir/"                                                    pubspec.yaml




# example/pubspec.yaml
#-----------------------------------
        gsed -i  "s/^ *flutter_sound: *#* *\(.*\)$/  flutter_sound: \1/"                                                                                                example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/ # Flutter Sound Dir$/#    path: \.\.\/ # Flutter Sound Dir/"                                                                        example/pubspec.yaml

        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: \1/"                                                                                                example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/flutter_sound_platform_interface$/#    path: \.\.\/\.\.\/flutter_sound_platform_interface/"                                                                        example/pubspec.yaml

        #gsed -i  "s/^ *#* *flutter_sound_platform_interface: *#* *\(.*\)$/#  flutter_sound_platform_interface: \1/"                                                     example/pubspec.yaml
        #gsed -i  "s/^ *path: \.\.\/\.\.\/flutter_sound_platform_interface # flutter_sound_platform_interface Dir$/#    path: \.\.\/\.\.\/flutter_sound_platform_interface # flutter_sound_platform_interface Dir/" example/pubspec.yaml

        gsed -i  "s/^ *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: \1/"                                                                                   example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir$/#    path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir/"                  example/pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: \1/"                                                                                        example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/\.\.\/tau\/etau # etau Dir$/#    path: \.\.\/\.\.\/\.\.\/tau\/etau # etau Dir/"                                      example/pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: \1/"                                                                                        example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/\.\.\/tau\/tau_web # tau_web Dir$/#    path: \.\.\/\.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      example/pubspec.yaml

# ---

        gsed -i  "s/^ *flauto: *#* *\(.*\)$/  flauto: \1/"                                                                                                example/pubspec.yaml
        gsed -i  "s/^ *flauto_lite: *#* *\(.*\)$/  flauto_lite: \1/"                                                                                      example/pubspec.yaml

        gsed -i  "s/^ *#* *flauto_platform_interface: *#* *\(.*\)$/#  flauto_platform_interface: \1/"                                                     example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/flauto_platform_interface # flauto_platform_interface Dir$/#    path: \.\.\/\.\.\/flauto_platform_interface # flauto_platform_interface Dir/" example/pubspec.yaml

        gsed -i  "s/^ *#* *flauto_web: *#* *\(.*\)$/#  flauto_web: \1/"                                                                                   example/pubspec.yaml
        gsed -i  "s/^ *path: \.\.\/\.\.\/flauto_web # flutter_sound_web Dir$/#    path: \.\.\/\.\.\/flauto_web # flutter_sound_web Dir/"                  example/pubspec.yaml



#========================================================================================================================================================================================================


elif [ "_$1" = "_DEV" ]; then
        echo 'DEV mode'
        echo '--------'




        gsed -i  "s/^ *\/\/ implementation project(':flutter_sound_core')$/    implementation project(':flutter_sound_core')/" example/android/app/build.gradle


        gsed -i  "s/^ *\/\/ *project(':flutter_sound_core').projectDir\(.*\)$/   project(':flutter_sound_core').projectDir\1/" example/android/settings.gradle

        gsed -i  "s/^ *\/\/ *include 'flutter_sound_core'$/   include 'flutter_sound_core'/" example/android/settings.gradle

        gsed -i  "s/^ *\/\/ *project(':flutter_sound_core').projectDir = /    project(':flutter_sound_core').projectDir = /" android/settings.gradle


        gsed -i  "s/^\( *implementation [^\/]*\/\/ Tau Core\)$/\/\/\1/"  android/build.gradle



        gsed -i  "s/^ *\/\/ *\(implementation project(':flutter_sound_core'\)/    \1/" android/build.gradle



        gsed -i  "s/^ *implementation 'xyz.canardoux:flutter_sound_core:/    \/\/implementation 'xyz.canardoux:flutter_sound_core:/"  android/build.gradle





        gsed -i  "s/^ *# pod 'flutter_sound_core',\(.*\)$/pod 'flutter_sound_core',\1/" example/ios/Podfile

        gsed -i  "s/^\( *<\!-- dynamic\) -->$/\1/" example/web/index.html
        gsed -i  "s/^\( *<\!-- static\)$/\1 -->/" example/web/index.html
        gsed -i  "s/^\( *<\!-- static\) -->$/\1/" example/web/index.html
        gsed -i  "s/^\( *<\!-- dynamic\)$/\1 -->/" example/web/index.html

# ../flutter_sound_web/pubspec.yaml
#-------------------------------
        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                         ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir$/    path: \.\.\/flutter_sound_platform_interface # Flutter Sound Dir/"            ../flutter_sound_web/pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: # \1/"                                                                                      ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/tau\/etau # etau Dir$/    path: \.\.\/\.\.\/tau\/etau # etau Dir/"                                      ../flutter_sound_web/pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: # \1/"                                                                                      ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir$/    path: \.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      ../flutter_sound_web/pubspec.yaml
# ---

        gsed -i  "s/^ *flauto_platform_interface: *#* *\(.*\)$/  flauto_platform_interface: # \1/"                                                         ../flutter_sound_web/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flauto_platform_interface # Flutter Sound Dir$/    path: \.\.\/flauto_platform_interface # Flutter Sound Dir/"            ../flutter_sound_web/pubspec.yaml


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


# ---

        gsed -i  "s/^ *flauto_platform_interface: *#* *\(.*\)$/  flauto_platform_interface: # \1/"                                                        pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flauto_platform_interface # Flutter Sound Dir$/    path: \.\.\/flauto_platform_interface # Flutter Sound Dir/"        pubspec.yaml
        gsed -i  "s/^ *flauto_web: *#* *\(.*\)$/  flauto_web: # \1/" pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/flauto_web # Flutter Sound Dir$/    path: \.\.\/flauto_web # Flutter Sound Dir/"                                      pubspec.yaml

# example/pubspec.yaml
#-----------------------------------
        gsed -i  "s/^ *flutter_sound: *#* *\(.*\)$/  flutter_sound: # \1/"                                                                                              example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/ # Flutter Sound Dir$/    path: \.\.\/ # Flutter Sound Dir/"                                                                        example/pubspec.yaml

        gsed -i  "s/^ *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                                                              example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/flutter_sound_platform_interface$/    path: \.\.\/\.\.\/flutter_sound_platform_interface/"                                                                        example/pubspec.yaml

        #gsed -i  "s/^ *#* *flutter_sound_platform_interface: *#* *\(.*\)$/  flutter_sound_platform_interface: # \1/"                                                    example/pubspec.yaml
        #gsed -i  "s/^# *path: \.\.\/\.\.\/flutter_sound_platform_interface # flutter_sound_platform_interface Dir$/    path: \.\.\/\.\.\/flutter_sound_platform_interface # flutter_sound_platform_interface Dir/" example/pubspec.yaml

        gsed -i  "s/^ *#* *flutter_sound_web: *#* *\(.*\)$/  flutter_sound_web: # \1/"                                                                                  example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir$/    path: \.\.\/\.\.\/flutter_sound_web # flutter_sound_web Dir/"                  example/pubspec.yaml

        gsed -i  "s/^ *etau: *#* *\(.*\)$/  etau: # \1/"                                                                                      example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/\.\.\/tau\/etau # etau Dir$/    path: \.\.\/\.\.\/\.\.\/tau\/etau # etau Dir/"                                      example/pubspec.yaml

        gsed -i  "s/^ *tau_web: *#* *\(.*\)$/  tau_web: # \1/"                                                                                      example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/\.\.\/tau\/tau_web # tau_web Dir$/    path: \.\.\/\.\.\/\.\.\/tau\/tau_web # tau_web Dir/"                                      example/pubspec.yaml
# ---

        gsed -i  "s/^ *flauto: *#* *\(.*\)$/  flauto: # \1/"                                                                                              example/pubspec.yaml
        gsed -i  "s/^ *flauto_lite: *#* *\(.*\)$/  flauto_lite: # \1/"                                                                                    example/pubspec.yaml

        gsed -i  "s/^ *#* *flauto_platform_interface: *#* *\(.*\)$/  flauto_platform_interface: # \1/"                                                    example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/flauto_platform_interface # flauto_platform_interface Dir$/    path: \.\.\/\.\.\/flauto_platform_interface # flauto_platform_interface Dir/" example/pubspec.yaml

        gsed -i  "s/^ *#* *flauto_web: *#* *\(.*\)$/  flauto_web: # \1/"                                                                                  example/pubspec.yaml
        gsed -i  "s/^# *path: \.\.\/\.\.\/flauto_web # flutter_sound_web Dir$/    path: \.\.\/\.\.\/flauto_web # flutter_sound_web Dir/"                  example/pubspec.yaml



else
        echo "Correct syntax is $0 [REL | DEV]"
        exit -1
fi

#cd ../
#bin/reldev.sh $1

echo "Done"
