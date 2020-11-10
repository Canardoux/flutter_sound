#!/bin/bash

VERSION=$1

cd flutter_sound/example
flutter build web
cd ../..
rm -r doc/flutter_sound/web_example
cp -a flutter_sound/example/build/web doc/flutter_sound/web_example


rm -r doc/flutter_sound/api/*
dartdoc --pretty-index-json --input flutter_sound --output doc/flutter_sound/api



cd  doc
rm -r _book book
gitbook build
mv _book book
cd ..

cd doc
git add .
git commit -m "TAU : documentation Version $VERSION"
#git push
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
