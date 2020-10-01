#!/bin/bash
if [ -z "$1" ]; then
	echo "Correct usage is $0 [VERSION]"
	exit -1
fi
git add .
git commit -m 'pod_flauto_engine_ios.sh'
git push
git tag -f $1
git push --tag
pod cache clean --all
pod trunk push flauto_engine_ios.podspec
