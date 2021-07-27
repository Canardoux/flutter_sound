#!/bin/bash
rm -rf /tmp/toto_doc 2>/dev/null
mkdir -v /tmp/toto_doc 2>/tmp/null
tar xzf _toto.tgz -C /tmp/toto_doc
tar xzf _toto3.tgz  -C /tmp/toto_doc
rm -rf /tmp/toto_doc/_site /tmp/toto_doc/flutter_sound/example/ios 2>/dev/null
#####cp -a /tmp/toto_doc/_site/* /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/

cd /tmp/toto_doc/flutter_sound/
export PATH="$PATH:/opt/flutter/bin"
export FLUTTER_ROOT=/opt/flutter
flutter clean
flutter pub get
/usr/lib/dart/bin/dartdoc --pretty-index-json  --output /tmp/toto_doc/api lib
cd



echo "patch css for Jekyll compatigility"

sed -i  "0,/^  overflow: hidden;$/s//overflow: auto;/"  /tmp/toto_doc/_site/pages/flutter-sound/api/static-assets/styles.css
sed -i  "s/^  background-color: inherit;$/  background-color: #2196F3;/" /tmp/toto_doc/_site/pages/flutter-sound/api/static-assets/styles.css

echo "Add Front matter on top of dartdoc pages"
for f in $(find /tmp/toto_doc/_site/pages/flutter-sound/api -name '*.html' )
do
        sed -i  "1i ---" $f
        #gsed -i  "1i toc: false" $f

        sed -i  "1i ---" $f
        sed -i  "/^<script src=\"https:\/\/ajax\.googleapis\.com\/ajax\/libs\/jquery\/3\.2\.1\/jquery\.min\.js\"><\/script>$/d" $f
done




echo "Building Jekyll doc"
cd /tmp/toto_doc
rm home.md 2>/dev/null
bundle config set --local path '~/vendor/bundle'
bundle install
bundle exec jekyll build
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi

cp -a /tmp/toto_doc/api /tmp/toto_doc/_site/pages/flutter-sound/api


echo "Symbolic links"
#FILES=*
cd /tmp/toto_doc/_site
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

rm -rf /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/*
cp -a /tmp/toto_doc/_site/* /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/

cd
rm _toto.tgz _toto3.tgz


echo "Live web example"
cd /tmp/toto_doc/flutter_sound/example

flutter build web
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd 

rm -rf /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/web_example/
cp -a /tmp/toto_doc/flutter_sound/example/assets/samples/ /tmp/toto_doc/flutter_sound/example/assets/extract /tmp/toto_doc/flutter_sound/example/build/web/assets
cp -a /tmp/toto_doc/flutter_sound/example/build/web /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/web_example
