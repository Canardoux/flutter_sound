[Back to the README](../README.md#flutter-sound-api)

-----------------------------------------------------------------------------------------------------------------------

# Flutter Sound Player API

The verbs offered by the Flutter Sound Player module are :

- [Default constructor](player.md#creating-the-player-instance)
- [openAudioSession() and closeAudioSession()](player.md#openAudioSession-and-closeAudioSession) to open or close and audio session
- [setAudioFocus()](player.md#setaudiofocus) to manage the session Audio Focus
- [startPlayer()](player.md#startplayer) to play an audio file
- [startPlayerFromBuffer](player.md#startplayerfrombuffer) to play data from an App buffer
- [stopPlayer()](player.md#stopplayer) to stop a current playback
- [pausePlayer()](player.md#pauseplayer) to pause the current playback
- [resumePlayer()](player.md#resumeplayer) to resume a paused playback
- [seekPlayer()](player.md#seekplayer) to position directely inside the current playback
- [setVolume()](player.md#setvolume) to adjust the ouput volume
- [playerState, isPlaying, isPaused, isStopped](player.md#playerstate-isplaying-ispaused-isstopped) to know the current player status
- [isDecoderSupported()](player.md#isdecodersupported) to know if a specific codec is supported on the current platform.
- [onProgress]() to subscribe to a Stream of the Progress events
- [setSubscriptionDuration()](player.md#setting-subscription-duration---optional) to specify the frequence of your subscription
- [iosSetCategory(), androidAudioFocusRequest()](player.md#iossetcategory-androidaudiofocusrequest---optional) to parameter the Session Audio Focus

-------------------------------------------------------------------------------------------------------------------

## Creating the `Player` instance.

*Dart definition (prototype) :*
```
/* ctor */ FlutterSoundPlayer()
```

This is the first thing to do, if you want to deal with playbacks. The instanciation of a new player does not do many thing. You are safe if you put this instanciation inside a global or instance variable initialization.

*Example:*
```dart
myPlayer = FlutterSoundPlayer();
```

--------------------------------------------------------------------------------------------------------------------

## `openAudioSession()` and `closeAudioSession()`

*Dart definition (prototype) :*
```
Future<FlutterSoundPlayer> openAudioSession({Focus focus})
Future<void> closeAudioSession()
```

A player must be opened before used. A player correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
When you have finished with a Player, you must close it. With other words, you must close your Audio Session.
Initializing a player takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.

An optional parameter can be specified during the opening : the Audio Focus.
This parameter can have the following values :
- Focus.requestFocusAndStopOthers (your app will have **exclusive use** of the output audio)
- Focus.requestFocusAndDuckOthers (if another App like Spotify use the output audio, its volume will be **lowered**)
- Focus.requestFocusAndKeepOthers (your App will play sound **above** others App)
- Focus.doNotRequestFocus (useful if you want to mangage yourself the Audio Focus with the verb ```setAudioFocus()```)

The Audio Focus is abandoned when you `closeAudioSession()` your player. If your App must play several sounds, you will probably openAudioSession() your player just once, and closeAudioSession() it when you have finished the last sound. If you close and reopen an Audio Session for each sound, you will probably get unpleasant things for the ears with the Audio Focus.

You MUST ensure that the player has been closeAudioSessiond() when your widget is detached from the ui.
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

You maynot openAudioSession many players without releasing them.
You will be very bad if you try something like :
```dart
    while (aCondition)  // *DO'NT DO THAT*
    {
            flutterSound = FlutterSoundPlayer().openAudioSession(); // A **new** Flutter Sound instance is created and openAudioSession
            flutterSound.startPlayer(bipSound);
    }
```

`openAudioSession()` and `closeAudioSession()` return Futures. You may not use your Player before the end of the initialization. So probably you will `await` the result of `openAudioSession()`. This result is the Player itself, so that you can collapse instanciation and initialization together with `player = await FlutterSoundPlayer().openAudioSession();`

*Example:*
```dart
    myPlayer = await FlutterSoundPlayer().openAudioSession(focus: Focus.requestFocusAndDuckOthers);

    ...
    (do something with myPlayer)
    ...

    myPlayer.closeAudioSession();
    myPlayer = null;
```

-----------------------------------------------------------------------------------------------------------------

## `setAudioFocus`

*Dart definition (prototype) :*
```
Future<void> setAudioFocus(Focus focus)
```

The possible values for the parameter are :
- Focus.requestFocus (request focus, but do not do anything special with others App)
- Focus.requestFocusAndStopOthers (your app will have **exclusive use** of the output audio)
- Focus.requestFocusAndDuckOthers (if another App like Spotify use the output audio, its volume will be **lowered**)
- Focus.requestFocusAndKeepOthers (your App will play sound **above** others App)
- Focus.abandonFocus (Your App will not have anymore the audio focus)

*Example:*
```dart
        myPlayer.setAudioFocus(Focus.requestFocusAndDuckOthers);
```

-----------------------------------------------------------------------------------------------------------------

## `startPlayer()`

*Dart definition (prototype) :*
```
Future<void> startPlayer( String uri, {Codec codec, TWhenFinished whenFinished} )
```

You can use both `startPlayer` or `startPlayerFromBuffer` to play a sound. The former takes in a URI that points to the file to play, while the later takes in a buffer containing the file to play and the codec to decode that buffer.

Those two functions can have two optional parameters :

- `codec:` for specifying the audio and file format of the file. Please refer tohe [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
- `whenFinished:()` : A lambda function for specifying what to do when the playback will be finished.

Very often, the `codec:` parameter is not useful. Flutter Sound will adapt itself depending on the real format of the file provided.
But this parameter is necessary when Flutter Sound must do format conversion (for example to play opusOGG on iOS)

`startPlayer()` returns a Future. You must wait for this return value to complete before attempting to add any listeners
to ensure that the player has fully initialised.

*Example:*
```dart
        Directory tempDir = await getTemporaryDirectory();
        File fin = await File ('${tempDir.path}/flutter_sound-tmp.aac');
        await flutterSoundPlayer.startPlayer(fin.path, codec: Codec.aacADTS);

        _playerSubscription = flutterSoundPlayer.onPlayerStateChanged.listen((e)
        {
                // ...
        });
}
```

*Example:*
```dart
    final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";

    await flutterSoundPlayer.startPlayer
    (
                fileUri,
                codec: Codec.mp3,
                whenFinished: ()
                {
                         print( 'I hope you enjoyed listening to this song' );
                },
    );
```

-----------------------------------------------------------------------------------------------------------------------------------

## `startPlayerFromBuffer()`

*Dart definition (prototype) :*
```
Future<void> startPlayer( Uint8List dataBuffer, {Codec codec, TWhenFinished whenFinished} )
```

For playing data from a memory buffer instead of a file, you use the `startPlayerFromBuffer()` verb.
`startPlayerFromBuffer()` is very similar to `startPlayer()` (see above).
The only real distinction is that the parameter is an `Uint8List` data buffer instead of an Uri to a file.

*Example:*
```dart
        // Load a local audio file and get it as a buffer
        Uint8List buffer = (await rootBundle.load('samples/audio.mp3'))
        .buffer
        .asUint8List();

        await flutterSoundPlayer.startPlayerFromBuffer
        (
                buffer,
                codec: Codec.mp3,
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
        await flutterSoundPlayer.stopPlayer();
        if (_playerSubscription != null) {
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
await flutterSoundPlayer.pausePlayer();
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
await flutterSoundPlayer.resumePlayer();
```

-------------------------------------------------------------------------------------------------------------------------------
## `seekPlayer()`

*Dart definition (prototype) :*
```
Future<void> seekPlayer( int milisec )
```

To seek to a new location. The player must already be playing. If not, an exception is thrown.

*Example:*
```dart
await flutterSoundPlayer.seekToPlayer(miliSecs);
```

----------------------------------------------------------------------------------------------------------------------------------

## `setVolume()`

*Dart definition (prototype) :*
```
Future<void> setVolume( double volume )
```

The parameter is a floating point number between 0 and 1.
Volume can be changed when player is running. Try manage this right after player starts.

*Example:*
```dart
await flutterSoundPlayer.setVolume(0.1);
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
        swtich(flutterSoundPlayer.playerState)
        {
                case PlayerState.isPlaying: doSomething; break;
                case PlayerState.isStopped: doSomething; break;
                case PlayerState.isPaused: doSomething; break;
        }
        ...
        if (flutterSoundPlayer.isStopped) doSomething;
        if (flutterSoundPlayer.isPlaying) doSomething;
        if (flutterSoundPlayer.isPaused) doSomething;

```

---------------------------------------------------------------------------------------------------------------------------------

## `isDecoderSupported()`

*Dart definition (prototype) :*
```
 Future<bool> isDecoderSupported(Codec codec)
```

This verb is useful to know if a particular codec is supported on the current platform;
Return a Future<bool>.

*Example:*
```dart
        if ( await flutterSoundPlayer.isDecoderSupported(Codec.opusOGG) ) doSomething;
```

---------------------------------------------------------------------------------------------------------------------------------

## `onProgress`

*Dart definition (prototype) :*
```
Stream<PlayStatus> get onProgress => playerController != null ? playerController.stream : null;
```

The attribut `onProgress` is a stream on which FlutterSound will post the player progression.
You may listen to this Stream to have feedback on the current playback.

*Example:*
```dart
        _playerSubscription = flutterSoundPlayer.onProgress.listen((e)
        {
                double maxDuration = e.duration;
                ...
        }
```
---------------------------------------------------------------------------------------------------------------------------------

## `setSubscriptionDuration` - (Optional)

*Dart definition (prototype) :*
```

Future<void> setSubscriptionDuration(double sec)
```

This verb is used to change the default interval between two post on the "Update Progress" stream. (The default interval is 10ms)

*Example:*
```dart
// 0.010s. is default
flutterSoundPlayer.setSubscriptionDuration(0.01);
```

-------------------------------------------------------------------------------------------------------------------------------

## `iosSetCategory()`, `androidAudioFocusRequest()` - (optional)

*Dart definition (prototype) :*
```
Future<bool> iosSetCategory( SessionCategory category, SessionMode mode, int options )
Future<bool> androidAudioFocusRequest(int focusGain)
```

Those two verbs are OS specific. They are used if your App needs to have fine control on the OS.

You can refer to [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosession/1771734-setcategory) to understand the parameters needed for `iosSetCategory()` and to the [Android documentation](https://developer.android.com/reference/android/media/AudioFocusRequest) to understand the parameter needed for `androidAudioFocusRequest()`.

Remark : `androidAudioFocusRequest` does work on Android before SDK 26.

*Example:*
```dart
if (_duckOthers)
{
        if (Platform.isIOS)
                await flutterSoundPlayer.iosSetCategory( SessionCategory.playAndRecord, SessionMode.defaultSessionMode, iosDuckOthers |  iosDefaultToSpeaker );
        else if (Platform.isAndroid)
                await flutterSoundPlayer.androidAudioFocusRequest( audioFocusGainTransientMayDuck );
} else
{
        if (Platform.isIOS)
                await flutterSoundPlayer.iosSetCategory( SessionCategory.playAndRecord, SessionMode.defaultSessionMode, iosDefaultToSpeaker );
        else if (Platform.isAndroid)
                await flutterSoundPlayer.androidAudioFocusRequest( audioFocusGain );
}
```

---------------------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#flutter-sound-api)
