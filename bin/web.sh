#!/bin/bash

rm -rf  tau_core/web/js 2>/dev/null
cp -a -v  flutter_sound_web/js tau_core/web

rm -rf  flutter_sound/example/web/js 2>/dev/null
cp -a -v flutter_sound_web/js flutter_sound/example/web

cd flutter_sound/example
flutter build web
