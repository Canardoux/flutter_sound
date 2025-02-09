---
title:  "Contributions"
description: "We need you!"
summary: "We need you!"
permalink: tau_dev.html
tags: [contributions]
keywords: Contributions
---

# Contributions

Flutter Sound is a free and Open Source project. Several contributors have already contributed to Flutter Sound. Specially :

- @hyochan who is the Flutter Sound father
- @salvatore373 who wrote the Track Player
- @bsutton who wrote the UI Widgets
- @larpoux who add several codec supports

**We really need your contributions.**
Pull Requests are welcome and will be considered very carefully.

## Setup a development environment

### Clone the Flutter Sound project and the flutter_sound_core module

```sh
cd some_where
git clone --recursive https://github.com/canardoux/tau.git
```

### setup a development environment

cd to the &tau; root dir and run the script `bin/reldev.sh DEV`

```sh
cd tau
bin/reldev.sh DEV
```

### iOS signing

Open tau/flutter_sound/example/ios/Runner.xcworkspace in XCode, and set your `Team` in the `Signing & Capabilities` tab.

### Set your Flutter Sound flavor

```sh
cd tau

# If you want to work on the full flavor
bin/flavor.sh FULL

# if you want to work on the lite flavor
bin/flavor.sh LITE
```


### Clean your space

Probably good to clean the space :

```sh
cd flutter_sound/example
rm -r build ios/.symlinks ios/Podfile.lock
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

### Debug the example

If everything good, you are now ready to run the example in debug mode using either Visual Studio Code, Android Studio or XCode

- To debug/develop the Dart side, you open the project /tau/flutter_sound/example/ in Visual Studio Code or Android Studio.
- To debug/develop the iOS side you open tau/flutter_sound/example/ios/Runner.xcworkspace in XCode.
- To debug/develop the Android side, you open the project tau/flutter_sound/example/android in Android Studio

### Debug your own App

You must change the dependencies in your pubspec.yaml file and do a `flutter pub get`:

```yaml
# ============================================================================
# The following instructions are just for developing/debugging Flutter Sound
# Do not put them in a real App
  flutter_sound_platform_interface:
    path: ../tau/flutter_sound_platform_interface # flutter_sound_platform_interface Dir
  flutter_sound_web:
    path: ../tau/flutter_sound_web # flutter_sound_web Dir
  flutter_sound: 
    path: ../tau/flutter_sound
# ============================================================================
```

## Update the documentation

&tau; uses the Jekyll tool with a "Documentation Theme" to generate the documentation.
[Here](https://idratherbewriting.com/documentation-theme-jekyll/) is the Jekyll documentation.
Please refer to this documentation to install ruby and jekyll on your dev machine.

All the &tau; documentation is in markdown files under tau/doc/pages.
You can see your modifications in live doing:

```sh
cd tau/doc
jekyll serve
```

Then, if you have the necessary credentials (but you certainly do not have them), you can do:

```sh
cd tau
bin/doc.sh
```

## Build a new release

if you have the necessary credentials (but you certainly do not have them), you can do:

```sh
cd tau
newVersion.sh 8.2.0
```

(In this example, 8.2.0 is the version number that you want to build).

When the script asks if OK to upload your new flutter_sound plugin,
it is a good idea to wait something like half an hour before answering.
This will give time to `npm` and `cocoaPod` to update their repositories (you do not want that someone will use your new build before that the repositories are updated.

------------------

When you have finished your contribution, you commit and push your files, and do a Pull Request in the Github &tau; Project.

**THANK YOU FOR YOUR CONTRIBUTION**
