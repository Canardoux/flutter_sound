#!/bin/bash

VERSION=$1

rm -r doc/pages/flutter-sound/api 2>/dev/null
if [ ! -z "$VERSION" ]; then
        echo "Setting the tau version"
        gsed -i  "s/^tau_version:.*/tau_version: $VERSION/"                                     doc/_config.yml
        gsed -i  "s/^\( *version: \).*/\1$VERSION/"                                             doc/_data/sidebars/mydoc_sidebar.yml
fi

cd flutter_sound
dart doc .
cd ..

cd doc
tar czf ../_toto.tgz *
cd ..
scp bin/doc2.sh canardoux@danku:/home/canardoux/bin
scp _toto.tgz canardoux@danku:/home/canardoux
ssh canardoux@danku "bash /home/canardoux/bin/doc2.sh"
rm _toto.tgz  2>/dev/null

echo 'E.O.J'
