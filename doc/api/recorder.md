# The τ Recorder

The verbs offered by the Flutter Sound Player module are :

* [Default constructor](recorder.md#creating-the-recorder-instance)
* [openAudioSession\(\) and closeAudioSession\(\)](recorder.md#openaudiosession-and-closeaudiosession) to open or close and audio session
* [setAudioFocus\(\)](recorder.md#setaudiofocus) to manage the session Audio Focus
* [startRecorder\(\)](recorder.md#startrecorder) to start your recorder
* [stopRecorder\(\)](recorder.md#stoprecorder) to stop your current record.
* [pauseRecorder\(\)](recorder.md#pauserecorder) to pause the current record
* [resumeRecorder\(\)](recorder.md#resumerecorder) to resume a paused record
* [recordState, isRecording, isPaused, isStopped](recorder.md#recorderstate-isrecording-ispaused-isstopped) to know the current recorder status
* [isEncoderSupported\(\)](recorder.md#isencodersupported) to know if a specific codec is supported on the current platform.
* [onProgress\(\)](recorder.md#onprogress) to subscribe to a Stream of the Progress events
* [setSubscriptionDuration\(\)](recorder.md#setsubscriptionduration) to specify the frequence of your subscription

## Creating the `Recorder` instance.

This is the first thing to do, if you want to deal with recording. The instanciation of a new recorder does not do many thing. You are safe if you put this instanciation inside a global or instance variable initialization.

_Example:_

```dart
myPlayer = FlutterSoundRecorder();
```

## `openAudioSession()` and `closeAudioSession()`

* [Dart API: openAudioSession](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/openAudioSession.html)
* [Dart API: closeAudioSession](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/closeAudioSession.html)

A recorder must be opened before used. A recorder correspond to an Audio Session. With other words, you must _open_ the Audio Session before using it. When you have finished with a Recorder, you must close it. With other words, you must close your Audio Session. Opening a recorder takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.

You MUST ensure that the recorder has been closed when your widget is detached from the UI. Overload your widget's `dispose()` method to close the recorder when your widget is disposed. In this way you will reset the player and clean up the device resources, but the recorder will be no longer usable.

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

You maynot openAudioSession many recorders without releasing them. You will be very bad if you try something like :

```dart
    while (aCondition)  // *DO'NT DO THAT*
    {
            flutterSound = FlutterSoundRecorder().openAudioSession(); // A **new** Flutter Sound instance is created and opened
            ...
    }
```

`openAudioSession()` and `closeAudioSession()` return Futures. You may not use your Recorder before the end of the initialization. So probably you will `await` the result of `openAudioSession()`. This result is the Recorder itself, so that you can collapse instanciation and initialization together with `myRecorder = await FlutterSoundPlayer().openAudioSession();`

The four optional parameters are used if you want to control the Audio Focus. Please look to [FlutterSoundPlayer openAudioSession\(\)](player.md#openaudiosession-and-closeaudiosession) to understand the meaning of those parameters

_Example:_

```dart
    myRecorder = await FlutterSoundRecorder().openAudioSession();

    ...
    (do something with myRecorder)
    ...

    myRecorder.closeAudioSession();
    myRecorder = null;
```

## `setAudioFocus()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/setAudioFocus.html)

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

## `startRecorder()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/startRecorder.html)

You use `startRecorder()` to start recording in an open session. `startRecorder()` has the destination file path as parameter. It has also 7 optional parameters to specify :

* codec: The codec to be used. Please refer to the [Codec compatibility Table](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
* toFile: a path to the file being recorded
* toStream: if you want to record to a Dart Stream. Please look to [the following notice](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/codec.md#recording-pcm-16-to-a-dart-stream). **This new functionnality needs, at least, Android SDK &gt;= 21 \(23 is better\)**
* sampleRate: The sample rate in Hertz
* numChannels: The number of channels \(1=monophony, 2=stereophony\)
* bitRate: The bit rate in Hertz
* audioSource : possible value is :
  * defaultSource
  * microphone
  * voiceDownlink _\(if someone can explain me what it is, I will be grateful ;-\) \)_

[path\_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.

Flutter Sound does not take care of the recording permission. It is the App responsability to check or require the Recording permission. [Permission\_handler](https://pub.dev/packages/permission_handler) is probably useful to do that.

_Example:_

```dart
    // Request Microphone permission if needed
    PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted)
            throw RecordingPermissionException("Microphone permission not granted");

    Directory tempDir = await getTemporaryDirectory();
    File outputFile = await File ('${tempDir.path}/flutter_sound-tmp.aac');
    await myRecorder.startRecorder(toFile: outputFile.path, codec: t_CODEC.CODEC_AAC,);
```

## `StopRecorder()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/StopRecorder.html)

Use this verb to stop a record. This verb never throws any exception. It is safe to call it everywhere, for example when the App is not sure of the current Audio State and want to recover a clean reset state.

_Example:_

```dart
        await myRecorder.stopRecorder();
        if (_recorderSubscription != null)
        {
                _recorderSubscription.cancel();
                _recorderSubscription = null;
        }
}
```

## PauseRecorder\(\)

Dart API\]\([https://canardoux.github.io/tau/doc/flutter\_sound/api/recorder/FlutterSoundRecorder/PauseRecorder.html](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/PauseRecorder.html)\)

On Android this API verb needs al least SDK-24. An exception is thrown if the Recorder is not currently recording.

_Example:_

```dart
await myRecorder.pauseRecorder();
```

## ResumeRecorder\(\)

Dart API\]\([https://canardoux.github.io/tau/doc/flutter\_sound/api/recorder/FlutterSoundRecorder/ResumeRecorder.html](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/ResumeRecorder.html)\)

On Android this API verb needs al least SDK-24. An exception is thrown if the Recorder is not currently paused.

_Example:_

```dart
await myRecorder.resumeRecorder();
```

## `recorderState`, `isRecording`, `isPaused`, `isStopped`

-[Dart API: isRecording](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/isRecording.html) -[Dart API: isStopped](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/isStopped.html) -[Dart API: isPaused](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/isPaused.html) -[Dart API: recorderState](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/RecorderState.html)

This four verbs is used when the app wants to get the current Audio State of the recorder.

`recorderState` is an attribut which can have the following values :

* isStopped   /// Recorder is stopped
* isRecording   /// Recorder is recording
* isPaused    /// Recorder is paused
* isRecording is a boolean attribut which is `true` when the recorder is in the "Recording" mode.
* isPaused is a boolean atrribut which  is `true` when the recorder is in the "Paused" mode.
* isStopped is a boolean atrribut which  is `true` when the recorder is in the "Stopped" mode.

_Example:_

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

## `isEncoderSupported()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/isEncoderSupported.html)

This verb is useful to know if a particular codec is supported on the current platform; Return a Future.

_Example:_

```dart
        if ( await myRecorder.isEncoderSupported(Codec.opusOGG) ) doSomething;
```

## `onProgress`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/onProgress.html)

The attribut `onProgress` is a stream on which FlutterSound will post the recorder progression. You may listen to this Stream to have feedback on the current recording.

_Example:_

```dart
        _recorderSubscription = myrecorder.onProgress.listen((e)
        {
                Duration maxDuration = e.duration;
                double decibels = e.decibels
                ...
        }
```

## `setSubscriptionDuration()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/setSubscriptionDuration.html)

This verb is used to change the default interval between two post on the "Update Progress" stream. \(The default interval is 0 \(zero\) which means "NO post"\)

_Example:_

```dart
// 0. is default
myRecorder.setSubscriptionDuration(0.010);
```
