---
title:  "Lock-screen"
description: "Playing sound in the background"
summary: "Configuring Flutter Sound for background audio"
permalink: guides_lock_screen.html
tags: [guide]
keywords: lock_screen
---
# Playing background audio

Flutter sounds open-architecture provides the ability to easily integrate a host of 3rd party plugins. We are strong advocates in keeping things simple (KISS) & where a robust solution already exists, we would rather use that than trying to re-invent the wheel. With this in mind, we have provided an an example within our `demo app` that shows how to play background audio & more importantly - how the audio can be controlled from your phones lock screen. 

## Setting up your app to play background audio
The first thing you will want to do is to amend your `pubspec.yaml` file and include a reference to `audio service` :

```text
audio_service: ^0.18.3
```

### iOS - Amend info.plist
Next you will need to make some adjustments to your info.plist so that it supports **background mode** :

```text
<key>UIBackgroundModes</key>
  <array>
    <string>audio</string>
  </array>
```


### Android - Amend AndroidManifest.xml
For Android to work correctly - a number of important changes needs to be made in your **AndroidManifest** file (Note , the info below assumes your Android project is 1.12 , if your project is prior to that then you will need to update your project to follow the new Flutter Android project structure (https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects)

##### Add permissions
```text
 <uses-permission android:name="android.permission.WAKE_LOCK"/>
 <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  ```
##### Change Activity name
```text
 android:name="com.ryanheise.audioservice.AudioServiceActivity"
  ```

##### Add the audio service & receiver intents
```text
  <service android:name="com.ryanheise.audioservice.AudioService">
  <intent-filter>
    <action android:name="android.media.browse.MediaBrowserService" />
  </intent-filter>
</service>
<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" >
  <intent-filter>
    <action android:name="android.intent.action.MEDIA_BUTTON" />
  </intent-filter>
</receiver>
  ```

**A completed AndroidManifest would look something like this**
```text
<manifest xmlns:tools="http://schemas.android.com/tools" ...>
  <uses-permission android:name="android.permission.WAKE_LOCK"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  
  <application ...>
    <activity android:name="com.ryanheise.audioservice.AudioServiceActivity" ...>
      ...
    </activity>
    <service android:name="com.ryanheise.audioservice.AudioService"
        android:exported="true" tools:ignore="Instantiatable">
      <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
      </intent-filter>
    </service>
    <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
        android:exported="true" tools:ignore="Instantiatable">
      <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
      </intent-filter>
    </receiver> 
  </application>
</manifest>
```

## Provide callbacks from the Lock Screen to your Audio Handler
We need a way for our code to handle lock-screen audio callbacks (Play, Pause, Stop, Previous etc) - The way we do this is to initialise the `AudioService` and customize accordingly (Android is different to iOS), we also specify a plain vanila Dart class file that **houses** our callback code :

```text
Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.fluttersound.audio',
      androidNotificationChannelName: 'Flutter Sound Audio Service Demo',

      /// The next two, specific to Android allows you to dismiss the Audio controls
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
```

The configuration for your `AudioService` requires a completed `AudioServiceConfig`. This belongs to the `Audio Service Plugin` and allows you to easily and completely initialise iOS and Android :

```text
AudioServiceConfig AudioServiceConfig({
  bool androidResumeOnClick = true,
  String? androidNotificationChannelId,
  String androidNotificationChannelName = 'Notifications',
  String? androidNotificationChannelDescription,
  Color? notificationColor,
  String androidNotificationIcon = 'mipmap/ic_launcher',
  bool androidShowNotificationBadge = false,
  bool androidNotificationClickStartsActivity = true,
  bool androidNotificationOngoing = false,
  bool androidStopForegroundOnPause = true,
  int? artDownscaleWidth,
  int? artDownscaleHeight,
  Duration fastForwardInterval = const Duration(seconds: 10),
  Duration rewindInterval = const Duration(seconds: 10),
  bool preloadArtwork = false,
  Map<String, dynamic>? androidBrowsableRootExtras,
})
package:audio_service/audio_service.dart

Creates a configuration object.
```

As you can see from the above snippet - you have full control for configuring Android.

We can see from the above `initAudioService` method that the audio handler is `AudioPlayerHandler`. This handler is what you will create and whereby you will ensure that it extends from `BaseAudioHandler`. This class is provided by the `AudioService` plugin - it will expect you to override base methods from this class so that you can control how your app behaves when control buttons like Pause, Play, Seek, Stop etc are triggered from your devices lock screen.

Ultimately you will simply override these base methods and delegate to your chosen AudioPlayer (Just Audio, Flutter Sound etc).

For the purpose of the demo, we have used JustAudio player within our `AudioPlayerHandler` but with some changes this could also be amended to include the callback code for Play, Stop, Seek, Pause etc for any Player (Flutter Sound etc). 

With respect to `AudioPlayerHandler` - Here you will see how we override the base methods of `BaseAudioHandler` :


```text
  @override
  Future<void> play() => _useFlutterSound
      ? _flutterSoundAudioPlayer.play()
      : _justAudioPlayer.play();

  @override
  Future<void> pause() => _useFlutterSound
      ? _flutterSoundAudioPlayer.pause()
      : _justAudioPlayer.pause();

  @override
  Future<void> seek(Duration position) => _useFlutterSound
      ? _flutterSoundAudioPlayer.seekTo(position)
      : _justAudioPlayer.seek(position);

  @override
  Future<void> stop() => _useFlutterSound
      ? _flutterSoundAudioPlayer.stop()
      : _justAudioPlayer.stop();

```

From the above code fragment - we use a simple switch `_useFlutterSound` to determine which player we wish to use and then delegate our callbacks accordingly.

## Initialising your Audio Service 

You are free to choose how you want to initialise your audio service (Provider, Get_x etc)  but this should be one of the first things your app does. In our demo code, we have chosen to use a simple DI plugin `flutter_simple_dependency_injection` and we initialise this in `main()` as well as create our audio service :

```text
Future<void> main() async {
  /// Lets add some DI to this demo !
  final injector = Injector();

  /// We want Audio template to be able to run in the background
  var audioService = await initAudioService();
  injector.map((i) => audioService, isSingleton: true);
  runApp(ExamplesApp());
}
```


This will then allow any code to reference `audioservice` easily :

**Play, Pause & Stop buttons**
```text
   
            StreamBuilder<bool>(
              stream: Injector()
                  .get<AudioHandler>()
                  .playbackState
                  .map((state) => state.playing)
                  .distinct(),
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _button(Icons.fast_rewind,
                        Injector().get<AudioHandler>().rewind),
                    if (playing)
                      _button(Icons.pause, Injector().get<AudioHandler>().pause)
                    else
                      _button(Icons.play_arrow,
                          Injector().get<AudioHandler>().play),
                    _button(Icons.stop, Injector().get<AudioHandler>().stop),
                    _button(Icons.fast_forward,
                        Injector().get<AudioHandler>().fastForward),
                  ],
                );
              },
            ),
```


## Summary

Integrating `AudioService` into  Flutter Sound consists of :

```
1- Adding the plugin in your pubspec.yaml
2- Amending your AndroidManifest.xml
3- Amending your info.plist
4- Creating an AudioHandler that descends from BaseAudioHandler
5- Providing implementation code for Play, Pause, Seek, Stop etc
```
