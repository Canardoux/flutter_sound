---
title:  "Installation"
description: "Flutter Sound installation."
summary: "Flutter Sound installation."
permalink: flutter_sound_install.html
tags: [flutter_sound,installation]
keywords: Flutter, Flutter Sound, installation
---
# Installation

## Install

For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

### SDK requirements

* Flutter Sound requires an iOS 10.0 SDK \(or later\)
* Flutter Sound requires an Android 21 \(or later\)

### Flutter Sound flavors

Flutter Sound comes in two flavors :

* the **FULL** flavor : flutter\_sound
* the **LITE** flavor : flutter\_sound\_lite

The big difference between the two flavors is that the **LITE** flavor does not have `mobile_ffmpeg` embedded inside. There is a huge impact on the memory used, but the **LITE** flavor will not be able to do :

* Support some codecs like Playback OGG/OPUS on iOS or Record OGG\_OPUS on iOS
* Will not be able to offer some helping functions, like `FlutterSoundHelper.FFmpegGetMediaInformation()` or `FlutterSoundHelper.duration()`

Here are the size of example/demo1 iOS .ipa in Released Mode. Those numbers include everything \(flutter library, application, ...\) and not only Flutter Sound.

| Flavor | V4.x | V5.1 |
| :--- | :---: | :--- |
| LITE | 16.2 MB | 17.8 MB |
| FULL | 30.7 MB | 32.1 MB |

### Linking your App directly from `pub.dev`

Add `flutter_sound` or `flutter_sound_lite` as a dependency in pubspec.yaml.

The actual versions are :

* flutter\_sound\_lite: ^5.0.0  \(the LTS version without FFmpeg\)
* flutter\_sound: ^5.0.0 \(the LTS version with FFmpeg embedded\)
* flutter\_sound\_lite: ^6.0.0 \(the current version without FFmpeg\)
* flutter\_sound: ^6.0.0       \(the current version with FFmpeg\)

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound: ^6.0.0
```

or

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite: ^6.0.0
```

### Linking your App with Flutter Sound sources \(optional\)

The Flutter-Sound sources [are here](https://github.com/dooboolab/flutter_sound).

There is actually two branches :

* V5. This is the Long Term Support \(LTS\) branch which is maintained under the version 5.x.x
* master. This is the branch currently developed and is released under the version 6.x.x.

If you want to generate your App from the sources with a `FULL` flavor:

```bash
cd some/where
git clone https://github.com/dooboolab/flutter_sound
cd some/where/flutter_sound
bin/flavor FULL
```

and add your dependency in your pubspec.yaml :

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound:
    path: some/where/flutter_sound
```

If you prefer to link your App with the `LITE` flavor :

```bash
cd some/where
git clone https://github.com/dooboolab/flutter_sound
cd some/where/flutter_sound
bin/flavor LITE
```

and add your dependency in your pubspec.yaml :

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite:
    path: some/where/flutter_sound
```

### FFmpeg

flutter\_sound FULL flavor makes use of a terrific plugin : `Mobile FFmpeg`.
In contrary to Flutter Sound Version 3.x.x, in Version 4.0.x your App can be built without any `Flutter-FFmpeg` dependency : `Mobile FFmpeg full-lts` is now automaticaly embedding inside the `FULL` flavor of Flutter Sound and Flutter Sound users do not have anything special to do.

But your App can also use `Flutter-FFmpeg` if you need it. (`Flutter-FFmpeg` is a wrapper around `Mobile FFmpeg`).

To use `Flutter-FFmpeg` :

#### `pubspec.yaml`

Add a dependency inside your `pubspec.yaml`
```
  flutter_ffmpeg: ^0.3.1
```

#### iOS `Podfile`

No need to add any dependency to `Mobile FFmpeg`.

Here is the Podfile of Flutter Sound example :
```
platform :ios, '11.0' # Necessary >= 11 for flutter_ffmpeg

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup


target 'Runner' do
  #use_frameworks! // Does not work with Flutter FFmpeg
  #use_modular_headers! // Does not work with Flutter FFmpeg

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

Note two things :
- Flutter FFmpeg needs iOS 11.0. Your App will not compile with iOS 10.0
- `use_frameorsk!` and `use_modular_headers!` cannot be used. _(I do not know what those instructions are used for!)_

#### `build.gradle`

In your main `build.gradle`, add this line :
```
ext.flutterFFmpegPackage = 'full-lts'
```

Note two things :
- This added line is in the **MAIN** build.gradle (not the App build.gradle).
- Flutter FFmpeg needs at least Android API 24

Here is the `build.gradle` file of Flutter Sound example :
```
buildscript {
    ext.kotlin_version = '1.3.50'
    repositories {
        google()
        jcenter()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:4.2.0-beta04'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        jcenter()
        maven { url 'https://jitpack.io' }
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

ext.flutterFFmpegPackage = 'full-lts' // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< !

task clean(type: Delete) {
    delete rootProject.buildDir
}
```


### Post Installation

* On _iOS_ you need to add usage descriptions to `info.plist`:

  ```markup
        <key>NSAppleMusicUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSCalendarsUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSCameraUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSContactsUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSLocationWhenInUseUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSMotionUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSSpeechRecognitionUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>UIBackgroundModes</key>
        <array>
                <string>audio</string>
        </array>
        <key>NSMicrophoneUsageDescription</key>
        <string>MyApp uses the microphone to record your speech and convert it to text.</string>
  ```
If your App needs to play remote files you possibly must add :
```markup
       <key>NSAppTransportSecurity</key>
       <dict>
               <key>NSAllowsArbitraryLoads</key>
               <true/>
       </dict>
```

* On _Android_ you need to add a permission to `AndroidManifest.xml`:

  ```markup
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  ```

### Flutter Web

To use Flutter Sound in a web application, you can either :

#### Static reference

Add those 4 lines at the end of the `<head>` section of your `index.html` file :

```text
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound.js"></script>
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound_player.js"></script>
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound_recorder.js"></script>
  <script src="assets/packages/flutter_sound_web/js/howler/howler.js"></script>
```

#### or Dynamic reference

Add those 4 lines at the end of the `<head>` section of your `index.html` file :

```text
  <script src="https://cdn.jsdelivr.net/npm/tau_sound_core@7.4.13/js/flutter_sound/flutter_sound.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/tau_sound_core@7.4.13/js/flutter_sound/flutter_sound_player.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/tau_sound_core@7.4.13/js/flutter_sound/flutter_sound_recorder.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/howler@2/dist/howler.min.js"></script>
```

Please [read this](https://www.jsdelivr.com/features) to understand how you can specify the interval of the versions you are interested by.

### Troubles shooting

#### Problem with Cocoapods

If you get this message \(specially after the release of a new Flutter Version\) :

```text
Cocoapods could not find compatible versions for pod ...
```

you can try the following instructions sequence \(and ignore if some commands gives errors\) :

```bash
cd ios
pod cache clean --all
rm Podfile.lock
rm -rf .symlinks/
cd ..
flutter clean
flutter pub get
cd ios
pod update
pod repo update
pod install --repo-update
pod update
pod install
cd ..
```

If everything good, the last `pod install` must not give any error.

