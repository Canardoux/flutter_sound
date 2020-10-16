#!/bin/bash
if [ -z "$1" ]; then
	echo "Correct usage is $0 [VERSION]"
	exit -1
fi
VERSION=$1
VERSION_CODE=${VERSION//./}

gsed -i  "s/^\( *s.version *= *\).*$/\1'$VERSION'/" flauto_engine_ios.podspec
gsed -i  "s/^\( *s.dependency *'flauto_engine_ios', *\).*$/\1'$VERSION'/" flutter_sound/ios/flutter_sound.podspec
gsed -i  "s/^\( *versionName *\).*$/\1'$VERSION'/" flauto_engine/android/FlautoEngine/build.gradle
gsed -i  "s/^\( *versionCode *\).*$/\11$VERSION_CODE/" flauto_engine/android/FlautoEngine/build.gradle
gsed -i  "s/^\( *implementation 'xyz.canardoux:FlautoEngine:\).*$/\1$VERSION'/" flutter_sound/android/build.gradle

git add .
git commit -m "flauto_engine.sh : Version $1"
git push
git tag -f flauto_engine_$1
git push --tag -f

pod cache clean --all
pod trunk push flauto_engine_ios.podspec
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi


cd flauto_engine/android/FlautoEngine
./gradlew clean
./gradlew assemble
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
./gradlew publishReleasePublicationToSonatypeRepository
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi