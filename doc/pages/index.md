---
title: Flutter Sound
description: The Flutter Sound Project README
keywords: home homepage readme
tags: [FlutterSound]
permalink: readme.html
summary: The Flutter Sound documentation.
---

{% include image.html file="2-year-old-irish-girl-ukrainian.jpg"  caption="Peace for Ukraine" %}
{% include image.html file="banner.png"  caption="Stand up For Ukraine : Street Art" %}

![pub version](https://img.shields.io/pub/v/flutter_sound.svg?style=flat-square)

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

Flutter Sound provides both a high level API and widgets for:

* play audio
* record audio

Flutter Sound can be used to play a beep from an asset all the way up to implementing a complete media player.

The API is designed so you can use the supplied widgets or roll your own.

The Flutter Sound package supports playback from:

* Assets
* Files
* URL
* Streams

## SDK requirements

* Flutter Sound requires an iOS 10.0 SDK \(or later\)
* Flutter Sound requires an Android 21 \(or later\)

## Examples \(Demo Apps\)

Flutter Sound comes with several Demo/Examples :

[The `examples App`](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/main.dart) is a driver which can call all the various examples.

## Features

The Flutter Sound package includes the following features :

* Play and Record τ or music with various codecs. \(See [the supported codecs here](guides_codec.html)\)
* Play local or remote files specified by their URL.
* Play assets.
* Record to a live stream Stream
* Playback from a live Stream
* The App playback can be controlled from the device lock screen or from an Apple watch
* Play audio using the built in \[SoundPlayerUI\] Widget.
* Roll your own UI utilizing the τ api.
* Record audio using the builtin \[SoundRecorderUI\] Widget.
* Roll your own Recording UI utilizing the τ api.
* Support for releasing/resuming resources when the app pauses/resumes.
* Record to a Dart Stream
* Playback from a Dart Stream
* The App playback can be controlled from the device lock screen or from an Apple watch

## License

- Flutter Sound is published under the MPL-2.0 License.
- Flutter Sound is copyrighted by Dooboolab and Canardoux.

* Flutter Sound is now released under the permissive Mozilla license which has a **weak** *copyleft* clause: if you modify some of Flutter Sound code you must publish your modifications under the MPL license too. But you may publish your App with any license you want. Even a Proprietary/Closed Sources License (shame on you!).

## We need help

{% include important.html content="We greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation."%}

## Thanks

<a href="https://www.buymeacoffee.com/larpoux"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=💛&slug=larpoux&button_colour=5F7FFF&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00"></a>
[![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/thetauproject?locale.x=fr_FR)

{% include note.html content="You can also click on the `Thumb up` button of the top of the [pub.dev page](https://pub.dev/packages/flutter_sound).
This is free and this will reassure me that **I do not spend most of my life for nobody**." %}

<script data-name="BMC-Widget" src="http://cdnjs.buymeacoffee.com/1.0.0/widget.prod.min.js" data-id="larpoux" data-description="Support me on Buy me a coffee!" data-message="Thank you for visiting. You can now buy me a coffee!" data-color="#5F7FFF" data-position="Right" data-x_margin="18" data-y_margin="18"></script>

