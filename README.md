---
title: Flutter Sound
description: The Flutter Sound Project README
permalink: fs-README.html
summary: The Flutter Sound Project README.
---
## Documentation

- ## Flutter Sound user : your doc [is here](https://tau.canardoux.xyz/fs-README.html)
- ## The CHANGELOG [is here](https://tau.canardoux.xyz/fs-CHANGELOG.html)

## Flutter Sound stands for Ukraine

{% include image.html file="2-year-old-irish-girl-ukrainian.jpg"  caption="Peace for Ukraine" %}
{% include image.html file="banner.png"  caption="Stand up For Ukraine : Street Art" %}

![pub version](https://img.shields.io/pub/v/flutter_sound.svg?style=flat-square)

## Flutter Sound as a τ Project

Flutter Sound is a set of libraries which deal with audio :

- A player for audio playback
- A recorder for recording audio
- Several utilities to handle audio files

![Demo](https://user-images.githubusercontent.com/27461460/77531555-77c9ec00-6ed6-11ea-9813-320f943b08cc.gif)

## Overview

Flutter Sound is a library package allowing you to play and record audio for :

* iOS
* Android
* Web

The Flutter Sound package supports playback from:

* Dart buffers
* Assets
* Files
* URL
* Streams

The Flutter Sound package supports recording to:

* Dart buffers
* Files
* Streams

## SDK requirements

* Flutter Sound requires an iOS 10.0 SDK \(or later\)
* Flutter Sound requires an Android 21 \(or later\)

## Examples \(Demo Apps\)

Flutter Sound comes with several [Demo/Examples]((https://github.com/Canardoux/flutter_sound/tree/master/example/lib)).

You can run a live view of these examples [here](TODO).

## Features

The Flutter Sound package includes the following features :

* Play and Record τ or music with various codecs. \(See [the supported codecs here](fs_guides_codec.html)\)
* Play local or remote files specified by their URL.
* Play assets.
* Record to a live stream Stream
* Playback from a live Stream
* Support for releasing/resuming resources when the app pauses/resumes.
* Record to a Dart Stream
* Playback from a Dart Stream

## Flutter Sound and Streams

Streams support are a main Flutter Sound feature that you must not overview.

- Flutter Sound can record to a dart stream of audio data (PCM Float32 or PCM Int16). This let you process live audio data in dart, or send these data to a remote host.
- Flutter Sound can playback from a dart stream of audio data (PCM Float32 or PCM Int16). This let play live audio data generated from dart
(sequencer, sound generator, ...) or from a remote host.

You can look to the [FS Streams guide](fs_guides_streams.html).

## License

- Flutter Sound is published under the MPL-2.0 License.
- Flutter Sound is copyrighted by Dooboolab and Canardoux.
- Flutter Sound is now released under the permissive Mozilla license which has a **weak** *copyleft* clause: if you modify some of Flutter Sound code you must publish your modifications under the MPL license too. But you may publish your App with any license you want. Even a Proprietary/Closed-Sources License (shame on you!).

## Taudio

The current Flutter Sound version is 9.x. [Taudio](TODO) is a new name for Flutter Sound 10.0. Taudio is actually in a developement state. It is an Alpha version. Even not a Beta version. There are many things to do before you can use it. Specially:
- A documentation (TODO)
- A support of the three main platforms:
   - Web
   - iOS (TODO)
   - Android (TODO)

Taudio is (will be) released under the Gnu Public Licence v3 (GPL v3). This mean that if you don't want, cannot or maynot release your App under a GPL License, you must stuck with Flutter Sound 9.x. This is not a big deal: Flutter Sound v 9.x will be maintain for a forseable future.

Taudio is a complete rewritten of Flutter Sound 9.x. It keeps compatibility with the Flutter Sound 9.x API but adds a new wrapper above [Etau](TODO]).

## Etau

This is (will be) an implementation on flutter of the [W3C Web Audio API](TODO).
Etau is actually in a developement state. It is an Alpha version. Even not a Beta version. There are many things to do before you can use it. Specially:

- A documentation (TODO)
- A support of the three main platforms:
   - Web
   - iOS (TODO)
   - Android (TODO)

The Web Audio API is terrific:

- It is a W3C recommandation
- It has a great [documentation from Moziilla](TODO)
- It is really powerful
- It is simple to use

Because the Web Audio API is a W3C recommandation, you can find very good documentations on the Web. Of course, the Mozilla documentation but also from other sources.
In a few words, the Web Audio API let you assembly `nodes` as a string, from a Source Node (perhaps the mic), to a Destination Node (perhaps the speaker), threw several nodes able to process the sound (echo, analyzer, panner, distorder, ...). But you should look to the Mozilla documentation which is very good.

You will have to ask yourself if you must use Taudio (which is a wrapper around Etau), or directly Etau.
The W3C recommandation is powerful but simple to use. There are probably not many reason to use Taudio.

Etau is (will be) released under the Gnu Public Licence v3 (GPL v3).

## We need help

{% include important.html content="
We greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation.
"%}.

Actually, I am almost alone to maintain and develop three important projects :
- Flutter Sound 9.x
- Taudio (flutter Sound 10.0)
- Etau

This is too much on my shoulders. We desesperatly need at least one other developer.

## Thanks

{% include note.html content="
If you like my work, you can click on the `Thumb up` button of the top of the [pub.dev page](https://pub.dev/packages/flutter_sound).
This is free and this will reassure me that **I do not spend most of my life for nobody**.
" %}