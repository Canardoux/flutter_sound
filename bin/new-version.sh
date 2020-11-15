#!/bin/bash
if [ -z "$1" ]; then
        echo "Correct usage is $0 <Version> "
        exit -1
fi



VERSION=$1
VERSION_CODE=${VERSION//./}
VERSION_CODE=${VERSION_CODE//+/}

###########bin/flavor FULL
bin/reldev.sh REL
bin/setver.sh $VERSION
bin/doc.sh $VERSION


cd flutter_sound_platform_interface/
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..


cd flutter_sound
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..

##########bin/flavor LITE

cd flutter_sound
##########flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..

########bin/flavor FULL

cd flutter_sound_web
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..



pod trunk push TauEngine.podspec
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi

cd TauEngine/android/TauEngine
./gradlew clean build bintrayUpload
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ../../..

cd TauEngine/web
npm publish .
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ../..


cd flutter_sound/example
flutter build web
cd ../..
rm -r doc/flutter_sound/web_example
cp -a flutter_sound/example/build/web doc/flutter_sound/

git add .
git commit -m "Release Version: $VERSION"
git push
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push --tag -f
fi
git checkout gh-pages
git merge master
git push
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push --tag -f
fi
git checkout master



cd flutter_sound/example
flutter pub get
flutter clean
cd ios
pod cache clean --all
rm Podfile.lock
pod repo update
pod install
cd ../../..



echo 'E.O.J'
