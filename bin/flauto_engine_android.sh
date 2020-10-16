#!/bin/bash

if [ -z "$1" ]; then
        echo "Correct usage is $0 [VERSION]"
        exit -1
fi
export v=$1


git add .
git commit -m "pod_flauto_engine_android.sh : Version $1"
git push
git tag -f flauto_engine_$1
git push --tag -f

cd flauto_engine/android/FlautoEngine
./gradlew clean
./gradlew assemble
./gradlew publishReleasePublicationToSonatypeRepository