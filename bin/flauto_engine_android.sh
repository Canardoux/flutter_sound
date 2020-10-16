#!/bin/bash

if [ -z "$1" ]; then
        echo "Correct usage is $0 [VERSION]"
        exit -1
fi

set v=$1
set $versionCode=123456
echo "s/^\( *versionName *\).*$/\1'$v'/"
gsed -i  "s/^\( *versionName *\).*$/\1'$v'/" flauto_engine/android/FlautoEngine/build.gradle
gsed -i  "s/^\( *versionCode *\).*$/\1$versionCode/" flauto_engine/android/FlautoEngine/build.gradle

git add .
git commit -m "pod_flauto_engine_android.sh : Version $1"
git push
git tag -f flauto_engine_$1
git push --tag -f

cd flauto_engine/android/FlautoEngine
./gradlew clean
./gradlew assemble
#####./gradlew publishReleasePublicationToSonatypeRepository