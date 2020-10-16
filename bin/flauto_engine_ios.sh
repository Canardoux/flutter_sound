#!/bin/bash
if [ -z "$1" ]; then
	echo "Correct usage is $0 [VERSION]"
	exit -1
fi
export v=$1
gsed -i  "s/^\( *s.version *= *\).*$/\1'$1'/" flauto_engine_ios.podspec
gsed -i  "s/^\( *s.dependency *'flauto_engine_ios', *\).*$/\1'$1'/" flutter_sound/ios/flutter_sound.podspec
git add .
git commit -m "flauto_engine_ios.sh : Version $1"
git push
git tag -f flauto_engine_$1
git push --tag -f
pod cache clean --all
pod trunk push flauto_engine_ios.podspec
