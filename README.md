# flutter_sound

<img src="https://raw.githubusercontent.com/dooboolab/flutter_sound/master/Logotype primary.png" width="70%" height="70%" />

<p align="left">
  <a href="https://pub.dartlang.org/packages/flutter_sound"><img alt="pub version" src="https://img.shields.io/pub/v/flutter_sound.svg?style=flat-square"></a>
</p>
This plugin provides simple recorder and player functionalities for both `android` and `ios` platforms. This only supports default file extension for each platform.
This plugin handles file from remote url.
This plugin can handle playback stream from native (To sync exact time with bridging).
<br/><img src="https://firebasestorage.googleapis.com/v0/b/flutterdart-5d354.appspot.com/o/flutter_sound.gif?alt=media&token=f9e01ee6-0dc6-4988-b96a-52cc4f4824c4"/>

## Free Read
[Medium Blog](https://medium.com/@dooboolab/flutter-sound-plugin-audio-recorder-player-e5a455a8beaf)

## Getting Started
For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

## Install
Add ```flutter_sound``` as a dependency in pubspec.yaml.
For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).</br>
Add ```permission_handler``` as a dependency in pubspec.yaml. Refer to [here](permission_handler) for help.</br>
If you need ffmpeg, add ```flutter_ffmpeg``` as a dependency in pubspec.yaml. Refer to [here](https://github.com/tanersener/flutter-ffmpeg) for help.

## Post Installation
On *iOS* you need to add a usage description to `info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This sample uses the microphone to record your speech and convert it to text.</string>
<key>UIBackgroundModes</key>
<array>
	<string>audio</string>
</array>
```

On *Android* you need to add a permission to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Migration Guide
To migrate to `2.0.0` you must migrate your Android app to Android X by following the [Migrating to AndroidX Guide](https://developer.android.com/jetpack/androidx/migrate).

## Methods
| Func  | Param  | Return | Description |
| :------------ |:---------------:| :---------------:| :-----|
| setSubscriptionDuration | `double sec` | `String` message | Set subscription timer in seconds. Default is `0.01` if not using this method.|
| startRecorder | `String uri`, `int sampleRate`, `int numChannels`, `t_CODEC codec` | `String` uri | Start recording. This will return uri used. |
| stopRecorder | | `String` message | Stop recording.  |
| startPlayer | `String uri`, `t_CODEC codec`  | `String` message | Start playing.  |
| startPlayerFromBuffer | `Uint8List dataBuffer`,  `t_CODEC codec` | `String` message | Start playing.  |
| stopPlayer | | `String` message | Stop playing. |
| pausePlayer | | `String` message | Pause playing. |
| resumePlayer | | `String` message | Resume playing. |
| seekToPlayer | `int milliSecs` position to goTo | `String` message | Seek audio to selected position in seconds. Parameter should be less than audio duration to correctly placed. |

## Subscriptions
| Subscription | Return | Description |
| :------------ |:---------------:| :---------------:|
| onRecorderStateChanged | `<RecordStatus>` | Able to listen to subscription when recorder starts. |
| onPlayerStateChanged | `<PlayStatus>` | Able to listen to subscription when player starts. |


## Default uri path
When uri path is not set during the `function call` in `startRecorder` or `startPlayer`, records are saved/read to/from a temporary directory depending on the platform.


## Codec compatibility
Actually, the following codecs are supported by flutter_sound:

| | AAC  | OGG/Opus  | CAF/Opus | MP3 | OGG/Vorbis | PCM |
| :------------ |:---------------:| :---------------:| :-----| :-----| :-----| :-----|
| iOS encoder| Yes | Yes | Yes | No | No | No |
| iOS decoder| Yes | Yes | Yes | Yes | No | Yes |
| Android encoder| Yes | No | No | No | No | No |
| Android decoder| Yes | Yes | No | Yes | Yes | Yes |

This table will eventually be upgrated when more codecs will be added.




## Usage
#### Creating instance.
In your view/page/dialog widget's State class, create an instance of FlutterSound.

```dart
FlutterSound flutterSound = new FlutterSound();
```

#### Starting recorder with listener.
```dart
Future<String> result = await flutterSound.startRecorder(codec: t_CODEC.CODEC_AAC,);

result.then(path) {
	print('startRecorder: $path');

	_recorderSubscription = flutterSound.onRecorderStateChanged.listen((e) {
	DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
	String txt = DateFormat('mm:ss:SS', 'en_US').format(date);
	});
}
```

The recorded file will be stored in a temporary directory. If you want to take your own path specify it like below.
```
Directory tempDir = await getTemporaryDirectory();
File outputFile = await File ('${tempDir.path}/flutter_sound-tmp.aac');
String path = await flutterSound.startRecorder(outputFile.path, codec: t_CODEC.CODEC_AAC,);
```

Actually on iOS, you can choose from three encoders :
- AAC (this is the default)
- CAF/OPUS
-  OGG/OPUS

Recently, Apple added a support for encoding with the standard OPUS codec. Unfortunatly, Apple encapsulates its data in its own proprietary envelope : CAF. This is really stupid, this is Apple. If you need to record with regular OGG/OPUS you must add `flutter_ffmpeg` to your dependencies.
Please, look to the [flutter_ffmpeg plugin README](https://pub.dev/packages/flutter_ffmpeg) for instructions for how to include this plugin into your app

To encode with OPUS you do the following :
```dart
await flutterSound.startRecorder(foot.path, codec: t_CODEC.CODEC_OPUS,)
```

On Android the OPUS codec is not yet supported by flutter_sound Recorder. (But Player is OK on Android)

#### Stop recorder
```dart
Future<String> result = await flutterSound.stopRecorder();

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
	flutterSound.stopRecorder();
	super.dispose();
}
```

#### Start player
- To start playback of a record from a URL call startPlayer.
- To start playback of a record from a memory buffer call startPlayerFromBuffer

You must wait for the return value to complete before attempting to add any listeners
to ensure that the player has fully initialised.

```dart
Directory tempDir = await getTemporaryDirectory();
File fin = await File ('${tempDir.path}/flutter_sound-tmp.aac');
Future<String> result = await flutterSound.startPlayer(fin.path);

result.then(path) {
	print('startPlayer: $path');

	_playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
		if (e != null) {
			DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
			String txt = DateFormat('mm:ss:SS', 'en_US').format(date);
			this.setState(() {
				this._isPlaying = true;
				this._playerTxt = txt.substring(0, 8);
			});
		}
	});
}
```

#### Start player from buffer

For playing data from a memory buffer instead of a file, you can do the following :

```dart
Uint8List buffer =  (await rootBundle.load(assetSample[_codec.index])).buffer.asUint8List();
path = await flutterSound.startPlayerFromBuffer(buffer, codec: t_CODEC.CODEC_AAC,);
```

#### Stop player


```dart
Future<String> result = await flutterSound.stopPlayer();

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
	flutterSound.stopPlayer();
	super.dispose();
}
```

#### Pause player
```dart
Future<String> result = await flutterSound.pausePlayer();
```

#### Resume player
```dart
Future<String> result = await flutterSound.resumePlayer();
```

#### Seek player

To seek to a new location the player must already be playing.
```dart
String Future<result> = await flutterSound.seekToPlayer(miliSecs);
```

#### Setting subscription duration (Optional). 0.01 is default value when not set.
```dart
/// 0.01 is default
flutterSound.setSubscriptionDuration(0.01);
```

#### Setting volume.
```dart
/// 1.0 is default
/// Currently, volume can be changed when player is running. Try manage this right after player starts.
String path = await flutterSound.startPlayer(null);
await flutterSound.setVolume(0.1);
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
_dbPeakSubscription = flutterSound.onRecorderDbPeakChanged.listen((value) {
  setState(() {
    this._dbLevel = value;
  });
});
```

#### Playing OGG/OPUS on iOS

To play OGG/OPUS on iOS you must add flutter_ffmpeg to your dependencies.
Please, look to the [flutter_ffmpeg plugin README](https://pub.dev/packages/flutter_ffmpeg) for instructions for how to include this plugin into your app. Playing OGG/OPUS on Android is no problem, even without flutter_ffmpeg. Please notice that [flutter_ffmpeg plugin](https://pub.dev/packages/flutter_ffmpeg) on Android needs a minAndroidSdk 16 (or later) if you use the LTS Release, but minAndroidSdk 24 (or later) if you use the Main Release.

### TODO
- [ ] Seeking example in `Example` project
- [x] Volume Control
- [x] Sync timing for recorder callback handler


### DEBUG
When you face below error,
```
* What went wrong:
A problem occurred evaluating project ':app'.
> versionCode not found. Define flutter.versionCode in the local.properties file.
```
Please add below to your `example/android/local.properties` file.
```
flutter.versionName=1.0.0
flutter.versionCode=1
flutter.buildMode=debug
```


## Help Maintenance
I've been maintaining quite many repos these days and burning out slowly. If you could help me cheer up, buying me a cup of coffee will make my life really happy and get much energy out of it.
<br/>
<a href="https://www.buymeacoffee.com/dooboolab" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>
[![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/dooboolab)
