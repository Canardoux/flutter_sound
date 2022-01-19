#!/bin/bash

echo "web.sh"
echo "------"
rm -rf  flutter_sound_core/web/js 2>/dev/null
cp -a -v flutter_sound/example/web/js flutter_sound_core/web

rm -rf  flutter_sound_web/js 2>/dev/null
cp -a -v flutter_sound/example/web/js flutter_sound_web/

cd flutter_sound/example
flutter build web
