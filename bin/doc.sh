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
ln -s  pages/flutter-sound/api/player/FlutterSoundPlayer-class.html dartdoc_player.html
ln -s  pages/flutter-sound/api/recorder/FlutterSoundRecorder-class.html dartdoc_recorder.html
ln -s  pages/flutter-sound/api/topics/Utilities-topic.html dartdoc_utilities.html
ln -s  pages/flutter-sound/api/topics/UI_Widgets-topic.html dartdoc_widgets.html

for dir in $(find pages/flutter-sound/api -type d)
do
        rel=`realpath --relative-to=$dir .`
        for f in *
        do
                ln -s $rel/$f $dir
        done
done
ln -s readme.html index.html
cd ../..

echo done

git add .
git commit -m "TAU : Version $VERSION"
git push
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push --tag -f
fi
git checkout gh-pages
#git merge master  "TAU : Version $VERSION"
rm -rf doc
git checkout master -- doc/_site
git add .
git commit -m "TAU : Version $VERSION"
git push
if [ ! -z "$VERSION" ]; then
        git tag -f $VERSION
        git push --tag -f
fi
git checkout master
