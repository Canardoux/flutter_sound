
[Back to the README](../README.md#flutter-sound-api)

-----------------------------------------------------------------------------------------------------------------------

# Flutter Sound Recorder API

The verbs offered by the Flutter Sound Player module are :


## Subscriptions

| Subscription           |      Return      |                     Description                      |
| :--------------------- | :--------------: | :--------------------------------------------------: |
| onRecorderStateChanged | `<RecordStatus>` | Able to listen to subscription when recorder starts. |
| onPlayerStateChanged   |  `<PlayStatus>`  |  Able to listen to subscription when player starts.  |

## Default uri path

When uri path is not set during the `function call` in `startRecorder` or `startPlayer`, records are saved/read to/from a temporary directory depending on the platform.


## FlutterSoundRecorder Usage

#### Creating instance.

In your view/page/dialog widget's State class, create an instance of FlutterSoundRecorder.
Before acessing the FlutterSoundRecorder API, you must initialize it with initialize().
When finished with this FlutterSoundRecorder instance, you must release it with release().

```dart
FlutterSoundRecorder flutterSoundRecorder = new FlutterSoundRecorder().initialize();

...
...

flutterSoundRecorder.release();
```

#### Starting recorder with listener.

```dart
Future<String> result = await flutterSoundRecorder.startRecorder(codec: t_CODEC.CODEC_AAC,);

result.then(path) {
        print('startRecorder: $path');

        _recorderSubscription = flutterSoundRecorder.onRecorderStateChanged.listen((e) {
        DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
        String txt = DateFormat('mm:ss:SS', 'en_US').format(date);
        });
}
```

The recorded file will be stored in a temporary directory. If you want to take your own path specify it like below. We are using [path_provider](https://pub.dev/packages/path_provider) in below so you may have to install it.

```
Directory tempDir = await getTemporaryDirectory();
File outputFile = await File ('${tempDir.path}/flutter_sound-tmp.aac');
String path = await flutterSoundRecorder.startRecorder(outputFile.path, codec: t_CODEC.CODEC_AAC,);
```

If the App does nothing special, ```startRecorder()``` will take care of controlling the permissions, and request itself the permission
for Recording, if necessary. If the Application wants to control itself the permissions, without any help from flutter_sound,
it must specify :
```
myFlutterSoundModule.requestPermission = false;
await myFlutterSoundModule.startRecorder(...);
```

Actually on iOS, you can choose from four encoders :

- AAC (this is the default)
- CAF/OPUS
- OGG/OPUS
- PCM

For example, to encode with OPUS you do the following :

```dart
await flutterSoundRecorder.startRecorder(foot.path, codec: t_CODEC.CODEC_OPUS,)
```

Note : On Android the OPUS codec and the PCM are not yet supported by flutter_sound Recorder. (But Player is OK on Android)

#### Stop recorder

```dart
Future<String> result = await flutterSoundRecorder.stopRecorder();

result.then(value) {
        print('stopRecorder: $value');

        if (_recorderSubscription != null) {
                _recorderSubscription.cancel();
                _recorderSubscription = null;
        }
}
```

You MUST ensure that the recorder has been stopped when your widget is detached from the ui.
Overload your widget's dispose() method to stop the recorder when your widget is disposed.

```dart
@override
void dispose() {
        flutterSoundRecorder.release();
        super.dispose();
}
```

#### Pause recorder

On Android this API verb needs al least SDK-24.

```dart
Future<String> result = await flutterSoundRecorder.pauseRecorder();
```

#### Resume recorder

On Android this API verb needs al least SDK-24.

```dart
Future<String> result = await flutterSoundRecorder.resumeRecorder();
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
_dbPeakSubscription = flutterSoundRecorder.onRecorderDbPeakChanged.listen((value) {
  setState(() {
    this._dbLevel = value;
  });
});
```
