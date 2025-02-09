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
#bin/web.sh

flutter analyze lib
if [ $? -ne 0 ]; then
    echo "Error: analyze flutter_sound/lib"
    #!!!!!exit -1
fi
dart format lib
if [ $? -ne 0 ]; then
    echo "Error: format flutter_sound/lib"
    exit -1
fi

rm -rf _*.tgz
 
cd ../flutter_sound_platform_interface/    
#flutter clean
#flutter pub get

flutter analyze lib
if [ $? -ne 0 ]; then
    echo "Error: analyze flutter_sound_platform_interface/lib"
    exit -1
fi
dart format lib
if [ $? -ne 0 ]; then
    echo "Error: format flutter_sound_platform_interface/lib"
    exit -1
fi

flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error: flutter pub publish[flutter_sound_platform_interface]"
    #!!!!!exit -1
fi
cd ../flutter_sound

echo '--------------------------------------------------------------------------------'

cd ../flutter_sound_web
flutter clean
flutter pub get

flutter analyze lib
if [ $? -ne 0 ]; then
    echo "Error: analyze flutter_sound_web/lib"
    #!!!!exit -1
fi
dart format lib
if [ $? -ne 0 ]; then
    echo "Error: format flutter_sound_web/lib"
    exit -1
fi

flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error: flutter pub publish[flutter_sound_web]"
    #!!!!!!exit -1
fi
cd ../flutter_sound


echo '--------------------------------------------------------------------------------'

cd ../flutter_sound_core
git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
    git tag -f $VERSION
    git push  -f origin $VERSION
fi
cd ../flutter_sound

cd ../flutter_sound_web
git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
    git tag -f $VERSION
    git push  -f origin $VERSION
fi
cd ../flutter_sound


git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
    git tag -f $VERSION
    git push  -f origin $VERSION
fi


echo '--------------------------------------------------------------------------------'
cd ../flutter_sound_core
pod trunk push flutter_sound_core.podspec 
if [ $? -ne 0 ]; then
    echo "Error: trunk push flutter_sound_core.podspec[flutter_sound_core]"
    #!!!!!exit -1
fi
cd ../flutter_sound

echo '--------------------------------------------------------------------------------'

cd ../flutter_sound_web
npm publish .
if [ $? -ne 0 ]; then
    echo "Error: npm publish"
    #!!!!!exit -1
fi

cd ../flutter_sound
 
echo '--------------------------------------------------------------------------------'


flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error: flutter pub publish[flutter_sound]"
   #!!!!!!exit -1
fi

echo '--------------------------------------------------------------------------------'

flutter analyze lib
if [ $? -ne 0 ]; then
    echo "Error: analyze flutter_sound/lib"
    #!!!!!!!!!exit -1
fi
dart format lib
if [ $? -ne 0 ]; then
    echo "Error: format flutter_sound/lib"
    exit -1
fi
dart format  example/lib


#flutter clean
#flutter pub get
flutter analyze lib
if [ $? -ne 0 ]; then
    echo "Error: analyze flutter_sound/lib"
    #!!!!!!!!!!!exit -1
fi
dart format lib
if [ $? -ne 0 ]; then
    echo "Error: format flutter_sound/lib"
    exit -1
fi


rm -rf doc/api
dart doc .
if [ $? -ne 0 ]; then
    echo "Error: dart doc flutter_sound/lib"
   #!!!!!exit -1
fi


cd example
flutter analyze lib
if [ $? -ne 0 ]; then
    echo "Error: analyze flutter_sound/example/lib"
    #!!!!!exit -1
fi
cd ..



cd example/ios
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

cd example
flutter build ios --release
if [ $? -ne 0 ]; then
    echo "Error: flutter build flutter_sound/example/ios"
    exit -1
fi

# Bug in flutter tools : if "flutter build --release" we must first "--debug" and then "--profile" before "--release"
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "Error: flutter build flutter_sound/example/apk"
    exit -1
fi

flutter build web --release
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..


bin/doc.sh $VERSION


cd flutter_sound_core
git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
    git tag -f $VERSION
    git push  -f origin $VERSION
fi

cd ../flutter_sound_web


git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push  -f origin $VERSION
fi

cd ../flutter_sound_platform_interface


git add .
git commit -m "TAU : Version $VERSION"
git pull origin
git push origin
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push  -f origin $VERSION
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

echo 'E.O.J'
