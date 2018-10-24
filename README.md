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
Add ```flutter_sound``` as a dependency in pubspec.yaml
For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

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

## Methods
| Func  | Param  | Return | Description |
| :------------ |:---------------:| :---------------:| :-----|
| setSubscriptionDuration | `double sec` | `String` message | Set subscription timer in seconds. Default is `0.01` if not using this method.|
| startRecorder | `String uri` | `String` uri | Start recording. This will return uri used. |
| stopRecorder | | `String` message | Stop recording.  |
| startPlayer | `String uri` | `String` message | Start playing.  |
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
When uri path is not set during the `function call` in `startRecorder` or `startPlayer`, they are saved in below path depending on the platform.
+ Default path for android
  * `sdcard/sound.mp4`.
+ Default path for ios
  * `sound.m4a`.

## Usage
#### Creating instance.
```dart
FlutterSound flutterSound = new FlutterSound();
```

#### Starting recorder with listener.
```dart
String path = await flutterSound.startPlayer(null);
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
```

#### Stop recorder
```dart
String result = await flutterSound.stopRecorder();
print('stopRecorder: $result');

if (_recorderSubscription != null) {
	_recorderSubscription.cancel();
	_recorderSubscription = null;
}
```

#### Start player
```dart
String path = await flutterSound.startPlayer(null);
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
```

#### Stop player
```dart
String result = await flutterSound.stopPlayer();
print('stopPlayer: $result');
if (_playerSubscription != null) {
	_playerSubscription.cancel();
	_playerSubscription = null;
}
```

#### Pause player
```dart
String result = await flutterSound.pausePlayer();
```

#### Resume player
```dart
String result = await flutterSound.resumePlayer();
```

#### Seek player
```dart
String result = await flutterSound.seekToPlayer(miliSecs);
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

### TODO
- [ ] Seeking example in `Exmaple` project
- [x] Volume Control
- [x] Sync timing for recorder callback handler 


## Help Maintenance
I've been maintaining quite many repos these days and burning out slowly. If you could help me cheer up, buying me a cup of coffee will make my life really happy and get much energy out of it.
<br/><a href="https://www.buymeacoffee.com/dooboolab" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>
