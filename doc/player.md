[Back to the README](../README.md#flutter-sound-api)

-----------------------------------------------------------------------------------------------------------------------

# Flutter Sound Player API

The verbs offered by the Flutter Sound Player module are :

- [Default constructor](#creating-the-player-instance)
- [openAudioSession](#openaudiosession-and-closeaudiosession) and [closeAudioSession()](#openAudioSession-and-closeAudioSession) to open or close an audio session
- [openAudioSessionWithUI()](#openaudiosessionwithui) to open an audio session with control from the Lock Screen or an Apple Watch
- [setAudioFocus()](#setaudiofocus) to manage the session Audio Focus
- [startPlayer()](#startplayer) to play an audio file or  a buffer.
- [startPlayerFromTrack](#startplayerfromtrack) to play data from a track specification and display controls on the lock screen or an Apple Watch
- [stopPlayer()](#stopplayer) to stop a current playback
- [pausePlayer()](#pauseplayer) to pause the current playback
- [resumePlayer()](#resumeplayer) to resume a paused playback
- [seekPlayer()](#seekplayer) to position directely inside the current playback
- [setVolume()](#setvolume) to adjust the ouput volume
- [playerState, isPlaying, isPaused, isStopped](#playerstate-isplaying-ispaused-isstopped) to know the current player status
- [isDecoderSupported()](#isdecodersupported) to know if a specific codec is supported on the current platform.
- [onProgress()](#onprogress) to subscribe to a Stream of the Progress events
- [setSubscriptionDuration()](#setsubscriptionduration) to specify the frequence of your subscription

-------------------------------------------------------------------------------------------------------------------

## Creating the `Player` instance.

*Dart definition (prototype) :*
```
/* ctor */ FlutterSoundPlayer()
```

This is the first thing to do, if you want to deal with playbacks. The instanciation of a new player does not do many thing. You are safe if you put this instanciation inside a global or instance variable initialization.

*Example:*
```dart
FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
```

--------------------------------------------------------------------------------------------------------------------

## `openAudioSession()` and `closeAudioSession()`

*Dart definition (prototype) :*
```
Future<FlutterSoundPlayer> openAudioSession
({
        AudioFocus focus = AudioFocus.requestFocusTransient,
        SessionCategory category = SessionCategory.playAndRecord,
        SessionMode mode = SessionMode.modeDefault,
        int audioFlags = outputToSpeaker
})

Future<void> closeAudioSession()
```

A player must be opened before used. A player correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
When you have finished with a Player, you must close it. With other words, you must close your Audio Session.
Opening a player takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.

### `focus:` parameter

`focus` is an optional parameter can be specified during the opening : the Audio Focus.
This parameter can have the following values :
- AudioFocus.requestFocusAndStopOthers (your app will have **exclusive use** of the output audio)
- AudioFocus.requestFocusAndDuckOthers (if another App like Spotify use the output audio, its volume will be **lowered**)
- AudioFocus.requestFocusAndKeepOthers (your App will play sound **above** others App)
- AudioFocus.requestFocusAndInterruptSpokenAudioAndMixWithOthers (for Android)
- AudioFocus.requestFocusTransient (for Android)
- AudioFocus.requestFocusTransientExclusive (for Android)
- AudioFocus.doNotRequestFocus (useful if you want to mangage yourself the Audio Focus with the verb ```setAudioFocus()```)

The Audio Focus is abandoned when you close your player. If your App must play several sounds, you will probably open  your player just once, and close it when you have finished with the last sound. If you close and reopen an Audio Session for each sound, you will probably get unpleasant things for the ears with the Audio Focus.

### `category`

`category` is an optional parameter used only on iOS.
This parameter can have the following values :
- ambient
- multiRoute
- playAndRecord
- playback
- record
- soloAmbient
- audioProcessing

See [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosessioncategory?language=objc) to understand the meaning of this parameter.

### `mode`

`mode` is an optional parameter used only on iOS.
This parameter can have the following values :
- modeDefault
- modeGameChat
- modeMeasurement
- modeMoviePlayback
- modeSpokenAudio
- modeVideoChat
- modeVideoRecording
- modeVoiceChat
- modeVoicePrompt

See [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosessionmode?language=objc) to understand the meaning of this parameter.

### `AudioFlags` are a set of optional flags :

- outputToSpeaker
- allowHeadset
- allowEarPiece
- allowBlueTooth
- allowAirPlay
- allowBlueToothA2DP

Note: you must use the verb [OpenAudioSessionWithUI()](player.md#openaudiosessionwithui) instead of `openAudioSession()` if you plan to use [startPlayerFromTrack()](player.md#startplayerfromtrack) during your Audio Session. (See under).

You MUST ensure that the player has been closed when your widget is detached from the UI.
Overload your widget's `dispose()` method to closeAudioSession the player when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the player will be no longer usable.

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

You may not open many Audio Sessions without closing them.
You will be very bad if you try something like :
```dart
    while (aCondition)  // *DO'NT DO THAT*
    {
            flutterSound = FlutterSoundPlayer().openAudioSession(); // A **new** Flutter Sound instance is created and opened
            flutterSound.startPlayer(bipSound);
    }
```

`openAudioSession()` and `closeAudioSession()` return Futures. You may not use your Player before the end of the initialization. So probably you will `await` the result of `openAudioSession()`. This result is the Player itself, so that you can collapse instanciation and initialization together with `myPlayer = await FlutterSoundPlayer().openAudioSession();`

*Example:*
```dart
    myPlayer = await FlutterSoundPlayer().openAudioSession(focus: Focus.requestFocusAndDuckOthers, outputToSpeaker | allowBlueTooth);

    ...
    (do something with myPlayer)
    ...

    await myPlayer.closeAudioSession();
    myPlayer = null;
```

-----------------------------------------------------------------------------------------------------------------

## `OpenAudioSessionWithUI()`

*Dart definition (prototype) :*
```
Future<FlutterSoundPlayer> OpenAudioSessionWithUI
({
        AudioFocus focus = AudioFocus.requestFocusTransient,
        SessionCategory category = SessionCategory.playAndRecord,
        SessionMode mode = SessionMode.modeDefault,
        int audioFlags = outputToSpeaker,
})
```

Use this verb instead of [openAudioSession()]() if you want to control the Audio Session from the lock screen or an Apple Watch. This verb must be used if you plan to use the verbs [startPlayerFromTrack()]() or [displayTrack()]() during your Audio Session. Please refer to [openAudioSession()](player.md#openaudiosession-and-closeaudiosession) above for the syntax parameters.

*Example:*
```dart
    myPlayer = await FlutterSoundPlayer().openAudioSessionWithUI(focus: Focus.requestFocusAndDuckOthers);

    ...
    await myPlayer.startPlayerFromTrack(aTrack);
    ...

    myPlayer.closeAudioSession();
    myPlayer = null;
```

## `setAudioFocus`

*Dart definition (prototype) :*
```
Future<void> setAudioFocus
({
        AudioFocus focus = AudioFocus.requestFocusTransient,
        SessionCategory category = SessionCategory.playAndRecord,
        SessionMode mode = SessionMode.modeDefault,
        int audioFlags = outputToSpeaker,
})
```

### `focus:` parameter possible values are
- AudioFocus.requestFocus (request focus, but do not do anything special with others App)
- AudioFocus.requestFocusAndStopOthers (your app will have **exclusive use** of the output audio)
- AudioFocus.requestFocusAndDuckOthers (if another App like Spotify use the output audio, its volume will be **lowered**)
- AudioFocus.requestFocusAndKeepOthers (your App will play sound **above** others App)
- AudioFocus.requestFocusAndInterruptSpokenAudioAndMixWithOthers
- AudioFocus.requestFocusTransient (for Android)
- AudioFocus.requestFocusTransientExclusive (for Android)
- AudioFocus.abandonFocus (Your App will not have anymore the audio focus)

### Other parameters :

Please look to [openAudioSession()](player.md#openaudiosession-and-closeaudiosession) to understand the meaning of the other parameters


*Example:*
```dart
        myPlayer.setAudioFocus(focus: AudioFocus.requestFocusAndDuckOthers);
```

-----------------------------------------------------------------------------------------------------------------

## `startPlayer()`

*Dart definition (prototype) :*
```
Future<void> startPlayer
({
        String fromUri,
        Uint8List fromDataBuffer,
        Stream fromStream,
        Codec codec,
        TWhenFinished whenFinished
})
```

You can use `startPlayer` to play a sound.

- `startPlayer()` has three optional parameters, depending on your sound source :
   - `fromUri:`  (if you want to play a file or a remote URI)
   - `fromDataBuffer:` (if you want to play from a data buffer)
   - `fromStream` *(not yet implemented)*

You must specify one or those three parameters.

- You use the optional parameter`codec:` for specifying the audio and file format of the file. Please refer to the [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.

- `whenFinished:()` : A lambda function for specifying what to do when the playback will be finished.

Very often, the `codec:` parameter is not useful. Flutter Sound will adapt itself depending on the real format of the file provided.
But this parameter is necessary when Flutter Sound must do format conversion (for example to play opusOGG on iOS)

`startPlayer()` returns a Future.

[path_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.


*Example:*
```dart
        Directory tempDir = await getTemporaryDirectory();
        File fin = await File ('${tempDir.path}/flutter_sound-tmp.aac');
        await myPlayer.startPlayer(fin.path, codec: Codec.aacADTS);

        _playerSubscription = myPlayer.onProgress.listen((e)
        {
                // ...
        });
}
```

*Example:*
```dart
    final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";

    await myPlayer.startPlayer
    (
                fileUri,
                codec: Codec.mp3,
                whenFinished: ()
                {
                         print( 'I hope you enjoyed listening to this song' );
                },
    );
```

--------------------------------------------------------------------------------------------------------------------------------

## `startPlayerFromTrack()`

*Dart definition (prototype) :*
```
Future<String> startPlayerFromTrack(
    Track track,
    {
    TWhenFinished whenFinished,
    TonPaused onPaused,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    })
```

Use this verb to play data from a track specification and display controls on the lock screen or an Apple Watch. The Audio Session must have been open with the verb [OpenAudioSessionWithUI]().

- `track` parameter is a simple structure which describe the sound to play. Please see [here the Track structure specification](track.md)

- `whenFinished:()` : A lambda function for specifying what to do when the playback will be finished.

- `onPaused:()` : this parameter can be :
   - a call back function to call when the user hit the Skip Pause button on the lock screen
   - 'TonPaused.disabled' *(not yet implemented)*
   - <null> : The pause button will be handled by Flutter Sound internal

- `onSkipForward:()` : this parameter can be :
   - a call back function to call when the user hit the Skip Forward button on the lock screen
   - <null> : The Skip Forward button will be disabled

- `onSkipBackward:()` : this parameter can be :
   - a call back function to call when the user hit the Skip Backward button on the lock screen
   - <null> : The Skip Backwqrd button will be disabled

*Example:*
```dart
    final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";

    await myPlayer.startPlayerFromTrack
    (
                track,
                whenFinished: ()
                {
                         print( 'I hope you enjoyed listening to this song' );
                },
    );
```

---------------------------------------------------------------------------------------------------------------------------------

## `stopPlayer()`

*Dart definition (prototype) :*
```
Future<void> stopPlayer( )
```

Use this verb to stop a playback. This verb never throw any exception. It is safe to call it everywhere,
for example when the App is not sure of the current Audio State and want to recover a clean reset state.

*Example:*
```dart
        await myPlayer.stopPlayer();
        if (_playerSubscription != null)
        {
                _playerSubscription.cancel();
                _playerSubscription = null;
        }
```



---------------------------------------------------------------------------------------------------------------------------------

## `pausePlayer()`

*Dart definition (prototype) :*
```
Future<void> pausePlayer( )
```

Use this verbe to pause the current playback. An exception is thrown if the player is not in the "playing" state.

*Example:*
```dart
await myPlayer.pausePlayer();
```

--------------------------------------------------------------------------------------------------------------------------------

## `resumePlayer()`

*Dart definition (prototype) :*
```
Future<void> resumePlayer( )
```

Use this verbe to resume the current playback. An exception is thrown if the player is not in the "paused" state.

*Example:*
```dart
await myPlayer.resumePlayer();
```

-------------------------------------------------------------------------------------------------------------------------------
## `seekPlayer()`

*Dart definition (prototype) :*
```
Future<void> seekPlayer( Duration duration )
```

To seek to a new location. The player must already be playing or paused. If not, an exception is thrown.

*Example:*
```dart
await myPlayer.seekToPlayer(Duration(milliseconds: milliSecs));
```

----------------------------------------------------------------------------------------------------------------------------------

## `setVolume()`

*Dart definition (prototype) :*
```
Future<void> setVolume( double volume )
```

The parameter is a floating point number between 0 and 1.
Volume can be changed when player is running. Manage this after player starts.

*Example:*
```dart
await myPlayer.setVolume(0.1);
```

---------------------------------------------------------------------------------------------------------------------------------

## `playerState`, `isPlaying`, `isPaused`, `isStopped`

*Dart definition (prototype) :*
```
    PlayerState playerState;
    bool get isPlaying => playerState == PlayerState.isPlaying;
    bool get isPaused => playerState == PlayerState.isPaused;
    bool get isStopped => playerState == PlayerState.isStopped;
```

This four verbs is used when the app wants to get the current Audio State of the player.

`playerState` is an attribut which can have the following values :

  - isStopped   /// Player is stopped
  - isPlaying   /// Player is playing
  - isPaused    /// Player is paused

- isPlaying is a boolean attribut which is `true` when the player is in the "Playing" mode.
- isPaused is a boolean atrribut which  is `true` when the player is in the "Paused" mode.
- isStopped is a boolean atrribut which  is `true` when the player is in the "Stopped" mode.

*Example:*
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

```

---------------------------------------------------------------------------------------------------------------------------------

## `isDecoderSupported()`

*Dart definition (prototype) :*
```
 Future<bool> isDecoderSupported(Codec codec)
```

This verb is useful to know if a particular codec is supported on the current platform.
Returns a Future<bool>.

*Example:*
```dart
        if ( await myPlayer.isDecoderSupported(Codec.opusOGG) ) doSomething;
```

---------------------------------------------------------------------------------------------------------------------------------

## `onProgress`

*Dart definition (prototype) :*
```
Stream<PlaybackDisposition> get onProgress => playerController != null ? playerController.stream : null;
```

The attribut `onProgress` is a stream on which FlutterSound will post the player progression.
You may listen to this Stream to have feedback on the current playback.

*Example:*
```dart
        _playerSubscription = myPlayer.onProgress.listen((e)
        {
                Duration maxDuration = e.duration;
                Duration position = e.position;
                ...
        }
```

---------------------------------------------------------------------------------------------------------------------------------

## `setSubscriptionDuration()`

*Dart definition (prototype) :*
```
Future<void> setSubscriptionDuration(Duration duration)
```

This verb is used to change the default interval between two post on the "Update Progress" stream. (The default interval is 10ms)

*Example:*
```dart
// 0.010s. is default
myPlayer.setSubscriptionDuration(Duration(milliseconds: 20));
```

---------------------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#flutter-sound-api)
