#!/bin/bash

VERSION=$1


echo "Front matter"
for f in $(find doc/pages/flutter_sound/api -name '*.html' )
do
        echo $f
        gsed -i  "1i ---" $f
        gsed -i  "1i ---" $f
done
echo done

git add .
git commit -m "TAU : Version $VERSION"
git push
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push --tag -f
fi
