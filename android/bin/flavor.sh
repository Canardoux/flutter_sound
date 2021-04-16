#!/bin/bash

# ------------------------------------------------------------------------------------------------------

# This script is used to switch from the Flutter Sound FULL flavor to the Flutter Sound LITE flavor
# (or the opposite)

# If the script is called without parameter, it just analyzes the current flavor and print errors if any.

# The allowed parameters are :
# "bin/flavor FULL"  to switch to the full version
# "bin/flavor LITE"  to switch to the lite version.

# If the script encounters errors before doing the switch
# then it does not modify any files.
# If you want to force the changes, add a second script parameter 'force'

# The "Current Directory" must be the Flutter Sound root directory.
# Note : this script uses the GNU-sed ("brew install gnu-sed" on Macos)

# ------------------------------------------------------------------------------------------------------

# Verify the Current Directory.

if [ ! -f "bin/flavor.sh" ]
then
    	 echo "This script must be called from Flutter Sound root directory"
	     exit -1
fi


# ------------------------------------------------------------------------------------------------------

# Processing dart files
# ---------------------

process_dart_file()
{
	if [ $2 == 'FULL' ]; then
		gsed -i "s/^ *import *'package:flutter_sound_lite\//import 'package:flutter_sound\//" $1
    gsed -i "s/^ *import *'package:flauto_lite\//import 'package:flauto\//" $1
	else
		gsed -i "s/^ *import *'package:flutter_sound\//import 'package:flutter_sound_lite\//" $1
    gsed -i "s/^ *import *'package:flauto\//import 'package:flauto_lite\//" $1
	fi
}

# ------------------------------------------------------------------------------------------------------


case $1 in
FULL)

  cd flutter_sound

		gsed -i  's/^name: flutter_sound_lite$/name: flutter_sound/' pubspec.yaml
                gsed -i  's/^name: flauto_lite$/name: flauto/' pubspec.yaml
		gsed -i  's/^\( *\)flutter_sound_lite:/\1flutter_sound:/' example/pubspec.yaml
                gsed -i  's/^\( *\)flauto_lite:/\1flauto:/' example/pubspec.yaml

		mv ios/flutter_sound_lite.podspec ios/flutter_sound.podspec 2>/dev/null
                mv ios/flauto_lite.podspec ios/flauto.podspec 2>/dev/null
# ---
		gsed -i  "s/^ *s.name *=* 'flutter_sound_lite'$/s.name = 'flutter_sound'/"  ios/flutter_sound.podspec 2>/dev/null
                gsed -i  "s/^ *s.name *=* 'flauto_lite'$/s.name = 'flutter_sound'/"  ios/flutter_sound.podspec 2>/dev/null
                gsed -i  "s/^ *#* s.dependency *'mobile-ffmpeg-/  s.dependency 'mobile-ffmpeg-/"   ios/flutter_sound.podspec 2>/dev/null
# ---
                gsed -i  "s/^ *s.name *=* 'flutter_sound_lite'$/s.name = 'flauto'/"  ios/flauto.podspec 2>/dev/null
                gsed -i  "s/^ *s.name *=* 'flauto_lite'$/s.name = 'flauto'/"  ios/flauto.podspec 2>/dev/null
                gsed -i  "s/^ *#* s.dependency *'mobile-ffmpeg-/  s.dependency *'mobile-ffmpeg-/"   ios/flauto_lite.podspec 2>/dev/null
# ---

		gsed -i  "s/^ *#define *[A-Z]*_FLAVOR/#define FULL_FLAVOR/"   ios/Classes/FlutterSound.h
                gsed -i  "s/^ *#define *[A-Z]*_FLAVOR/#define FULL_FLAVOR/"   ios/Classes/FlutterSoundFFmpeg.h

                for f in $(find . -name '*.dart' ); do process_dart_file $f FULL $f; done

		mv "android/src/main/ffmpeg.park" "android/src/main/java/com/dooboolab/ffmpeg" 2>/dev/null

		gsed -i  "/ext.flutterFFmpegPackage *= *'audio'$/d"   android/build.gradle
		#gsed -i  "/implementation *'com.arthenica:mobile-ffmpeg-/d"   android/build.gradle
		gsed -i "1iext.flutterFFmpegPackage = 'audio'" android/build.gradle
  	        gsed -i "s/^[ \t]*\/\/implementation 'com.arthenica:mobile-ffmpeg-/    implementation 'com.arthenica:mobile-ffmpeg-/" android/build.gradle


  	        gsed -i  "/import *com.dooboolab.ffmpeg.FlutterSoundFFmpeg;$/d"  android/src/main/java/com/dooboolab/fluttersound/FlutterSound.java
		gsed -i  "1aimport com.dooboolab.ffmpeg.FlutterSoundFFmpeg;"     android/src/main/java/com/dooboolab/fluttersound/FlutterSound.java

 		gsed -i  "s/^[ $'\t']*public static *final *boolean *FULL_FLAVOR *= *false;$/    public static final boolean FULL_FLAVOR = true;/"  android/src/main/java/com/dooboolab/fluttersound/FlutterSound.java
		gsed -i  "s/^[ $'\t']*if *( *FULL_FLAVOR *) *;\/\/\ *{/        if (FULL_FLAVOR) \{/"  android/src/main/java/com/dooboolab/fluttersound/FlutterSound.java

  cd ..
	;;

# ------------------------------------------------------------------------------------------------------

LITE)
  cd flutter_sound

		gsed -i  's/^name: flutter_sound$/name: flutter_sound_lite/' pubspec.yaml
                gsed -i  's/^name: flauto$/name: flauto_lite/' pubspec.yaml
		gsed -i  's/^\( *\)flutter_sound:/\1flutter_sound_lite:/' example/pubspec.yaml
                gsed -i  's/^\( *\)flauto:/\1flauto_lite:/' example/pubspec.yaml

		mv ios/flutter_sound.podspec ios/flutter_sound_lite.podspec
                mv ios/flauto.podspec        ios/flauto_lite.podspec 2>/dev/null
# ---
		gsed -i  "s/^ *s.name *=* 'flutter_sound'$/s.name = 'flutter_sound_lite'/"  ios/flutter_sound_lite.podspec 2>/dev/null
                gsed -i  "s/^ *s.name *=* 'flauto'$/s.name = 'flutter_sound_lite'/"  ios/flutter_sound_lite.podspec 2>/dev/null
                gsed -i  "s/^ *#* s.dependency *'mobile-ffmpeg-/  # s.dependency 'mobile-ffmpeg-/"   ios/flutter_sound_lite.podspec 2>/dev/null
# ---
                gsed -i  "s/^ *s.name *=* 'flutter_sound'$/s.name = 'flauto_lite'/"  ios/flauto_lite.podspec 2>/dev/null
                gsed -i  "s/^ *s.name *=* 'flauto'$/s.name = 'flauto_lite'/"  ios/flauto_lite.podspec 2>/dev/null
                gsed -i  "/^ *#* s.dependency *'mobile-ffmpeg-/  # s.dependency *'mobile-ffmpeg-/"   ios/flauto_lite.podspec 2>/dev/null
# ---

                gsed -i  "s/^ *#define *[A-Z]*_FLAVOR/#define LITE_FLAVOR/"   ios/Classes/FlutterSound.h
                gsed -i  "s/^ *#define *[A-Z]*_FLAVOR/#define LITE_FLAVOR/"   ios/Classes/FlutterSoundFFmpeg.h

                for f in $(find . -name '*.dart' ); do process_dart_file $f LITE $f; done


		mv "android/src/main/java/com/dooboolab/ffmpeg" "android/src/main/ffmpeg.park" 2>/dev/null

		gsed -i  "/ext.flutterFFmpegPackage *= *'audio'$/d"   android/build.gradle
		gsed -i "1i//ext.flutterFFmpegPackage = 'audio'" android/build.gradle
 		gsed -i "s/^[ \t]*implementation 'com.arthenica:mobile-ffmpeg-/    \/\/implementation 'com.arthenica:mobile-ffmpeg-/" android/build.gradle


                gsed -i  "/import *com.dooboolab.ffmpeg.FlutterSoundFFmpeg;$/d"  android/src/main/java/com/dooboolab/fluttersound/FlutterSound.java
		gsed -i "1a//import com.dooboolab.ffmpeg.FlutterSoundFFmpeg;"  android/src/main/java/com/dooboolab/fluttersound/FlutterSound.java

		gsed -i  "s/^[ $'\t']*public static *final *boolean *FULL_FLAVOR *= *true;$/    public static final boolean FULL_FLAVOR = false;/"  android/src/main/java/com/dooboolab/fluttersound/FlutterSound.java
		gsed -i  "s/^[ $'\t']*if *( *FULL_FLAVOR *) *{/        if (FULL_FLAVOR) ;\/\/\{/"  android/src/main/java/com/dooboolab/fluttersound/FlutterSound.java
  cd ..
	;;

# ------------------------------------------------------------------------------------------------------

*)
	echo "Corect syntax is $0 [FULL||LITE]  [force]"
	exit -1
esac

rm -rf flutter_sound/example/ios/DerivedData 2>/dev/null
#rm -rf flutter_sound/example/ios/Podfile 2>/dev/null

exit 0

