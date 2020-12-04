# The τ Player

The verbs offered by the Flutter Sound Player module are :

* [Default constructor](player.md#creating-the-player-instance)
* [openAudioSession\(\)](player.md#openaudiosession-and-closeaudiosession) and [closeAudioSession\(\)](player.md#openaudiosession-and-closeaudiosession) to open or close an audio session
* [setAudioFocus\(\)](player.md#setaudiofocus) to manage the session Audio Focus
* [startPlayer\(\)](player.md#startplayer) to play an audio file or  a buffer.
* [startPlayerFromTrack\(\)](player.md#startplayerfromtrack) to play data from a track specification and display controls on the lock screen or an Apple Watch
* [startPlayerFromStream\(\)](player.md#startplayerfromstream) to play live data. Please look to the [following notice](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/codec.md#playing-pcm-16-from-a-dart-stream).
* [feedFromStream\(\)](player.md#feedfromstream) to play live PCM data synchronously.  Please look to the [following notice](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/codec.md#playing-pcm-16-from-a-dart-stream).
* [foodSink\(\)](player.md#foodsink) is the output stream when you want to play asynchronously live data
* [FoodData and FoodEvent\(\)](player.md#food) are the two kinds of food that you can provide to the `foodSink` Stream.
* [stopPlayer\(\)](player.md#stopplayer) to stop a current playback
* [pausePlayer\(\)](player.md#pauseplayer) to pause the current playback
* [resumePlayer\(\)](player.md#resumeplayer) to resume a paused playback
* [seekPlayer\(\)](player.md#seekplayer) to position directely inside the current playback
* [setVolume\(\)](player.md#setvolume) to adjust the ouput volume
* [playerState, isPlaying, isPaused, isStopped, getPlayerState\(\)](player.md#playerstate-isplaying-ispaused-isstopped-getplayerstate) to know the current player status
* [isDecoderSupported\(\)](player.md#isdecodersupported) to know if a specific codec is supported on the current platform.
* [onProgress\(\)](player.md#onprogress) to subscribe to a Stream of the Progress events
* [getProgress\(\)](player.md#getprogress) to query the current progress of a playback.
* [setUIProgressBar](player.md#setuiprogressbar) to set the position of the progress bar on the Lock Screen
* [nowPlaying\(\)](player.md#nowplaying) to specify the containt of the lock screen beetween two playbacks
* [setSubscriptionDuration\(\)](player.md#setsubscriptionduration) to specify the frequence of your subscription

## Creating the `Player` instance.

_Dart definition \(prototype\) :_

```text
/* ctor */ FlutterSoundPlayer()
```

This is the first thing to do, if you want to deal with playbacks. The instanciation of a new player does not do many thing. You are safe if you put this instanciation inside a global or instance variable initialization.

_Example:_

```dart
FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
```

## `openAudioSession()` and `closeAudioSession()`

[Dart API: openAudioSession](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/openAudioSession.html) [Dart API: closeAudioSession](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/closeAudioSession.html)

A player must be opened before used. A player correspond to an Audio Session. With other words, you must _open_ the Audio Session before using it. When you have finished with a Player, you must close it. With other words, you must close your Audio Session. Opening a player takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`. It is safe to call this procedure at any time.

* If the Player is not open, this verb will do nothing
* If the Player is currently in play or pause mode, it will be stopped before.

### `focus:` parameter

`focus` is an optional parameter can be specified during the opening : the Audio Focus. This parameter can have the following values :

* AudioFocus.requestFocusAndStopOthers \(your app will have **exclusive use** of the output audio\)
* AudioFocus.requestFocusAndDuckOthers \(if another App like Spotify use the output audio, its volume will be **lowered**\)
* AudioFocus.requestFocusAndKeepOthers \(your App will play sound **above** others App\)
* AudioFocus.requestFocusAndInterruptSpokenAudioAndMixWithOthers \(for Android\)
* AudioFocus.requestFocusTransient \(for Android\)
* AudioFocus.requestFocusTransientExclusive \(for Android\)
* AudioFocus.doNotRequestFocus \(useful if you want to mangage yourself the Audio Focus with the verb `setAudioFocus()`\)

The Audio Focus is abandoned when you close your player. If your App must play several sounds, you will probably open your player just once, and close it when you have finished with the last sound. If you close and reopen an Audio Session for each sound, you will probably get unpleasant things for the ears with the Audio Focus.

### `category`

`category` is an optional parameter used only on iOS. This parameter can have the following values :

* ambient
* multiRoute
* playAndRecord
* playback
* record
* soloAmbient
* audioProcessing

See [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosessioncategory?language=objc) to understand the meaning of this parameter.

### `mode`

`mode` is an optional parameter used only on iOS. This parameter can have the following values :

* modeDefault
* modeGameChat
* modeMeasurement
* modeMoviePlayback
* modeSpokenAudio
* modeVideoChat
* modeVideoRecording
* modeVoiceChat
* modeVoicePrompt

See [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosessionmode?language=objc) to understand the meaning of this parameter.

### `audioFlags`

are a set of optional flags \(used on iOS\):

* outputToSpeaker
* allowHeadset
* allowEarPiece
* allowBlueTooth
* allowAirPlay
* allowBlueToothA2DP

### `device`

is the output device \(used on Android\)

* speaker
* headset,
* earPiece,
* blueTooth,
* blueToothA2DP,
* airPlay

### `withUI`

is a boolean that you set to `true` if you want to control your App from the lock-screen \(using [startPlayerFromTrack\(\)](player.md#startplayerfromtrack) during your Audio Session\).

You MUST ensure that the player has been closed when your widget is detached from the UI. Overload your widget's `dispose()` method to closeAudioSession the player when your widget is disposed. In this way you will reset the player and clean up the device resources, but the player will be no longer usable.

```dart
@override
void dispose()
{
        if (myPlayer != null)
        {
            myPlayer.closeAudioSession();
            myPlayer = null;
        }
        super.dispose();
}
```

You may not open many Audio Sessions without closing them. You will be very bad if you try something like :

```dart
    while (aCondition)  // *DON'T DO THAT*
    {
            flutterSound = FlutterSoundPlayer().openAudioSession(); // A **new** Flutter Sound instance is created and opened
            flutterSound.startPlayer(bipSound);
    }
```

`openAudioSession()` and `closeAudioSession()` return Futures. You may not use your Player before the end of the initialization. So probably you will `await` the result of `openAudioSession()`. This result is the Player itself, so that you can collapse instanciation and initialization together with `myPlayer = await FlutterSoundPlayer().openAudioSession();`

_Example:_

```dart
    myPlayer = await FlutterSoundPlayer().openAudioSession(focus: Focus.requestFocusAndDuckOthers, outputToSpeaker | allowBlueTooth);

    ...
    (do something with myPlayer)
    ...

    await myPlayer.closeAudioSession();
    myPlayer = null;
```

## `setAudioFocus()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/setAudiFocus.html)

### `focus:` parameter possible values are

* AudioFocus.requestFocus \(request focus, but do not do anything special with others App\)
* AudioFocus.requestFocusAndStopOthers \(your app will have **exclusive use** of the output audio\)
* AudioFocus.requestFocusAndDuckOthers \(if another App like Spotify use the output audio, its volume will be **lowered**\)
* AudioFocus.requestFocusAndKeepOthers \(your App will play sound **above** others App\)
* AudioFocus.requestFocusAndInterruptSpokenAudioAndMixWithOthers
* AudioFocus.requestFocusTransient \(for Android\)
* AudioFocus.requestFocusTransientExclusive \(for Android\)
* AudioFocus.abandonFocus \(Your App will not have anymore the audio focus\)

### Other parameters :

Please look to [openAudioSession\(\)](player.md#openaudiosession-and-closeaudiosession) to understand the meaning of the other parameters

_Example:_

```dart
        myPlayer.setAudioFocus(focus: AudioFocus.requestFocusAndDuckOthers);
```

## `startPlayer()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/startPlayer.html)

You can use `startPlayer` to play a sound.

* `startPlayer()` has three optional parameters, depending on your sound source :
  * `fromUri:`  \(if you want to play a file or a remote URI\)
  * `fromDataBuffer:` \(if you want to play from a data buffer\)
  * `sampleRate` is mandatory if `codec` == `Codec.pcm16`. Not used for other codecs.

You must specify one or the three parameters : `fromUri`, `fromDataBuffer`, `fromStream`.

* You use the optional parameter`codec:` for specifying the audio and file format of the file. Please refer to the [Codec compatibility Table](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
* `whenFinished:()` : A lambda function for specifying what to do when the playback will be finished.

Very often, the `codec:` parameter is not useful. Flutter Sound will adapt itself depending on the real format of the file provided. But this parameter is necessary when Flutter Sound must do format conversion \(for example to play opusOGG on iOS\).

`startPlayer()` returns a Duration Future, which is the record duration.

Hint: [path\_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.

_Example:_

```dart
        Directory tempDir = await getTemporaryDirectory();
        File fin = await File ('${tempDir.path}/flutter_sound-tmp.aac');
        Duration d = await myPlayer.startPlayer(fin.path, codec: Codec.aacADTS);

        _playerSubscription = myPlayer.onProgress.listen((e)
        {
                // ...
        });
}
```

_Example:_

```dart
    final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";

    Duration d = await myPlayer.startPlayer
    (
                fromURI: fileUri,
                codec: Codec.mp3,
                whenFinished: ()
                {
                         print( 'I hope you enjoyed listening to this song' );
                },
    );
```

## `startPlayerFromTrack()`

Dart API\]\([https://canardoux.github.io/tau/doc/flutter\_sound/api/player/FlutterSoundPlayer/startPlayerFromTrack.html](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/startPlayerFromTrack.html)\)

Use this verb to play data from a track specification and display controls on the lock screen or an Apple Watch. The Audio Session must have been open with the parameter `withUI`.

* `track` parameter is a simple structure which describe the sound to play. Please see [here the Track structure specification](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/track.md)
* `whenFinished:()` : A function for specifying what to do when the playback will be finished.
* `onPaused:()` : this parameter can be :
  * a call back function to call when the user hit the Skip Pause button on the lock screen
  * `null` : The pause button will be handled by Flutter Sound internal
* `onSkipForward:()` : this parameter can be :
  * a call back function to call when the user hit the Skip Forward button on the lock screen
  * `null` : The Skip Forward button will be disabled
* `onSkipBackward:()` : this parameter can be :
  * a call back function to call when the user hit the Skip Backward button on the lock screen
  *  : The Skip Backward button will be disabled
* `removeUIWhenStopped` : is a boolean to specify if the UI on the lock screen must be removed when the sound is finished or when the App does a `stopPlayer()`. Most of the time this parameter must be true. It is used only for the rare cases where the App wants to control the lock screen between two playbacks. Be aware that if the UI is not removed, the button Pause/Resume, Skip Backward and Skip Forward remain active between two playbacks. If you want to disable those button, use the API verb `nowPlaying()`. Remark: actually this parameter is implemented only on iOS.
* `defaultPauseResume` : is a boolean value to specify if Flutter Sound must pause/resume the playback by itself when the user hit the pause/resume button. Set this parameter to _FALSE_ if the App wants to manage itself the pause/resume button. If you do not specify this parameter and the `onPaused` parameter is specified then Flutter Sound will assume `FALSE`. If you do not specify this parameter and the `onPaused` parameter is not specified then Flutter Sound will assume `TRUE`. Remark: actually this parameter is implemented only on iOS.

`startPlayerFromTrack()` returns a Duration Future, which is the record duration.

_Example:_

```dart
    final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
    Track track = Track( codec: Codec.opusOGG, trackPath: fileUri, trackAuthor: '3 Inches of Blood', trackTitle: 'Axes of Evil', albumArtAsset: albumArt )
    Duration d = await myPlayer.startPlayerFromTrack
    (
                track,
                whenFinished: ()
                {
                         print( 'I hope you enjoyed listening to this song' );
                },
    );
```

## `startPlayerFromStream()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/startPlayerFromStream.html)

**This functionnality needs, at least, and Android SDK &gt;= 21**

* The only codec supported is actually `Codec.pcm16`.
* The only value possible for `numChannels` is actually 1.
* SampleRate is the sample rate of the data you want to play.

Please look to [the following notice](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/codec.md#playing-pcm-16-from-a-dart-stream)

_Example_ You can look to the three provided examples :

* [This example](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/flutter_sound/example/example.md#liveplaybackwithbackpressure) shows how to play Live data, with Back Pressure from Flutter Sound
* [This example](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/flutter_sound/example/example.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound
* [This example](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/flutter_sound/example/example.md#soundeffect) shows how to play some real time sound effects.

_Example 1:_

```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

await myPlayer.feedFromStream(aBuffer);
await myPlayer.feedFromStream(anotherBuffer);
await myPlayer.feedFromStream(myOtherBuffer);

await myPlayer.stopPlayer();
```

_Example 2:_

```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));

myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
```

## `feedFromStream`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/feedFromStream.html)

This is the verb that you use when you want to play live PCM data synchronously. This procedure returns a Future. It is very important that you wait that this Future is completed before trying to play another buffer.

_Example:_

* [This example](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/flutter_sound/example/example.md#liveplaybackwithbackpressure) shows how to play Live data, with Back Pressure from Flutter Sound
* [This example](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/flutter_sound/example/example.md#soundeffect) shows how to play some real time sound effects synchronously.

```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

await myPlayer.feedFromStream(aBuffer);
await myPlayer.feedFromStream(anotherBuffer);
await myPlayer.feedFromStream(myOtherBuffer);

await myPlayer.stopPlayer();
```

## `foodSink`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/foodSink.html)

The sink side of the Food Controller that you use when you want to play asynchronously live data. This StreamSink accept two kinds of objects :

* FoodData \(the buffers that you want to play\)
* FoodEvent \(a call back to be called after a resynchronisation\)

_Example:_

[This example](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/example/README.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound

```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));
myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
```

## `onProgress`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/onProgress.html)

The stream side of the Food Controller : this is a stream on which FlutterSound will post the player progression. You may listen to this Stream to have feedback on the current playback.

PlaybackDisposition has two fields :

* Duration duration  \(the total playback duration\)
* Duration position  \(the current playback position\)

_Example:_

```dart
        _playerSubscription = myPlayer.onProgress.listen((e)
        {
                Duration maxDuration = e.duration;
                Duration position = e.position;
                ...
        }
```

## `Food`

* [Dart API: Food](https://canardoux.github.io/tau/doc/flutter_sound/api/tau/Food/Food.html)
* [Dart API: FoodData](https://canardoux.github.io/tau/doc/flutter_sound/api/tau/FoodData/FoodData.html.html)
* [Dart API: FoodEvent](https://canardoux.github.io/tau/doc/flutter_sound/api/tau/FoodEvent/FoodEvent.html)

This are the objects that you can `add` to `foodSink` The Food class has two others inherited classes :

* FoodData \(the buffers that you want to play\)
* FoodEvent \(a call back to be called after a resynchronisation\)

_Example:_

[This example](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/example/README.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound

```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));
myPlayer.foodSink.add(FoodEvent(()async {await _mPlayer.stopPlayer(); setState((){});}));
```

## `stopPlayer()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/stopPlayer.html)

Use this verb to stop a playback. This verb never throw any exception. It is safe to call it everywhere, for example when the App is not sure of the current Audio State and want to recover a clean reset state.

_Example:_

```dart
        await myPlayer.stopPlayer();
        if (_playerSubscription != null)
        {
                _playerSubscription.cancel();
                _playerSubscription = null;
        }
```

## `pausePlayer()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/pausePlayer.html)

Use this verbe to pause the current playback. An exception is thrown if the player is not in the "playing" state.

_Example:_

```dart
await myPlayer.pausePlayer();
```

## `resumePlayer()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/resumePlayer.html)

Use this verbe to resume the current playback. An exception is thrown if the player is not in the "paused" state.

_Example:_

```dart
await myPlayer.resumePlayer();
```

## `seekPlayer()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/seekPlayer.html)

To seek to a new location. The player must already be playing or paused. If not, an exception is thrown.

_Example:_

```dart
await myPlayer.seekToPlayer(Duration(milliseconds: milliSecs));
```

## `setVolume()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/setVolume.html)

The parameter is a floating point number between 0 and 1. Volume can be changed when player is running. Manage this after player starts.

_Example:_

```dart
await myPlayer.setVolume(0.1);
```

## `playerState`, `isPlaying`, `isPaused`, `isStopped`. `getPlayerState()`

[Dart API: playerState](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/playerState.html) [Dart API: getPlayerState\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/getPlayerState.html) [Dart API: isPlaying\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/isPlaying.html) [Dart API: isPaused\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/isPaused.html) [Dart API: isStopped\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/isStopped.html)

This four verbs is used when the app wants to get the current Audio State of the player.

`playerState` is an attribut which can have the following values :

* isStopped   /// Player is stopped
* isPlaying   /// Player is playing
* isPaused    /// Player is paused
* isPlaying is a boolean attribut which is `true` when the player is in the "Playing" mode.
* isPaused is a boolean atrribut which  is `true` when the player is in the "Paused" mode.
* isStopped is a boolean atrribut which  is `true` when the player is in the "Stopped" mode.

Flutter Sound shows in the `playerState` attribut the last known state. When the Audio State of the background OS engine changes, the `playerState` parameter is not updated exactly at the same time. If you want the exact background OS engine state you must use `PlayerState theState = await myPlayer.getPlayerState()`. Acutually `getPlayerState()` is only implemented on iOS.

_Example:_

```dart
        swtich(myPlayer.playerState)
        {
                case PlayerState.isPlaying: doSomething; break;
                case PlayerState.isStopped: doSomething; break;
                case PlayerState.isPaused: doSomething; break;
        }
        ...
        if (myPlayer.isStopped) doSomething;
        if (myPlayer.isPlaying) doSomething;
        if (myPlayer.isPaused) doSomething;
        ...
        PlayerState theState = await myPlayer.getPlayerState();
        ...
```

## `isDecoderSupported()`

[Dart API: isStopped\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/isDecoderSupported.html)

This verb is useful to know if a particular codec is supported on the current platform. Returns a Future.

_Example:_

```dart
        if ( await myPlayer.isDecoderSupported(Codec.opusOGG) ) doSomething;
```

## `getProgress()`

[Dart API: isStopped\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/getProgress.html)

This verb is used to get the current progress of a playback. It returns a `Map` with two Duration entries : `'progress'` and `'duration'`. Remark : actually only implemented on iOS.

_Example:_

```dart
        Duration progress = (await getProgress())['progress'];
        Duration duration = (await getProgress())['duration'];
```

## `setUIProgressBar()`

[Dart API: isStopped\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/setUIProgressBar.html)

This verb is used if the App wants to control itself the Progress Bar on the lock screen. By default, this progress bar is handled automaticaly by Flutter Sound. Remark `setUIProgressBar()` is implemented only on iOS.

_Example:_

```dart
        Duration progress = (await getProgress())['progress'];
        Duration duration = (await getProgress())['duration'];
        setUIProgressBar(progress: Duration(milliseconds: progress.milliseconds - 500), duration: duration)
`
```

## `nowPlaying()`

[Dart API: isStopped\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/nowPlaying.html)

This verb is used to set the Lock screen fields without starting a new playback. The fields 'dataBuffer' and 'trackPath' of the Track parameter are not used. Please refer to 'startPlayerFromTrack' for the meaning of the others parameters. Remark `setUIProgressBar()` is implemented only on iOS.

_Example:_

```dart
    Track track = Track( codec: Codec.opusOGG, trackPath: fileUri, trackAuthor: '3 Inches of Blood', trackTitle: 'Axes of Evil', albumArtAsset: albumArt );
    await nowPlaying(Track);
```

## `setSubscriptionDuration()`

[Dart API: isStopped\(\)](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/setSubscriptionDuration.html)

This verb is used to change the default interval between two post on the "Update Progress" stream. \(The default interval is 0 \(zero\) which means "NO post"\)

_Example:_

```dart
myPlayer.setSubscriptionDuration(Duration(milliseconds: 100));
```

