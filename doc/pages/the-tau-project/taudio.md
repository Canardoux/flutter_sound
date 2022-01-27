---
title:  "Taudio Streams"
description: "RFC - Request For Comment"
summary: "Web Audio API on various frameworks."
permalink: taudio_rfc.html
tags: [rfc,taudio]
keywords: rfc, taudio
---

## Overview

`Taudio Streams` (or simply `Taudio`), is everything about W3C [Web Audio API](https://www.w3.org/TR/webaudio/).
You can look also to the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) which is very clear and that it is a pleasure to read it.

`Taudio Streams` will implent this API under various frameworks :

- Flutter
- Blazor
- Microsoft MAUI
- React Native
- ...

## Motivations

### Flutter Sound is just a draft

Flutter Sound has several API verbs to handle Audio Streams but very roughly:

- It does not support Flutter Web
- It does not support GNU/Linux
- It runs only on Flutter Android and Flutter iOS
- It supports only Raw PCM-INTEGER-16 Little Endian
- It does not support Stereo
- The code was *two-headed* (the code for Audio Streams and for Media-Players/Recorders are completely independant of each others).
- The code is complicate and hard to maintain
- The latency was too important on Android

### Tau Sound was just a dream

During many months, we had the project to implement [Audio Graphs](/guides_graph.html) inside Flutter Sound.
This project was called `TauSound`.

TauSound was killed a few weeks ago because:

- The API was very difficult to specify, and we were sure that we will have to modify it very often.
- It added complexity inside an already complecated library.
- We was realizing that we tried to define something that was already defined by the W3C. If you look to Web Audio API, you will see that whe were trying to do something already done. And done really perfectely.

### W3C - Web Audio API

W3C did a fantastic job with the specification of this API.

More, this API is completely implemented inside the main Web Browser :

- Microsoft Edge
- Google Chrome
- Mozilla Firefox
- Apple Safari

It means that we do not have to develop anything new for Web support.

Flutter Sound on Web was second-class citizen. Taudio on Web will be first-class citizen:
The problems will not be on Web but on the native side (iOS, Android, GNU/Linux, ...)

W3C specified many great things like :

- [Andio Graphs](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Basic_concepts_behind_Web_Audio_API#audio_graphs)
- [Visualisation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Basic_concepts_behind_Web_Audio_API#visualizations)
- [Spatialisation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Basic_concepts_behind_Web_Audio_API#spatialisations)

The recommandation allow anybody to build custom nodes and insert them inside their graphs.
It would be fantastic to be able to code custom nodes in Dart.

## Architecture/Design

The Taudio architecture is actually not fully designed.
For information you can look to [The Flutter Sound Architecture](/architecture.html).

Flutter Sound Architecture is complicate. It has been designed so that a port to other frameworks will be easy.
Unfortunatly, Flutter Sound has never been ported elswhere than:

- Flutter iOS
- Flutter Android
- and a little bit Flutter web

Actually it is not clear if we can have a simpler design for Taudio, without compromising portability.

## Roadmap

Taudio can be a very large project, which will busy us during several years.

It is important to define several milestones to be able to understand where we will be during those years.

### 1 - Taudio Streams on Flutter Web

This milestone is probably not very difficult.
The goal is just to offer the W3C API to Flutter Web.
We do not expect many problems : we will probably just implement the interface to call Javascript from Dart.

The documentation will be very simple : we do not want to rewrite the Mozilla documentation which is really very good.
Probably the documentation will only be the correspondance between Dart and Javascript.
This documentation will be in the Dart code itself. No need to write several Markdown documentation.

In this milestone, we will code most of the W3C and Mozilla examples as Flutter Examples.

### 2 - Taudio Player/Recorder on Flutter

This milestone is probably very simple. Everything will be coded in Flutter with pure Dart.
The goal is to offer a very high API for major simple graphs. For example a MP3 player.
With this API, the developer will not have to build himself/herself the graphs.
The API will be similar to Flutter Sound or Just Audio, but not identical.

This step will simplify the migration from Flutter Sound on Web, which is actually not very good.

In this milestone we will port the Flutter Sound examples.

### 3 - Taudio on Blazor

Blazor is Microsoft`s framework to build Web App with C#.
This framework is similar to Flutter Web.
Blazor compile to webasm.

We do not expect more problems than with the first milestone : the purpose of this step is to build an interface
between C# and Javascript.

In this milestone, we will code most of the W3C and Mozilla examples as Blazor Examples.

### 4 - Taudio Streams for Flutter iOS

This milestone is much more complicate that the previous ones.
We will have to implement the W3C API for native iOS.

We do not think that it will be doable to implements the many dozen of the different nodes specified by the W3C.
We will have to limit ourself to the major types of nodes.
We are not musician, and implement an audio-compressor, for example, is probably not doable for us.

We will document how to code custom nodes, so that musicians will be able to code the nodes types they need, as flutter plugins.

The implementation of this milestone can be:

- 1. Mostly coded on the Flutter side, in dart. The code in Dart will be shared between Flutter iOS and Flutter Android, but will need to be recoded for others Framework like React Native
- 2. Mostly coded on the iOS side, in Objective-C. The code in Objective-C and other frameworks will be shared, but we will have to recode on Java the Android stuff.
- 3. A mix between some development in Dart, and some development in Objective-C.
- 4. Coded with a real portable language like C++ or Rust. *(Not sure that it is doable)*

For this milestone, we will try to find free and open source code already existing on the web that can be used.
For example :

- [flutter_oboe](https://pub.dev/packages/oboe)
- [cpal](https://github.com/RustAudio/cpal)
- [Rust Crates](https://crates.io/crates/web-audio-api/0.14.0)
- ...

### 5 - Taudio Streams for Flutter Android

This milestone is similar to the milestone `4 - Taudio Streams for Flutter iOS`.

Everything which has been coded on Objective-C will have to be recoded on Java.

Our experience with Flutter Sound shows a real problem with latency.
Perhaps [flutter_oboe](https://pub.dev/packages/oboe) can help doing something better

### 6 - Taudio Streams for Desktop

A port of our library on desktops is something that we want. Specially GNU/Linux.

We can port Taudio on:

- Microsoft MAUI
- Flutter Desktop
- Electron
- ...

We will have to make a choice. We cannot support all the existing frameworks existing in 2022.

### 7 - Other frameworks

Many frameworks would be good candidate for Taudio:

- React Native
- Cordova/Capacitor
- Native Script
- Solar-2D
- ...

We definitely cannot support everything. Perhaps we will do depending on oportunity.

### 8 - A graphic editor

My dream is to build a graphic Audio Graph with a mouse.
We will drag and drop Audio nodes to the graph, and draw the channels between them.

The nodes attributs will be specified by menu.

We will have a test/pause/resume button so that the Audio Graph designer will have an overview of how the sound is processed.

This milestone is probably not useful. But it will be funny to do.
But this is milestone (8). I will probably be dead before reaching it.

## Conclusion

This project is huge. There are many things to master :

- Dart
- Flutter
- C#
- Blazor
- Dotnet
- MAUI
- Electron (maybe)
- React Native (maybe)
- Rust (maybe)

And of course :

- Java
- Objective C
- C++

We probably will have to kill some of the 8 milestones. But not actually sure which ones.

