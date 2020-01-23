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
| initialize | `Function skipForwardHandler`, `Function skipBackwardForward` | `void` | Initializes the media player and all the callbacks for the player and the recorder. This must be called before all other media player and recorder methods.| 
| releaseMediaPlayer |  | `void` | Resets the media player and cleans up the device resources. This must be called when the player is no longer needed.| 
| setSubscriptionDuration | `double sec` | `String` message | Set subscription timer in seconds. Default is `0.01` if not using this method.|
| startRecorder | `String uri`, `int sampleRate`, `int numChannels`, t_CODEC codec | `String` uri | Start recording. This will return uri used. |
| stopRecorder | | `String` message | Stop recording.  |
| startPlayer | `Track track`, `bool canSkipForward`, `bool canSkipBackward` | `String` message | Start playing.  |
| stopPlayer | | `String` message | Stop playing. |
| pausePlayer | | `String` message | Pause playing. |
| resumePlayer | | `String` message | Resume playing. |
| seekToPlayer | `int milliSecs` position to goTo | `String` message | Seek audio to selected position in seconds. Parameter should be less than audio duration to correctly placed. |

## Subscriptions
| Subscription | Return | Description |
| :------------ |:---------------:| :---------------:|
| onRecorderStateChanged | `<RecordStatus>` | Able to listen to subscription when recorder starts. |
| onPlayerStateChanged | `<PlayStatus>` | Able to listen to subscription when player starts. |
| onPlaybackStateChanged | `<PlaybackState>` | Able to listen to subscription when player starts.


## Default uri path
When uri path is not set during the `function call` in `startRecorder` or `startPlayer`, they are saved in below path depending on the platform.
+ Default path for android
  * `Library/Caches/sound.aac`.
+ Default path for ios
  * `sound.aac`.


## Codec compatibility
Actually, the following codecs are supported by flutter_sound:

| | AAC  | OGG/Opus  | CAF/Opus | MP3 | OGG/Vorbis | PCM |
| :------------ |:---------------:| :---------------:| :-----| :-----| :-----| :-----|
| iOS encoder| Yes | No | Yes | No | No | No |
| iOS decoder| Yes | No | Yes | Yes | No | Yes |
| Android encoder| Yes | No | No | No | No | No |
| Android decoder| Yes | Yes | No | Yes | Yes | Yes |

This table will eventually be upgrated when more codecs will be added.




## Usage
#### Creating instance.
In your view/page/dialog widget's State class, create an instance of FlutterSound.

```dart
FlutterSound flutterSound = new FlutterSound();
```

#### Initialize the player.
In order to be able to execute all the player methods, you must initialize the player by calling the ```initialize``` method.
You could also pass two functions as arguments of ```initialize```, and they will be triggered when the user tries to skip forward or backward using the buttons in the notification.
Furthermore, your application should display media player controls only when the initialization finished successfully.

```dart
@override
void initState() {
	super.initState();
	flutterSound.initialize()
	.then((_) {
          displayMediaPlayerControls();
        });
}
```

#### Starting recorder with listener.
```dart
Future<String> result = await flutterSound.startRecorder(null);

result.then(path) {
	print('startRecorder: $path');

	_recorderSubscription = flutterSound.onRecorderStateChanged.listen((e) {
	DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
	String txt = DateFormat('mm:ss:SS', 'en_US').format(date);
	});
}
```

If you want to take your own path specify it like below.
```
String path = await flutterSound.startRecorder(Platform.isIOS ? 'ios.aac' : 'android.aac');
```
Actually on iOS, you can choose from two encoders :
- AAC (this is the default)
- CAF/OPUS

To encode with OPUS you do the following :
```dart
await flutterSound.startRecorder(null, codec: t_CODEC.CODEC_CAF_OPUS,)
```
Recently, Apple added a support for encoding with the standard OPUS codec. Unfortunetly, Apple encapsulates its data in its own proprietary envelope : CAF. This is really stupid, this is Apple

On Android the OPUS codec is not yet supported by flutter_sound.

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

#### Create a ```Track``` object
In order to play a sound you must create a ```Track``` object to pass to ```startPlayer```.

The ```Track``` class is provided by the flutter_sound package. Its constructor takes in 1 required argument and 3 optional arguments:
* ```trackPath``` (required): a ```String``` representing the path that points to the audio file to play. This must be provided if ```dataBuffer``` is null, but you cannot provide both;
* ```dataBuffer``` (required): a ```Uint8List```, a buffer that contains an audio file. This must be provided if ```trackPath``` is null, but you cannot provide both;
* ```trackTitle```: the ```String``` to display in the notification as the title of the track;
* ```trackAuthor``` the ```String``` to display in the notification as the name of the author of the track;
* ```albumArtUrl``` a ```String``` representing the URL that points to the image to display in the notification as album art.

```dart
// Create with the path to the audio file
Track track = new Track(
	trackPath: "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3", // An example audio file
        trackTitle: "Track Title",
        trackAuthor: "Track Author",
        albumArtUrl: "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_1MB.png", // An example image
);

// Load a local audio file and get it as a buffer
Uint8List buffer = (await rootBundle.load('samples/audio.mp3'))
    	.buffer
    	.asUint8List();
// Create with the buffer
Track track = new Track(
	dataBuffer: buffer,
        trackTitle: "Track Title",
        trackAuthor: "Track Author",
        albumArtUrl: "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_1MB.png", // An example image
);
```

#### Start player
To start playing a sound you have to call ```startPlayer```. This function takes in 3 arguments:
* a ```Track```, which is the track that the player is going to play;
* a ```boolean```, whether the user can skip forward from this track (and whether the "skip forward" button in the notification should be enabled);
* a ```boolean```, whether the user can skip backbard from this track (and whether the "skip backward" button in the notification should be enabled).

You must wait for the return value to complete before attempting to add any listeners
to ensure that the player has fully initialised.

```dart
Future<String> result = await flutterSound.startPlayer(track, false, false);

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

#### Listen to plyaback state changes

If you subscribe to the ```onPlaybackStateChanged``` ```Stream``` you will be notified whenever the audio player starts playing a sound, is paused or stopped.

```dart
_playbackStateSubscription = flutterSound.onPlaybackStateChanged.listen((newState) {
        print('The new playack state is: $newState');
});
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

If you want to continue using the player after calling ```stopPlayer``` you must call ```releaseMediaPlayer``` and then ```initialize``` again.

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

#### Release the player
You MUST ensure that the player has been released when your widget is detached from the ui.
Overload your widget's ```dispose()``` method to release the player when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the player will be no longer usable.

```dart
@override
void dispose() {
	flutterSound.releaseMediaPlayer();
	super.dispose();
}
```

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
