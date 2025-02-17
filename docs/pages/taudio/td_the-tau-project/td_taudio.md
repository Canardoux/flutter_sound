---
title:  "Taudio Streams (RFC)"
description: "RFC - Request For Comment"
summary: "Web Audio API on various frameworks."
permalink: td_taudio_rfc.html
sidebar: fs_sidebar
tags: [rfc,taudio]
keywords: rfc, taudio
---

## Overview

_Taudio Streams_ (or simply _Taudio_), is everything about W3C [Web Audio API](https://www.w3.org/TR/webaudio/).
You can look also to the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) which is very clear and that it is a pleasure to read it.

_Taudio Streams_ will implent this API under various frameworks :

- Flutter
- Blazor
- Microsoft MAUI
- React Native
- ...

## Motivation for TAudio

### Flutter Sound is just a draft

Flutter Sound has several API verbs to handle Audio Streams but comes with some limitations:

- It does not support Flutter Web
- It does not support GNU/Linux
- It runs only on Flutter Android and Flutter iOS
- It supports only Raw PCM-INTEGER-16 Little Endian
- It does not support Stereo
- It does not support events with DB level
- The code was *two-headed* (the code for Audio Streams and for Media-Players/Recorders are completely independant of each others).
- The code is complicate and hard to maintain
- The latency was too important on Android

### Tau Sound was just a dream

During many months, we had the project to implement [Audio Graphs](/guides_graph.html) inside Flutter Sound.
This project was called _TauSound_.

TauSound was killed off a few weeks ago because:

- The API was overly complex and hard to maintain
- It added complexity inside an already complicated library.
- It dawned on us that we wre re-inventing the wheel ; W3C already had functionality in place that we were trying to implement. If you look to the [Web Audio API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API), you will see that we were trying to do something that had already been perfected.

### W3C - Web Audio API

W3C did a fantastic job with the specification of this API.

Furthermore, this API is already completely implemented inside a host of mainstream WEB Browsers:

- Microsoft Edge
- Google Chrome
- Mozilla Firefox
- Apple Safari

It means that we do not have to develop anything new for Web support.

Flutter Sound on Web was really a second-class citizen. Taudio on Web will be first-class citizen:
The problems will not be on Web but on the native side (iOS, Android, GNU/Linux, ...)

W3C specified many great things like :

- [Audio Graphs](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Basic_concepts_behind_Web_Audio_API#audio_graphs)
- [Visualisation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Basic_concepts_behind_Web_Audio_API#visualizations)
- [Spatialisation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Basic_concepts_behind_Web_Audio_API#spatialisations)

The recommandation allows anybody to build custom nodes and insert them inside their graphs.
It would be fantastic for our users to be able to code custom nodes in Dart.

## Architecture/Design

The Taudio architecture is actually not yet fully designed.
For information you can look to [The Flutter Sound Architecture](/architecture.html).

Flutter Sound Architecture is ridiculously complicated. It was designed so that a port to other frameworks would be easy.
Unfortunatly this complexity was not useful because Flutter Sound has never been ported anywhere other than:

- Flutter iOS
- Flutter Android
- and a little bit Flutter web

Actually it is not clear if we can have a simpler design for Taudio, without compromising portability.

Here is a possible design, using a portable language as Rust or C++

{% include image.html file="taudio-architecture.svg"  caption="The Taudio architecture" %}



## Roadmap

Taudio can be a very large project, which will keep us busy for several years.

It is important to define several milestones to be able to understand where we will be during those years.

### 0 - Project launch (mandatory)

This step is not about coding, but about doing things which are required to launch the project

We will :

- Setup a Git repo
- Choose a documentation tool
- Setup the documentation. It can be:
  - Jekyll (same as Flutter Sound and compatible with dartdoc)
  - Notion.so (which is close source)
  - Hugo
  - Gatsby
  - Docusaurus
  - Git Book (which is close source)
  - ... other ...
- Choose a Project Management tool (if any)
- Choose an Issue Tracker tool (if any)
- Define an architecture
- Setup all the examples from W3C and Mozilla in pure Javascript

Porting the examples in Javascript is just copy and past from W3C and Mozilla.
This is useful because :

- We will get familiar with Web Audio API
- We will have a regular implementation in pure Javascript of what we want to achieve with other frameworks not Javascript

### 1 - Taudio Streams on Flutter Web (mandatory)

This milestone is probably not very difficult.
The goal is just to offer the W3C API to Flutter Web.
We do not expect many problems : we will probably just implement the interface to call Javascript from Dart.

The documentation will be very simple : we do not want to rewrite the Mozilla documentation which is really very good.
Probably the documentation will only be the correspondance between Dart and Javascript.
This documentation will be in the Dart code itself. No need to write several Markdown documentation as we did for Flutter Sound.

In this milestone, we will code most of the W3C and Mozilla examples as Flutter Examples.

### 2 - Taudio Player/Recorder on Flutter (optional)

This milestone is probably very simple. Everything will be coded in Flutter with pure Dart.
The goal is to offer a very high API for major simple graphs. For example a MP3 player.
With this API, the developer will not have to build himself/herself his/her graphs.
The API will be similar to Flutter Sound or Just Audio, but not identical.

In this milestone we will port the Flutter Sound examples.

This step will simplify the migration from Flutter Sound on Web, which is actually not very good.

We may skip this milestone if we decide that Taudio is only a port of Web Audio API on flutter but we do not want to be a Flutter Sound replacement.
We may also delay this mileston after #5 (after the impmentation of TaudioStreams on Flutter iOS and Flutter Android).

### 3 - Taudio on Blazor (optional)

Blazor is Microsoft`s framework to build Web App with C#.
This framework is similar to Flutter Web.
Blazor compile to webasm.

We do not expect more problems than with milestone #1 : the purpose of this step is to build an interface
between C# and Javascript instead of Dart and Javascript.

In this milestone, we will code most of the W3C and Mozilla examples as Blazor Examples.

We may skip this milestone if we decide that we are only interested by Flutter and the knowledge of other frameworks will be to hard for us.
We may also delay this milestone after #5 (after the impmentation of TaudioStreams on Flutter iOS and Flutter Android).

### 4 - Taudio Streams for Flutter iOS (mandatory)

This milestone is much more complicate that the previous ones.
We will have to implement the W3C API for native iOS.

We do not think that it will be doable to implements the many dozen of the different nodes specified by the W3C.
We will have to limit ourself to the major types of nodes.
We are not musician, and implement an audio-compressor, for example, is probably not doable for us without borrowing the algorythm from elsewhere.

We will document how to code custom nodes, so that musicians will be able to code the nodes types they need, as many flutter plugins.

The implementation of this milestone can be:

- Mostly coded on the Flutter side, in dart. The code in Dart will be shared between Flutter iOS and Flutter Android, but will need to be recoded for others Framework like React Native
- Mostly coded on the iOS side, in Objective-C. The code in Objective-C will be shared with other frameworks , but we will have to recode onwith Java the iOS stuff.
- A mix between some development in Dart, and some development in Objective-C.
- Coded with a real portable language like C++ or Rust. *(Not sure that it is doable)*

For this milestone, we will try to find some FOSS already existing on the web that can be used.
For example :

- [flutter_oboe](https://pub.dev/packages/oboe)
- [cpal](https://github.com/RustAudio/cpal)
- [Rust Crates](https://crates.io/crates/web-audio-api/0.14.0)
- The code source of Chromium
- The code source of Firefox
- ...

### 5 - Taudio Streams for Flutter Android (mandatory)

This milestone is similar to the milestone #4 and will be also difficult.

Everything which has been coded on Objective-C will have to be recoded on Java.

Note: our experience with Flutter Sound shows a real problem with latency.
Perhaps [flutter_oboe](https://pub.dev/packages/oboe) can help doing something better

### 6 - Taudio Streams for Desktop (optional)

A port of our library on desktops is something that we probably want. Specially on GNU/Linux.

We can port Taudio on:

- Microsoft MAUI
- Flutter Desktop
- Electron
- ...

We will have to make a choice. We cannot support all the existing frameworks existing in 2022.
We may also declare that we are not interested by using Taudio on desktops.

### 7 - Other frameworks (optional)

Many frameworks would be good candidate for Taudio:

- React Native
- Cordova/Capacitor
- Native Script
- Solar-2D
- ...

We definitely cannot support everything. Probably we will do our choices based on oportunities.

### 8 - A graphic editor (optional)

My dream is to build a graphic Audio Graph with a mouse.
We will drag and drop Audio nodes to the graph, and draw the channels between them.

The nodes attributs will be specified by menu.

We will have a test/pause/resume button so that the Audio Graph designer will have an audio preview of how the sound is processed.

This milestone is probably not useful. But it will be funny to do it.

This is milestone #8. I will probably be dead before reaching it :-( .

## The license

The license issue is for me somthing very important that we must determine during milestone #0.

I strongly insist to publish Taudio under The GNU GPL license.
The GPL license has a very strong copyleft clause : nobody can borrow all or part of the project without publishing all his/her software under GPL, too.

I cannot accept the idea to work during several years on a project badly protected by a license like MIT.

Taudio must be free not only today, but for ever.
MIT and even MPL are for me really bad licenses.

## Conclusion

This project is huge. There are many things to master :

- The W3C specifications
- Dart
- Flutter
- C# (maybe)
- Blazor (maybe)
- Dotnet (maybe)
- MAUI (maybe)
- Electron (maybe)
- React Native (maybe)
- Rust (maybe)

And of course :

- Java
- Objective C
- C++

We probably will have to kill some of the 8 milestones, however - we are yet to decide which ones.
