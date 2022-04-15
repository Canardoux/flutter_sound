#!/bin/bash
rm -rf /tmp/toto_doc 2>/dev/null
mkdir -v /tmp/toto_doc 2>/tmp/null
tar xzf _toto.tgz -C /tmp/toto_doc 2>/dev/null
tar xzf _toto3.tgz  -C /tmp/toto_doc 2>/dev/null
rm -rf /tmp/toto_doc/_site /tmp/toto_doc/flutter_sound/example/ios 2>/dev/null
#####mv -v  /tmp/toto_doc/flutter_sound/example/samples  /tmp/toto_doc/flutter_sound/example/assets/

cd /tmp/toto_doc/flutter_sound/
export PATH="$PATH:/opt/flutter/bin"
export FLUTTER_ROOT=/opt/flutter
flutter clean
flutter pub get
/usr/lib/dart/bin/dart doc   lib 2>/dev/null
mv -v doc/api .



sed -i  "0,/^  overflow: hidden;$/s//overflow: auto;/"  api/static-assets/styles.css
sed -i  "s/^  background-color: inherit;$/  background-color: #2196F3;/" api/static-assets/styles.css

sed -i  "0,/^  overflow: hidden;$/s//overflow: auto;/"  /tmp/toto_doc/_site/pages/flutter-sound/api/static-assets/styles.css
sed -i  "s/^  background-color: inherit;$/  background-color: #2196F3;/" /tmp/toto_doc/_site/pages/flutter-sound/api/static-assets/styles.css

cd
echo "patch css for Jekyll compatibility"

echo "Add Front matter on top of dartdoc pages"
for f in $(find /tmp/toto_doc/api -name '*.html' )
do
        sed -i  "1i ---" $f
        #gsed -i  "1i toc: false" $f

        sed -i  "1i ---" $f
        sed -i  "/^<script src=\"https:\/\/ajax\.googleapis\.com\/ajax\/libs\/jquery\/3\.2\.1\/jquery\.min\.js\"><\/script>$/d" $f
done

echo "Building Jekyll doc"
cd /tmp/toto_doc
rm home.md 2>/dev/null
rm -rf /tmp/toto_doc/flutter_sound/example/ios/Pods 
bundle config set --local path '~/vendor/bundle'
bundle install
bundle exec jekyll build
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi

rm -rf /var/www/vhosts/canardoux.xyz/flutter_sound.canardoux.xyz/*
cp -a /tmp/toto_doc/_site/* /var/www/vhosts/canardoux.xyz/flutter_sound.canardoux.xyz/

cd ~/flutter_sound.canardoux.xyz/
echo "Symbolic links of the API"
echo "--------------------------"
for dir in $(find api -type d)
do
        rel=`realpath --relative-to=$dir .`
        echo "----- dir=$dir ----- rel=$rel"
        for d in */ ; do
            #echo "ln -s -v $rel/$d $dir"
            ln -s -v $rel/$d $dir
        done
        #for f in *
        #do
        #        ln -s $rel/$f $dir
        #done
done




cd ~/flutter_sound.canardoux.xyz/
ln -s -v readme.html index.html
#cd api/topics
#rm favico*
#ln -s ../../images/favico* .
#cd
cd
######rm _toto.tgz _toto3.tgz


echo "Live web example"
cd /tmp/toto_doc/flutter_sound/example

flutter build web
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd 

rm -rf /var/www/vhosts/canardoux.xyz/flutter_sound.canardoux.xyz/web_example/
cp -a /tmp/toto_doc/flutter_sound/example/assets/samples/ /tmp/toto_doc/flutter_sound/example/assets/extract /tmp/toto_doc/flutter_sound/example/build/web/assets
cp -a /tmp/toto_doc/flutter_sound/example/build/web /var/www/vhosts/canardoux.xyz/flutter_sound.canardoux.xyz/web_example
