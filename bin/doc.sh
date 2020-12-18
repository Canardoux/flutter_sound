#!/bin/bash

VERSION=$1


rm -r doc/pages/flutter-sound/api
cd flutter_sound
flutter clean
flutter pub get
dartdoc --pretty-index-json  --output ../doc/pages/flutter-sound/api
cd ..

if [ ! -z "$VERSION" ]; then
        gsed -i  "s/^tau_version:.*/tau_version: $VERSION/"                                     doc/_config.yml
        gsed -i  "s/^\( *version: \).*/\1$VERSION/"                                             doc/_data/sidebars/mydoc_sidebar.yml
fi

gsed -i  "0,/^  overflow: hidden;$/s//overflow: auto;/"  doc/pages/flutter-sound/api/static-assets/styles.css
gsed -i  "s/^  background-color: inherit;$/  background-color: #2196F3;/" doc/pages/flutter-sound/api/static-assets/styles.css

echo "Front matter"
for f in $(find doc/pages/flutter-sound/api -name '*.html' )
do
        gsed -i  "1i ---" $f
        #gsed -i  "1i toc: false" $f

        gsed -i  "1i ---" $f
        gsed -i  "/^<script src=\"https:\/\/ajax\.googleapis\.com\/ajax\/libs\/jquery\/3\.2\.1\/jquery\.min\.js\"><\/script>$/d" $f
done
rm -rf doc/_site

echo jekyll build
cd doc
rm home.md 2>/dev/null
bundle exec jekyll build 2>/dev/null
cd ..


echo symbolic links
#FILES=*
cd doc/_site
#cp index.html home.html
ln -s  pages/flutter-sound/api/index.html dartdoc.html
for dir in $(find pages/flutter-sound/api -type d)
do
        rel=`realpath --relative-to=$dir .`
        for f in *
        do
                ln -s $rel/$f $dir
        done
done
ln -s README.html index.html
cd ../..

echo done
exit 0
git add .
git commit -m "TAU : Version $VERSION"
git push
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push --tag -f
fi
