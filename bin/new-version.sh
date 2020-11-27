#!/bin/bash
if [ -z "$1" ]; then
        echo "Correct usage is $0 <Version> "
        exit -1
fi



VERSION=$1
VERSION_CODE=${VERSION//./}
VERSION_CODE=${VERSION_CODE//+/}

bin/flavor.sh FULL
bin/reldev.sh REL
bin/setver.sh $VERSION

#rm flutter_sound/Logotype\ primary.png
#ln -s ../doc/flutter_sound/Logotype\ primary.png flutter_sound/
rm flutter_sound_web/js
if [  -d tau_core/web/js ]; then
    ln -s ../tau_core/web/js flutter_sound_web/js
else
   ln -s ../tau_sound_core/web/js flutter_sound_web/js
fi



cd flutter_sound_platform_interface/
#flutter clean
#flutter pub get

flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..

cd flutter_sound_web
flutter clean
flutter pub get
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..


cd flutter_sound
dartfmt lib
dartfmt example/lib
flutter analyze
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
dartanalyzer lib
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi



#flutter clean
#flutter pub get
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..

bin/flavor.sh LITE

cd flutter_sound
#flutter clean
#flutter pub get
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..

bin/flavor.sh FULL

git add .
git commit -m "TAU : Version $VERSION"
git push
git tag -f $VERSION
git push --tag -f


if test -f "tau_core.podspec"; then
    pod trunk push tau_core.podspec
else
    pod trunk push tau_sound_core.podspec
fi
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi

cd tau_core/android
./gradlew clean build bintrayUpload
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ../..

cd tau_core/web
npm publish .

cd ../..




cd flutter_sound/example
flutter pub get
flutter clean
cd ios
pod cache clean --all
rm Podfile.lock
rm -rf .symlinks/
pod repo update
cd ..
flutter build ios
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi

# Bug in flutter tools : if "flutter build --release" we must first "--debug" and then "--profile" before "--release"
flutter build apk --debug
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi

flutter build web
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi

cd ../..
rm -r doc/flutter_sound/web_example
cp -a flutter_sound/example/build/web doc/flutter_sound/web_example


bin/doc.sh $VERSION


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




echo 'E.O.J'
