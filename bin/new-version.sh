#!/bin/bash
if [ -z "$1" ]; then
        echo "Correct usage is $0 <Version> "
        exit -1
fi



VERSION=$1
VERSION_CODE=${VERSION#./}
VERSION_CODE=${VERSION_CODE#+/}

bin/setver.sh $VERSION
bin/reldev.sh REL
bin/web.sh

cd flutter_sound
dart analyze lib
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
dart format lib
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi

cd ..

#cp -a -v flutter_sound_web/js/flutter_sound/* flutter_sound/example/web/js/flutter_sound

#rm flutter_sound/Logotype\ primary.png
#ln -s ../doc/flutter_sound/Logotype\ primary.png flutter_sound/
#rm -rf flutter_sound_web/js
#if [  -d flutter_sound_core/web/js ]; then
#rm -rf flutter_sound_web/js
#cp -a -v flutter_sound_core/web/js flutter_sound_web

##rm -rf flutter_sound/example/web/js
#cp -a -v flutter_sound_core/web/js flutter_sound/example/web
rm -rf _*.tgz
    
    #ln -s ../flutter_sound_core/web/js flutter_sound_web/js
#else
#   ln -s ../tau_sound_core/web/js flutter_sound_web/js
#fi


cd flutter_sound_platform_interface/    
#flutter clean
#flutter pub get
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
cd ..

cd flutter_sound_web
flutter clean
flutter pub get
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
cd ..



cd flutter_sound
dart format  lib
dart format  example/lib
dart analyze lib
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
cd ..



git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
    git tag -f $VERSION
    git push  -f origin $VERSION
fi

cd flutter_sound_core
git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
    git tag -f $VERSION
    git push  -f origin $VERSION
fi
cd ..

cd flutter_sound_core
pod trunk push flutter_sound_core.podspec
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
cd ..

#cd flutter_sound_core/android
#./gradlew clean build bintrayUpload
#if [ $? -ne 0 ]; then
#    echo "Error"
#    exit -1
#fi
#cd ../..


git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push  -f origin $VERSION
fi

cd flutter_sound_core
git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
    git tag -f $VERSION
    git push  -f origin $VERSION
fi
cd ..

cd flutter_sound_core/web
npm publish .

cd ../..
 
cd flutter_sound
#flutter clean
#flutter pub get
flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..



cd flutter_sound
flutter analyze lib
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
#dartdoc lib
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
rm -rf doc
cd example
flutter analyze lib
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
#dartdoc lib
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
rm -rf doc
cd ../..




cd flutter_sound/example/ios
pod cache clean --all
rm Podfile.lock
rm -rf .symlinks/
cd ..
flutter clean
flutter pub get
cd ios
pod update
pod repo update
pod install --repo-update
pod update
pod install
cd ..
flutter build ios
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi

# Bug in flutter tools : if "flutter build --release" we must first "--debug" and then "--profile" before "--release"
flutter build apk --debug
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi

cd ../..


bin/doc.sh $VERSION

git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push  -f origin $VERSION
fi

cd flutter_sound_core
git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
    git tag -f $VERSION
    git push  -f origin $VERSION
fi
cd ..


#git add .
#git commit -m "Release Version: $VERSION"
#if [ ! -z "$VERSION" ]; then
#        git tag -f $VERSION
#        git push --tag -f
#fi
#git checkout gh-pages
#git merge master
#git push
#if [ ! -z "$VERSION" ]; then
#        git tag -f $VERSION
 #       git push --tag -f
#fi
#git checkout master




echo 'E.O.J'
