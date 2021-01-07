---
title: The &tau; (tau) Project
description: The d&tau; Project README
keywords: home homepage readme
tags: [tau]
permalink: readme.html
summary: The &tau; Project documentation.
---

{% include image.html file="banner5.png"  caption="The &tau; (tau) Project" %}

The τ (tau) Project is a set of libraries which deal with audio :

* A player for audio playback
* A recorder for recording audio
* Several utilities to handle audio files

{% include note.html content="τ is a big project. The goal is to share a maximum of the developments between various Platforms/Frameworks and various target OS." %}

## Overview

τ is a library package allowing you to play and record audio for

* iOS
* Android
* Web

τ provides both a high level API and widgets for:

* play audio
* record audio

τ can be used to play a beep from an asset all the way up to implementing a complete media player.

The API is designed so you can use the supplied widgets or roll your own.

The τ package supports playback from:

* Assets
* Files
* URL

## Features

The τ package includes the following features :

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

## Supported platforms

τ is actually supported by the following frameworks:

* Flutter \(Flutter Sound\)

In the future, it will be \(perhaps\) supported by

* React Native \(Tau React\).  \(Not yet. Later\).
* Cordova \(Tau Cordova\).  \(Not yet. Later\).
* Others \(Native Script, Solar 2D, ...\)

## Supported targets

τ is actually supported by the following OS :

* iOS
* Android
* Web

In the future, it will be \(perhaps\) supported by

* Linux
* others \(Windows, MacOS\)

## What about Flutter Sound ?

{% include note.html content="Flutter Sound is not dead, of course. This is exactly the opposite. Flutter Sound is a really alive project."%}

We just changed the name of the project, because we want to encompass others frameworks than Flutter.


## Licenses

- Flutter Sound is copyrighted by Dooboolab (2018, 2019, 2020, 2021).
- Flutter Sound is released under a license with a *copyleft* clause: the LGPL-V3 license. This means that if you modify some of Flutter Sound code you must publish your modifications under the LGPL license too.

- &tau; React is copyrighted by Canardoux (2021).
- &tau; React is released under a license with a **strong** *copyleft* clause : the GPL-V3 license. This means that if you use part or all of &tau; React in your App, this App must be published under the GPL-V3 license, too.


## We need help

τ is a fundamental building block needed by almost every mobile project.

We are looking to make τ the go to project for mobile Audio with support for various platforms and various OS.

τ is a large and complex project which requires to maintain multiple hardware platforms and test environments.

{% include important.html content="We greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation."%}


## Thanks

Too many projects to manage. I am burning out slowly. If you could help me cheer up, buy me a cup of coffee will make my life really happy and get much energy out of it. As a side effect, we will know that Flutter Sound is important for you, that you appreciate our job and that you can show it with a little money.

<a href="https://www.buymeacoffee.com/larpoux"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=💛&slug=larpoux&button_colour=5F7FFF&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00"></a>
[![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/thetauproject?locale.x=fr_FR)

{% include note.html content="You can also click on the `Thumb up` button of the top of the [pub.dev page](https://pub.dev/packages/flutter_sound).
This is free and this will reassure me that **I do not spend most of my life for nobody**." %}

<script data-name="BMC-Widget" src="http://cdnjs.buymeacoffee.com/1.0.0/widget.prod.min.js" data-id="larpoux" data-description="Support me on Buy me a coffee!" data-message="Thank you for visiting. You can now buy me a coffee!" data-color="#5F7FFF" data-position="Right" data-x_margin="18" data-y_margin="18"></script>

