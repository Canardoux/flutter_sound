---
title: Flutter Sound
permalink: fs-README.html
summary: The Flutter Sound Project README.
---
![pub version](https://img.shields.io/pub/v/flutter_sound.svg?style=flat-square)

![Flutter Sound](https://tau-ver.canardoux.xyz/images/fs/Logotype-primary.png)

## Documentation

- ## Flutter Sound user : your doc [is here](https://tau.canardoux.xyz/fs-README.html)
- ## The CHANGELOG [is here](https://tau.canardoux.xyz/fs-CHANGELOG.html)

## Flutter Sound stands for Ukraine

![PeaceForUkraine](https://tau-ver.canardoux.xyz/images/2-year-old-irish-girl-ukrainian.jpg)
Peace for Ukraine

![PrayForUkraine](https://tau-ver.canardoux.xyz/images/banner.png)
Pray for Ukraine

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
* Remote URL
* Dart Streams

The Flutter Sound package supports recording to:

* Dart buffers
* Files
* Dart Streams

## SDK requirements

* Flutter Sound requires an iOS 10.0 SDK \(or later\)
* Flutter Sound requires an Android 21 \(or later\)
* Flutter Sound is OK with the main Web browsers
   - Google Chrome
   - Firefox
   - Safari

## Examples \(Demo Apps\)

Flutter Sound comes with several [Demo/Examples](http://tau.canardoux.xyz/fs-ex___.html).

You can run a live view of these examples [here](http://tau.canardoux.xyz/live/fs/index.html).

## Features

The Flutter Sound package includes the following features :

* Play and Record sound or music with various codecs. \(See [the supported codecs here](/fs-guides_codec.html)\)
* Play local or remote files specified by their URL.
* Play assets.
* Record to a live dart Stream
* Playback from a live dart Stream
* Support for releasing/resuming resources when the app pauses/resumes.

## Flutter Sound and Streams

Streams support are a main Flutter Sound feature that is very exciting.

- Flutter Sound can record to a dart stream of audio data (PCM Float32 or PCM Int16). This let you process live audio data in dart, or send these data to a remote host.
- Flutter Sound can playback from a dart stream of audio data (PCM Float32 or PCM Int16). This let play live audio data generated from dart
(sequencer, sound generator, ...) or from a remote host.

You can look to the [FS Streams guide](http://tau.canardoux.xyz/fs-guides_streams.html).

## License

- Flutter Sound is published under the [MPL-2.0 License](http://tau.canardoux.xyz/fs-LICENSE.html).
- Flutter Sound is copyrighted by Dooboolab and Canardoux.
- Flutter Sound is now released under the permissive Mozilla license which has a **weak** *copyleft* clause: if you modify some of Flutter Sound code you must publish your modifications under the MPL license too. But you may publish your App with any license you want. Even a Proprietary/Closed-Sources License (shame on you!).
- The Tau documentation is published under the [Creative Commons CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.en) license.

## The τ family

The `Tau` family begins to be rich :). It is composed by those following Flutter plugins.

- `Flutter Sound 9.x` (this legacy plugin developed for many years)
- [Etau](https://pub.dev/packages/etau) (which is a port on Flutter Web of the W3C Web Audio API)
- [Tauweb](https://pub.dev/packages/tau_web) (which is the `Etau` implementation for Flutter Web)
- [Tauwar](https://pub.dev/packages/tau_war) (which is the `Etau` implementation for Flutter on mobiles)
- [Taudio](https://pub.dev/packages/taudio) (which is (will be) something like Flutter Sound 10.0)

### [Etau](https://pub.dev/packages/etau)

This is (will be) an implementation on flutter of the [W3C Web Audio API](https://www.w3.org/TR/webaudio-1.1).
Etau is actually in a developement state. It is an Alpha version. Even not a Beta version. There are many things to do before you can use it. Specially:

- A documentation (TODO)
- A support of the three main platforms:
   - Web
   - iOS (TODO)
   - Android (TODO)

The Web Audio API is terrific:

- It is a [W3C recommandation](https://www.w3.org/TR/webaudio-1.1)
- It has a great [documentation from Moziilla](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API)
- It is really powerful
- It is simple to use

Because the Web Audio API is a W3C recommandation, you can find very good documentations on the Web. Of course, the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) but also documentation from other sources.

In a few words, the Web Audio API let you assembly nodes as a Node Chain, from a Source Node (perhaps the mic), to a Destination Node (perhaps the speaker), threw several nodes able to process the sound (echo, analyzer, panner, distorder, ...). But you really should look to the Mozilla documentation which is very good.

Now, you will have to ask yourself if you must use [Taudio](https://pub.dev/packages/taudio) (which is just a wrapper around `Etau`), or directly [Etau](https://pub.dev/packages/etau).
The W3C recommandation is powerful but simple to use. There are probably no many reasons to use `Taudio` any longer.

`Etau` is (will be) released under the Gnu Public Licence v3 (GPL v3).

### [Taudio](https://pub.dev/packages/taudio)

The current Flutter Sound version is 9.x. [Taudio](https://pub.dev/packages/taudio) is a new name for Flutter Sound 10.0. `Taudio` is actually in a developement state. It is an Alpha version. Even not a Beta version. There are many things to do before you can use it. Specially:
- A documentation (TODO)
- A support of the three main platforms:
   - Web (TODO)
   - iOS (TODO)
   - Android (TODO)

`Taudio` is (will be) released under the Gnu Public Licence v3 (GPL v3). This mean that if you don't want, cannot or maynot release your App under a GPL License, you must stuck with Flutter Sound 9.x. This is not a big deal: Flutter Sound v 9.x will be maintain for a forseable future.

`Taudio` is a complete rewritten of Flutter Sound 9.x. It keeps compatibility with the Flutter Sound 9.x API but adds a new wrapper above [Etau](https://pub.dev/packages/etau).

## We need help

{% include important.html content="
We greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation.
"%}

Actually, I am almost alone to maintain and develop three important projects :
- Etau
- Flutter Sound 9.x
- Taudio (flutter Sound 10.0)

This is too much on my shoulders. We desesperatly need at least one other developer.

## Thanks

{% include note.html content="
### If you like my work, you can click on the `Thumb up` button of the top of the [pub.dev page](https://pub.dev/packages/flutter_sound).
This is free and this will reassure me that **I do not spend most of my life for nobody**.
"%}