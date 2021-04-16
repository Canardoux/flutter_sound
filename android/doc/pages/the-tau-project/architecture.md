---
title: The &tau; Architecure
keywords: tau architecture
tags: [tau,architecture]
summary: "The &tau; Architecture."
permalink: architecture.html
---

# The &tau; architecture

{% include image.html file="the-t-architecture.svg"  caption="The &tau; architecture" %}



On this diagram, we can see clearly the three layers :

## The Platform layer

This is the highest layer. This layer must implement the various platforms/frameworks that &tau; wants to support.

Actually the only platform is Flutter. Maybe in the future we will have others :

- React Native
- Native Script
- Cordova
- Solar 2D
- ...

This layer is independant of the target OS. The API is general enough to accomodate various target OS.


## The OS layer

This is the lowest layer. this layer must implement the various target OS that &tau; wants to support.

Actually the OS supported are :

- Android
- iOS
- Web

Maybe in the future we will have others :

- Linux
- Windows
- MacOS

This layer is independant of the platforms/frameworks that &tau; wants to be supported by.


## The Interface layer

The middle layer is the interface between the two other layers. This middle layer must be as thin as possible.
Its purpose is just for doing an interface. No real processing mus be done in this layer


## Where are published all those blocs ?

- Flutter Sound is published on `pub.dev` under the project `flutter_sound`  (or `flauto`) and `flutter_sound_lite` (or `flauto_lite`).
- The Flutter Sound Platform Interface is published on `pub.dev` under the project `flutter_sound_platform_interface` (or `flauto_platform_interface` ).
- The Flutter Web plugin is published on `pub.dev` under the project `flutter_sound_web` (or `flauto_web`).
- The &tau; Core for Android is published on `Bintray` (`jcenter()`) under the project `tau_sound_core` (or `tau_core`).
- The &tau; Core for iOS is published on `Cocoapods` under the project `tau_sound_core` (or `tau_core`).
- The &tau; Core for Web is published on `npm` under the project `tau_sound_core` (or `tau_core`).
