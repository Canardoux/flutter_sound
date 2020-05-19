
[Back to the README](../README.md#flutter-sound-api)

-----------------------------------------------------------------------------------------------------------------------

# Flutter Sound Recorder API

The verbs offered by the Flutter Sound Player module are :

- [Default constructor](#creating-the-player-instance)
- [openAudioSession() and closeAudioSession()](#openAudioSession-and-closeAudioSession) to open or close and audio session
- [startRecorder()](#startrecorder) to start your recorder
- [stopRecorder()](#stoprecorder) to stop your current record.
- [pauseRecorder()](#pauserecorder) to pause the current record
- [resumeRecorder()](#resumerecorder) to resume a paused record
- [recordState, isRecording, isPaused, isStopped](#recorderstate-isrecording-ispaused-isstopped) to know the current recorder status
- [isEncoderSupported()](#isencodersupported) to know if a specific codec is supported on the current platform.
- [onProgress()](#onprogress) to subscribe to a Stream of the Progress events
- [setSubscriptionDuration()](#setsubscriptionduration) to specify the frequence of your subscription

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
Future<FlutterSoundRecorder> openAudioSession
({
        AudioFocus focus = AudioFocus.requestFocusTransient,
        SessionCategory category = SessionCategory.playAndRecord,
        SessionMode mode = SessionMode.modeDefault,
        int audioFlags = outputToSpeaker
})

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

The four optional parameters are used if you want to control the Audio Focus. Please look to [FlutterSoundPlayer openAudioSession()](player.md#openaudiosession-and-closeaudiosession) to understand the meaning of those parameters

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
    Future<void> startRecorder(
        {
                Codec codec = Codec.aacADTS,
                String toFile,
                Stream toStream,
                int sampleRate = 16000,
                int numChannels = 1,
                int bitRate = 16000,
                AudioSource audioSource = AudioSource.DefaultSource,
        })
```

You use `startRecorder()` to start recording in an open session. `startRecorder()` has the destination file path as parameter.
It has also 7 optional parameters to specify :
- codec: The codec to be used. Please refer to the [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
- toFile: a path to the file being recorded
- toStream: if you want to record to a Dart Stream *(not yet implemented)*
- sampleRate: The sample rate in Hertz
- numChannels: The number of channels (1=monophony, 2=stereophony)
- bitRate: The bit rate in Hertz
- audioSource : possible value is :
   - defaultSource
   - microphone
   - voiceDownlink *(if someone can explain me what it is, I will be grateful ;-) )*

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
    await myRecorder.startRecorder(toFile: outputFile.path, codec: t_CODEC.CODEC_AAC,);
```

----------------------------------------------------------------------------------------------------------------------

## `StopRecorder()`

*Dart definition (prototype) :*
```
Future<void> stopRecorder( )
```

Use this verb to stop a record. This verb never throws any exception. It is safe to call it everywhere,
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

## PauseRecorder()

*Dart definition (prototype) :*
```
Future<void> pauseRecorder( )
```

On Android this API verb needs al least SDK-24.
An exception is thrown if the Recorder is not currently recording.

*Example:*
```dart
await myRecorder.pauseRecorder();
```

--------------------------------------------------------------------------------------------------------------------------

## ResumeRecorder()


*Dart definition (prototype) :*
```
Future<void> resumeRecorder( )
```

On Android this API verb needs al least SDK-24.
An exception is thrown if the Recorder is not currently paused.

*Example:*
```dart
await myRecorder.resumeRecorder();
```

---------------------------------------------------------------------------------------------------------------------------------

## `recorderState`, `isRecording`, `isPaused`, `isStopped`

*Dart definition (prototype) :*
```
    RecorderState recorderState;
    bool get isrecording => recorderState == RecorderState.isRecording;
    bool get isPaused => recorderState == RecorderState.isPaused;
    bool get isStopped => recorderState == RecorderState.isStopped;
```

This four verbs is used when the app wants to get the current Audio State of the recorder.

`recorderState` is an attribut which can have the following values :

  - isStopped   /// Recorder is stopped
  - isRecording   /// Recorder is recording
  - isPaused    /// Recorder is paused

- isRecording is a boolean attribut which is `true` when the recorder is in the "Recording" mode.
- isPaused is a boolean atrribut which  is `true` when the recorder is in the "Paused" mode.
- isStopped is a boolean atrribut which  is `true` when the recorder is in the "Stopped" mode.

*Example:*
```dart
        swtich(myRecorder.recorderState)
        {
                case RecorderState.isRecording: doSomething; break;
                case RecorderState.isStopped: doSomething; break;
                case RecorderState.isPaused: doSomething; break;
        }
        ...
        if (myRecorder.isStopped) doSomething;
        if (myRecorder.isRecording) doSomething;
        if (myRecorder.isPaused) doSomething;

```

---------------------------------------------------------------------------------------------------------------------------------

## `isEncoderSupported()`

*Dart definition (prototype) :*
```
 Future<bool> isEncoderSupported(Codec codec)
```

This verb is useful to know if a particular codec is supported on the current platform;
Return a Future<bool>.

*Example:*
```dart
        if ( await myRecorder.isEncoderSupported(Codec.opusOGG) ) doSomething;
```

---------------------------------------------------------------------------------------------------------------------------------

## `onProgress`

*Dart definition (prototype) :*
```
Stream<RecorderStatus> get onProgress => recorderController != null ? recorderController.stream : null;
```

The attribut `onProgress` is a stream on which FlutterSound will post the recorder progression.
You may listen to this Stream to have feedback on the current recording.

*Example:*
```dart
        _recorderSubscription = myrecorder.onProgress.listen((e)
        {
                Duration maxDuration = e.duration;
                double decibels = e.decibels
                ...
        }
```

---------------------------------------------------------------------------------------------------------------------------------

## `setSubscriptionDuration()`

*Dart definition (prototype) :*
```
Future<void> setSubscriptionDuration(double sec)
```

This verb is used to change the default interval between two post on the "Update Progress" stream. (The default interval is 10ms)

*Example:*
```dart
// 0.010s. is default
myRecorder.setSubscriptionDuration(0.010);
```

---------------------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#flutter-sound-api)

