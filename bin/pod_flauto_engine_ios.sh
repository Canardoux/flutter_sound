#!/bin/bash
if [ -z "$1" ]; then
	echo "Correct usage is $0 [VERSION]"
	exit -1
fi
export v=$1
gsed -i  's/^\( *s\.version *)/\1toto/' flauto_engine_ios.podspec
git add .
git commit -m 'pod_flauto_engine_ios.sh'
git push
git tag -f $1
git push --tag -f
pod cache clean --all
pod trunk push flauto_engine_ios.podspec
