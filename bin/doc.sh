#!/bin/bash

VERSION=$1

rm -r doc/pages/flutter-sound/api 2>/dev/null
if [ ! -z "$VERSION" ]; then
        echo "Setting the tau version"
        gsed -i  "s/^tau_version:.*/tau_version: $VERSION/"                                     doc/_config.yml
        gsed -i  "s/^\( *version: \).*/\1$VERSION/"                                             doc/_data/sidebars/mydoc_sidebar.yml
fi

rm -rf flutter_sound/example/build flutter_sound/build
tar czf _toto3.tgz flutter_sound flutter_sound_web flutter_sound_platform_interface extract
cd doc
tar czf ../_toto.tgz *
cd ..
scp bin/doc2.sh canardoux@canardoux.xyz:/var/www/vhosts/canardoux.xyz/bin
scp _toto.tgz canardoux@canardoux.xyz:/var/www/vhosts/canardoux.xyz/
scp _toto3.tgz canardoux@canardoux.xyz:/var/www/vhosts/canardoux.xyz/
ssh -p7822 canardoux@canardoux.xyz "bash /var/www/vhosts/canardoux.xyz/bin/doc2.sh"
rm _toto.tgz _toto2.tgz _toto3.tgz 2>/dev/null

echo 'E.O.J'