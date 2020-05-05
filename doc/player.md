# Flutter Sound Player API

The verbs offered by the Flutter Sound Player module are :

- [Default constructor](player.md#creating-the-player-instance)
- [initialize() and release()](player.md#initialize-and-release) to open or close and audio session
- [setAudioFocus()](player.md#initialize-and-release) to manage the session Audio Focus
- [startPlayer()](player.md#startplayer) to play an audio file
- [startPlayerFromBuffer](player.md#startplayerfrombuffer) to play data from an App buffer
- [stopPlayer()](player.md#stopplayer) to stop a current playback
- `pausePlayer()` to pause the current playback
- `resumePlayer()` to resume a paused playback
- `seekPlayer()` to position directely inside the current playback
- `setVolume()` to adjust the ouput volume
- `playerState`, `isPlaying`, `isPaused`, `isStopped` to know the current player status
- `iosSetCategory()`, `androidAudioFocusRequest()` and `setActive()` to parameter the Session Audio Focus
- setSubscriptionDuration to specify the frequence of your subscription

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

## `initialize()` and `release()`

*Dart definition (prototype) :*
```
Future<FlutterSoundPlayer> initialize({Focus focus})
Future<void> release()
```

A player must be *initialized* before used. A player correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
When you have finished with a Player, you must release it. With other words, you must close your Audio Session.
Initializing a player takes resources inside the OS. Those resources are freed with the verb `release()`.

An optional parameter can be specified during the initialization : the Audio Focus.
This parameter can have the following values :
- Focus.requestFocusAndStopOthers (your app will have **exclusive use** of the output audio)
- Focus.requestFocusAndDuckOthers (if another App like Spotify use the output audio, its volume will be **lowered**)
- Focus.requestFocusAndKeepOthers (your App will play sound **above** others App)
- Focus.doNotRequestFocus (useful if you want to mangage yourself the Audio Focus with the verb ```setAudioFocus()```)

The Audio Focus is abandoned when you `release()` your player. If your App must play several sounds, you will probably initialize your player just once, and release it when you have finished the last one. If you close and reopen an Audio Session for each sound, you will probably get unpleasant things for the ears with the Audio Focus.

You MUST ensure that the player has been released when your widget is detached from the ui.
Overload your widget's `dispose()` method to release the player when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the player will be no longer usable.

```dart
@override
void dispose()
{
        if (myPlayer != null)
        {
            myPlayer.release();
            myPlayer = null;
        }
        super.dispose();
}
```

You maynot initialize many players without releasing them.
You will be very bad if you try something like :
```dart
    while (aCondition)  // *DO'NT DO THAT*
    {
            flutterSound = FlutterSoundPlayer().initialize(); // A **new** Flutter Sound instance is created and initialize
            flutterSound.startPlayer(bipSound);
    }
```

`initialize()` and `release()` return Futures. You may not use your Player before the end of the initialization. So probably you will `await` the result of `initialize()`. This result is the Player itself, so that you can collapse instanciation and initialization together with `player = await FlutterSoundPlayer().initialize();`

*Example:*
```dart
    myPlayer = await FlutterSoundPlayer().initialize(focus: Focus.requestFocusAndDuckOthers);

    ...
    (do something with myPlayer)
    ...

    myPlayer.release();
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

- `whenFinished:()` : A lambda function for specifying what to do when the playback will be finished.
- `codec:` for specifying the audio and file format of the file.

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
// An example audio file
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

-----------------------------------------------------------------------------------------------------------------------------------

## `startPlayerFromBuffer()`

For playing data from a memory buffer instead of a file, you can do the following :

```dart
Uint8List buffer =  (await rootBundle.load(assetSample[_codec.index])).buffer.asUint8List();
String result = await flutterSoundPlayer.startPlayerFromBuffer
        (
                buffer,
                codec: t_CODEC.CODEC_AAC,
                whenFinished: ()
                {
                         print( 'I hope you enjoyed listening to this song' );
                },
        );
```

---------------------------------------------------------------------------------------------------------------------------------

## `stopPlayer()`

```dart
Future<String> result = await flutterSoundPlayer.stopPlayer();

result.then(value) {
        print('stopPlayer: $result');
        if (_playerSubscription != null) {
                _playerSubscription.cancel();
                _playerSubscription = null;
        }
}
```

You MUST ensure that the player has been stopped when your widget is detached from the ui.
Overload your widget's dispose() method to stop the player when your widget is disposed.

```dart
@override
void dispose() {
        flutterSoundPlayer.release();
        super.dispose();
}
```

---------------------------------------------------------------------------------------------------------------------------------

## `pausePlayer()`

```dart
Future<String> result = await flutterSoundPlayer.pausePlayer();
```

--------------------------------------------------------------------------------------------------------------------------------

## `resumePlayer()`

```dart
Future<String> result = await flutterSoundPlayer.resumePlayer();
```

-------------------------------------------------------------------------------------------------------------------------------
## `seekPlayer()`


To seek to a new location the player must already be playing.

```dart
String Future<result> = await flutterSoundPlayer.seekToPlayer(miliSecs);
```

----------------------------------------------------------------------------------------------------------------------------------

## `setVolume()`

```dart
/// 1.0 is default
/// Currently, volume can be changed when player is running. Try manage this right after player starts.
String path = await flutterSoundPlayer.startPlayer(fileUri);
await flutterSoundPlayer.setVolume(0.1);
```

---------------------------------------------------------------------------------------------------------------------------------

## `playerState`, `isPlaying`, `isPaused`, `isStopped`

-------------------------------------------------------------------------------------------------------------------------------

## `iosSetCategory()`, `androidAudioFocusRequest()` and `setActive()` - (optional)

Those three functions are optional. If you do not control the audio focus with the function `setActive()`, flutter_sound will require the audio focus each time the function `startPlayer()` is called and will release it when the sound is finished or when you call the function `stopPlayer()`.

Before controling the focus with `setActive()` you must call `iosSetCategory()` on iOS or `androidAudioFocusRequest()` on Android. `setActive()` and `androidAudioFocusRequest()` are useful if you want to `duck others`.
Those functions are probably called just once when the app starts.
After calling this function, the caller is responsible for using correctly `setActive()`
probably before startRecorder or startPlayer, and stopPlayer and stopRecorder.

You can refer to [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosession/1771734-setcategory) to understand the parameters needed for `iosSetCategory()` and to the [Android documentation](https://developer.android.com/reference/android/media/AudioFocusRequest) to understand the parameter needed for `androidAudioFocusRequest()`.

Remark : those three functions does work on Android before SDK 26.

```dart
if (_duckOthers)
{
        if (Platform.isIOS)
                await flutterSoundPlayer.iosSetCategory( t_IOS_SESSION_CATEGORY.PLAY_AND_RECORD, t_IOS_SESSION_MODE.DEFAULT, IOS_DUCK_OTHERS |  IOS_DEFAULT_TO_SPEAKER );
        else if (Platform.isAndroid)
                await flutterSoundPlayer.androidAudioFocusRequest( ANDROID_AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK );
} else
{
        if (Platform.isIOS)
                await flutterSoundPlayer.iosSetCategory( t_IOS_SESSION_CATEGORY.PLAY_AND_RECORD, t_IOS_SESSION_MODE.DEFAULT, IOS_DEFAULT_TO_SPEAKER );
        else if (Platform.isAndroid)
                await flutterSoundPlayer.androidAudioFocusRequest( ANDROID_AUDIOFOCUS_GAIN );
}
...
...
flutterSoundPlayer.setActive(true); // Get the audio focus
flutterSoundPlayer.startPlayer(aSound);
flutterSoundPlayer.startPlayer(anotherSong);
flutterSoundPlayer.setActive(false); // Release the audio focus
```

---------------------------------------------------------------------------------------------------------------------------------

## Setting subscription duration (Optional). 0.010 is default value when not set.

```dart
/// 0.01 is default
flutterSoundPlayer.setSubscriptionDuration(0.01);
```

---------------------------------------------------------------------------------------------------------------------------------

