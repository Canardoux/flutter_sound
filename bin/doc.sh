#!/bin/bash

VERSION=$1

rm -r doc/flutter_sound/api/*
dartdoc --pretty-index-json --input flutter_sound --output doc/flutter_sound/api


git add .
git commit -m "TAU : Version $VERSION"
git push
if [ ! -z "$VERSION" ]
        git tag -f $VERSION
        git push --tag -f
fi
git checkout gh-pages
git merge master
git push
git checkout master
