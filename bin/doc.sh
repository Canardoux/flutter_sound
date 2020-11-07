#!/bin/bash

rm -r doc/flutter_sound/api/*
dartdoc --pretty-index-json --input flutter_sound --output doc/flutter_sound/api

