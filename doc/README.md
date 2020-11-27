# The &tau; (tau) Project


The &tau; project is a set of libraries which deal with audio :

- A player for audio playback
- A recorder for recording audio
- Several utilities to handle audio files

&tau; is a big project. The goal is to share a maximum of the developments between various Platforms/Frameworks and various target OS.

## Overview

&tau; is a library package allowing you to play and record audio for both the `android` and `ios` platforms.

&tau; provides both a high level API and widgets for:

* play audio
* record audio

&tau; can be used to play a beep from an asset all the way up to implementing a complete media player.

The API is designed so you can use the supplied widgets or roll your own.

The &tau; package supports playback from:

* Assets
* Files
* URL


## Features

The &tau; package includes the following features :

- Play and Record &tau; or music with various codecs. (See [the supported codecs here](tau/codec.md#flutter-sound-codecs))
- Play local or remote files specified by their URL.
- Play assets.
- Record to a live stream Stream
- Playback from a live Stream
- The App playback can be controled from the device lock screen or from an Apple watch
- Play audio using the built in SoundPlayerUI Widget.
- Roll your own UI utilising the &tau; api.
- Record audio using the builtin SoundRecorderUI Widget.
- Roll your own Recording UI utilising the &tau; api.
- Support for releasing/resuming resources when the app pauses/resumes.
- Record to a Dart Stream
- Playback from a Dart Stream
- The App playback can be controled from the device lock screen or from an Apple watch


## Supported platforms

&tau; is actually supported by the following frameworks:
- Flutter (Flutter Sound)

In the future, it will be (perhaps) supported by
- React Native (Tau RN).  (Not yet. Later).
- Cordova (Tau Cordova).  (Not yet. Later).
- Others (Native Script, Solar 2D, ...)


## Supported targets

&tau; is actually supported by the following OS :

- iOS
- Android
- Web

In the future, it will be (perhaps) supported by
- Linux
- others (Windows, MacOS)


## What about Flutter Sound ?

Flutter Sound is not dead, of course. This is exactly the opposite.
Flutter Sound is a really alive project.

We just changed the name of the project, because we want to encompass others frameworks than Flutter.

-------------

&tau; is a fundamental building block needed by almost every mobile project.

I'm looking to make &tau; the go to project for mobile Audio with support for various platforms and various OS.

&tau; is a large and complex project which requires me to maintain multiple hardware platforms and test environments.

I greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation.
