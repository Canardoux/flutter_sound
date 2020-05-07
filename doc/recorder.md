
[Back to the README](../README.md#flutter-sound-api)

-----------------------------------------------------------------------------------------------------------------------

# Flutter Sound Recorder API

The verbs offered by the Flutter Sound Player module are :

- [Default constructor](recorder.md#creating-the-player-instance)
- [openAudioSession() and closeAudioSession()](recorder.md#openAudioSession-and-closeAudioSession) to open or close and audio session
- [startRecorder()]() to start your recorder
- [stopRecorder()]() to stop your current record.
- [pauseRecorder()]() to pause the current record
- [resumeRecorder()] to resume a paused record
- [recordState, isRecording, isPaused, isStopped]() to know the current recorder status
- [isEncoderSupported()] to know if a specific codec is supported on the current platform.
- [onProgress()](recorder.md#onprogress) to subscribe to a Stream of the Progress events
- [setSubscriptionDuration()](recorder.md#setsubscriptionduration---optional) to specify the frequence of your subscription
- [onRecorderDbPeakChanged()]() to subscribe to a Stream of the DB peaks events
- [setDbPeakLevelUpdate()]()  to specify the frequence of your subscription
- [setDbLevelEnabled()]() to enable or disable the DB peak stream

-------------------------------------------------------------------------------------------------------------------

## Creating the `Recorder` instance.

*Dart definition (prototype) :*
```
/* ctor */ FlutterSoundRecorder()
```

This is the first thing to do, if you want to deal with recording. The instanciation of a new recorder does not do many thing. You are safe if you put this instanciation inside a global or instance variable initialization.

*Example:*
```dart
myPlayer = FlutterSoundRecorder();
```

--------------------------------------------------------------------------------------------------------------------

## `openAudioSession()` and `closeAudioSession()`

*Dart definition (prototype) :*
```
Future<FlutterSoundPlayer> openAudioSession()
Future<void> closeAudioSession()
```

A recorder must be opened before used. A recorder correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
When you have finished with a Recorder, you must close it. With other words, you must close your Audio Session.
Opening a recorder takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.

You MUST ensure that the recorder has been closed when your widget is detached from the UI.
Overload your widget's `dispose()` method to close the recorder when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the recorder will be no longer usable.

```dart
@override
void dispose()
{
        if (myRecorder != null)
        {
            myRecorder.closeAudioSession();
            myPlayer = null;
        }
        super.dispose();
}
```

You maynot openAudioSession many recorders without releasing them.
You will be very bad if you try something like :
```dart
    while (aCondition)  // *DO'NT DO THAT*
    {
            flutterSound = FlutterSoundRecorder().openAudioSession(); // A **new** Flutter Sound instance is created and opened
            ...
    }
```

`openAudioSession()` and `closeAudioSession()` return Futures. You may not use your Recorder before the end of the initialization. So probably you will `await` the result of `openAudioSession()`. This result is the Recorder itself, so that you can collapse instanciation and initialization together with `myRecorder = await FlutterSoundPlayer().openAudioSession();`

*Example:*
```dart
    myRecorder = await FlutterSoundRecorder().openAudioSession();

    ...
    (do something with myRecorder)
    ...

    myRecorder.closeAudioSession();
    myRecorder = null;
```

-----------------------------------------------------------------------------------------------------------------

## `startRecorder()`

*Dart definition (prototype) :*
```
    Future<void> startRecorder( String path,
        {
                Codec codec = Codec.aacADTS,
                int sampleRate = 16000,
                int numChannels = 1,
                int bitRate = 16000,
        })
```

You use `startRecorder()` to start recording in an open session. `startRecorder()` has the destination file path as parameter.
It has also 4 optional parameters to specify :
- The codec to be used. Please refer to the [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
- The sample rate in Hertz
- The number of channels (1=monophony, 2=stereophony)
- The bit rate in Hertz

[path_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.

Flutter Sound does not take care of the recording permission. It is the App responsability to check or require the Recording permission.
[Permission_handler](https://pub.dev/packages/permission_handler) is probably useful to do that.

*Example:*
```dart
    // Request Microphone permission if needed
    PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted)
            throw RecordingPermissionException("Microphone permission not granted");

    Directory tempDir = await getTemporaryDirectory();
    File outputFile = await File ('${tempDir.path}/flutter_sound-tmp.aac');
    await myRecorder.startRecorder(outputFile.path, codec: t_CODEC.CODEC_AAC,);
```

----------------------------------------------------------------------------------------------------------------------

## `StopRecorder()`

*Dart definition (prototype) :*
```
Future<void> stopRecorder( )
```

Use this verb to stop a record. This verb never throw any exception. It is safe to call it everywhere,
for example when the App is not sure of the current Audio State and want to recover a clean reset state.

*Example:*
```dart
        await myRecorder.stopRecorder();
        if (_recorderSubscription != null)
        {
                _recorderSubscription.cancel();
                _recorderSubscription = null;
        }
}
```

------------------------------------------------------------------------------------------------------------------------

## Pause recorder

*Dart definition (prototype) :*
```
Future<void> pauseRecorder( )
```

On Android this API verb needs al least SDK-24.

*Example:*
```dart
await myRecorder.pauseRecorder();
```

--------------------------------------------------------------------------------------------------------------------------

#### Resume recorder

On Android this API verb needs al least SDK-24.

```dart
Future<String> result = await myRecorder.resumeRecorder();
```

#### Using the amplitude meter

The amplitude meter allows displaying a basic representation of the input sound.
When enabled, it returns values ranging 0-120dB.

```dart
//// By default this option is disabled, you can enable it by calling
setDbLevelEnabled(true);
```

```dart
//// You can tweak the frequency of updates by calling this function (unit is seconds)
updateDbPeakProgress(0.8);
```

```dart
//// You need to subscribe in order to receive the value updates
_dbPeakSubscription = myRecorder.onRecorderDbPeakChanged.listen((value) {
  setState(() {
    this._dbLevel = value;
  });
});
```
