#!/bin/bash

VERSION=$1

echo "Generate dartdoc for flutter-sound"
rm -r doc/pages/flutter-sound/api
cd flutter_sound
flutter clean
flutter pub get
dartdoc --pretty-index-json  --output ../doc/pages/flutter-sound/api lib
if [ $? -ne 0 ]; then
    echo "Error"
    #exit -1
fi
cd ..

##rm doc/pages/flutter-sound/api/index.html
if [ ! -z "$VERSION" ]; then
        echo "Setting the tau version"
        gsed -i  "s/^tau_version:.*/tau_version: $VERSION/"                                     doc/_config.yml
        gsed -i  "s/^\( *version: \).*/\1$VERSION/"                                             doc/_data/sidebars/mydoc_sidebar.yml
fi

echo "patch css for Jekyll compatigility"
gsed -i  "0,/^  overflow: hidden;$/s//overflow: auto;/"  doc/pages/flutter-sound/api/static-assets/styles.css
gsed -i  "s/^  background-color: inherit;$/  background-color: #2196F3;/" doc/pages/flutter-sound/api/static-assets/styles.css

echo "Add Front matter on top of dartdoc pages"
for f in $(find doc/pages/flutter-sound/api -name '*.html' )
do
        gsed -i  "1i ---" $f
        #gsed -i  "1i toc: false" $f

        gsed -i  "1i ---" $f
        gsed -i  "/^<script src=\"https:\/\/ajax\.googleapis\.com\/ajax\/libs\/jquery\/3\.2\.1\/jquery\.min\.js\"><\/script>$/d" $f
done

echo "Building Jekyll doc"
rm -rf doc/_site
cd doc
rm home.md 2>/dev/null
bundle exec jekyll build
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..


echo "Symbolic links"
#FILES=*
cd doc/_site
#ln -s  pages/flutter-sound/api/index.html dartdoc.html
#ln -s  pages/flutter-sound/api/player/FlutterSoundPlayer-class.html dartdoc_player.html
#ln -s  pages/flutter-sound/api/recorder/FlutterSoundRecorder-class.html dartdoc_recorder.html
#ln -s  pages/flutter-sound/api/topics/Utilities-topic.html dartdoc_utilities.html
#ln -s  pages/flutter-sound/api/topics/UI_Widgets-topic.html dartdoc_widgets.html

for dir in $(find pages/flutter-sound/api -type d)
do
        rel=`realpath --relative-to=$dir .`
        for d in */ ; do
            ln -s $rel/$d $dir
        done
        #for f in *
        #do
        #        ln -s $rel/$f $dir
        #done
done
ln -s readme.html index.html
cd ../..

echo "Live web example"
#rm -r doc/_site/pages/flutter-sound/web_example
#cp -a flutter_sound/example/build/web doc/_site/pages/flutter-sound/web_example
cp privacy_policy.html doc/_site

echo "Upload"
cd doc/_site
tar czf ../../_toto.tgz *
cd ../..
scp _toto.tgz canardoux@canardoux.xyz:/var/www/vhosts/canardoux.xyz/
ssh -p7822 canardoux@canardoux.xyz "rm -rf /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/*; tar xzf _toto.tgz -C /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/; rm _toto.tgz"

##cp doc/images/banner.png flutter_sound/example/build/web
cp -a -v flutter_sound/example/assets/samples flutter_sound/example/assets/extract flutter_sound/example/build/web/assets

cd flutter_sound/example/build/web
tar czf ../../../../_toto2.tgz *
cd ../../../..
scp _toto2.tgz canardoux@canardoux.xyz:/var/www/vhosts/canardoux.xyz/
ssh -p7822 canardoux@canardoux.xyz "rm -rf /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/web_example; mkdir -p /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/web_example; tar xzf _toto2.tgz -C /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/web_example; rm _toto2.tgz"
rm _toto.tgz _toto2.tgz
