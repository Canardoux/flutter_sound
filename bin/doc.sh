#!/bin/bash

VERSION=$1

#echo "Generate dartdoc for flutter-sound"
rm -r doc/pages/flutter-sound/api 2>/dev/null
#cd flutter_sound
#flutter clean
#flutter pub get
#dartdoc --pretty-index-json  --output ../doc/pages/flutter-sound/api lib
#if [ $? -ne 0 ]; then
#    echo "Error"
    #exit -1
#fi
#cd ..

##rm doc/pages/flutter-sound/api/index.html
if [ ! -z "$VERSION" ]; then
        echo "Setting the tau version"
        gsed -i  "s/^tau_version:.*/tau_version: $VERSION/"                                     doc/_config.yml
        gsed -i  "s/^\( *version: \).*/\1$VERSION/"                                             doc/_data/sidebars/mydoc_sidebar.yml
fi

#rm -r doc/_site/pages/flutter-sound/web_example
#cp -a flutter_sound/example/build/web doc/_site/pages/flutter-sound/web_example
cp privacy_policy.html doc/_site

echo "Upload"
rm -rf flutter_sound/example/build flutter_sound/build
tar czf _toto3.tgz flutter_sound flutter_sound_web flutter_sound_platform_interface
cd doc
tar czf ../_toto.tgz *
cd ..
scp bin/doc2.sh canardoux@canardoux.xyz:/var/www/vhosts/canardoux.xyz/bin
scp _toto.tgz canardoux@canardoux.xyz:/var/www/vhosts/canardoux.xyz/
scp _toto3.tgz canardoux@canardoux.xyz:/var/www/vhosts/canardoux.xyz/
ssh -p7822 canardoux@canardoux.xyz "bash /var/www/vhosts/canardoux.xyz/bin/doc2.sh"
#ssh -p7822 canardoux@canardoux.xyz "rm -rf /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/*; tar xzf _toto.tgz -C /var/www/vhosts/canardoux.xyz/tau.canardoux.xyz/; rm _toto.tgz"

##cp doc/images/banner.png flutter_sound/example/build/web
rm _toto.tgz _toto2.tgz _toto3.tgz 2>/dev/null
