# Flutter Sound

<img src="https://raw.githubusercontent.com/dooboolab/flutter_sound/master/Logotype primary.png" width="70%" height="70%" />

<p align="left">
  <a href="https://pub.dartlang.org/packages/flutter_sound"><img alt="pub version" src="https://img.shields.io/pub/v/flutter_sound.svg?style=flat-square"></a>
</p>


This package provides audio recording and playback functionalities for both `android` and `ios` platforms.

Flutter Sound provides both an api, that you can use with your own UI, and  recording and playback widgets.

Flutter Sound is also able to display the standard OS audio player and which allows user to control the audio from their lock screen.

The key classes are:

## Api classes

SoundPlayer - plays audio

SoundRecorder - records audio

Track - play a single track via the OS's audio UI

Album - play a collection of tracks fia the OS's audio UI.

## Wdigets

Playbar - displays an HTML 5 style audio controller

Recorder - displays a recording interface.

Note: there are some limitations on the supported codecs. See the [codec] section below.

![Demo](https://user-images.githubusercontent.com/27461460/77531555-77c9ec00-6ed6-11ea-9813-320f943b08cc.gif)

## Migration Guide

To migrate to `4.0.0`from 3.x.x you must do some minor changes in your configurations files.
Please refer to the **FFmpeg** section below.

## Free Read

[Medium Blog](https://medium.com/@dooboolab/flutter-sound-plugin-audio-recorder-player-e5a455a8beaf)


## Install

For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

Flutter Sound comes in two flavors :
- the **FULL** flavor : flutter_sound
- the **LITE** flavor : flutter_sound_lite

The big difference between the two flavors is that the **LITE** flavor does not have `mobile_ffmpeg` embedded inside.
There is a huge impact on the memory used, but the **LITE** flavor will not be able to do some codecs :
- Playback OGG/OPUS on iOS
- Record OGG_OPUS on iOS

Add `flutter_sound` or `flutter_sound_lite` as a dependency in pubspec.yaml. The actual versions are `^flutter_sound: 4.0.0-beta.3` and `^flutter_sound_lite: 4.0.0-beta.3`
Be aware that **it is not released version**, and probably not good to use it in a released App.
The API is actually not stabilized and will change very soon.
The actual released App is `flutter_sound: ^3.1.10`

```
dependencies:
  flutter:
    sdk: flutter
  flutter_sound: ^4.0.0-beta.3
```
or
```
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite: ^4.0.0-beta.3
```

The Flutter-Sound sources [are here](https://github.com/dooboolab/flutter_sound).

### FFmpeg

flutter_sound makes use of flutter_ffmpeg. In contrary to Flutter Sound Version 3.x.x, in Version 4.0.x your App can be built without any Flutter-FFmpeg dependency.

If you come from Flutter Sound Version 3.x.x, you must remove this dependency from your ```pubspec.yaml```.
You must also delete the line ```ext.flutterFFmpegPackage = 'audio-lts'``` from your ```android/build.gradle```
and the special line ```pod name+'/audio-lts', :path => File.join(symlink, 'ios')``` in your Podfile.
If you do not do that, you will have duplicates modules during your App building.

```flutter_ffmpeg audio-lts``` is now embedding inside flutter_sound. If your App needs to use FFmpeg, you must use the embedded version inside flutter_sound
instead of adding a new dependency in your pubspec.yaml.


## Post Installation

- On _iOS_ you need to add a usage description to `info.plist`:

  ```xml
  <key>NSMicrophoneUsageDescription</key>
    <string>This sample uses the microphone to record your speech and convert it to text.</string>
  <key>UIBackgroundModes</key>
  <array>
  	<string>audio</string>
  </array>
  ```

- On _Android_ you need to add a permission to `AndroidManifest.xml`:

  ```xml
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  ```


# SoundPlayer
The SoundPlayer class is primarly design to play back audio without display any UI.

If you need a UI to allow your user to control playback you have three options:

1) use the showOSUI parameter on the SoundPlayer constructor. 
This will display the OS specific Audio player.

2) Use Flutter Sound's Playbar which provide a HTML5 like audio player UI

3) Use the SoundPlayer's apis to roll your own widget. You can start with the Playbar code as an example of how to do this.

The API is documented at [pub.dev](https://pub.dev/documentation/flutter_sound/latest/)

## Play audio from an asset

To play audio from a project asset copy the file to your assets directory in the root of your dart project.

```assets/sample.acc```

Add the asset to the 'assets' section of your pubspec.yaml

```
flutter:
  assets:
  - sample.acc
```

Now play the file.

```dart
var player = SoundPlayer.fromPath('sample.aac');
player.onFinish = player.release;
player.play();
```

You must be certain to release the player once you have finished playing the audio.
You can reuse a `SoundPlayer` as many times as you want as long as you call `SoundPlayer.release()` once you are done with it.

SoundPlayer uses the passed filename extension to determine the correct codec to play. If you need to play a file with an extension that doesn't match one of the known file extensions then you MUST pass in the codec.

See the [codec](https://pub.dev/documentation/flutter_sound/latest/codec/codec-library.html) documentation
for details on the supported codecs.

```dart
var player = SoundPlayer.fromPath('sample.blit', codec: Codec.mp3);
player.onFinish = player.release;
player.play();
```

## Play audio from an external URL

You can play a remote audio file by passing a URL to SoundPlayer.

See the [codec](https://pub.dev/documentation/flutter_sound/latest/codec/codec-library.html) documentation
for details on the supported codecs.

```dart
var player = SoundPlayer.fromPath('https://some audio file'
	, codec:Codec.mp3);
player.onFinish = player.release;
player.play();
```

## Play audio from an in memory buffer 
When playing a audio file from a buffer you MUST provide the codec.


See the [codec](https://pub.dev/documentation/flutter_sound/latest/codec/codec-library.html) documentation
for details on the supported codecs.

```dart
Uint8List buffer = ....
var player = SoundPlayer.fromBuffer(buffer, codec:Codec.mp3);
player.onFinish = player.release;
player.play();
```

## Playing a Track via the OS's UI

If you want to play the audio and have the OS Audio player displayed so the user can control the playback then use:

```dart
var player = Track.fromPath('sample.aac');
player.trackTitle = 'Reckless';
player.trackAuthor = 'Flutter Sound';
player.albumArtUrl = 'http://some image url';
player.onFinish = player.release;
player.play();
```
Note how I snuck in the track details. If provided they will be displayed on the OS Audio Player.

## Playing an album via the OS's UI

If you want to play a collection of tracks via the OS's UI then you can create an Album with a static set of Tracks or a virtual set of Tracks.

### Play album with static set of Tracks

```dart
var album = Album.fromTracks([
	Track('sample.acc'),
	Track('buzz.mp3'),
]);

album.play();
```

### Play album with a virtual set of Tracks

Virtual tracks allow you to create an album of infinite size which
could be useful if you are pulling audio from an external source.

If you create a virtual album you MUST implement the onSkipForward 
and onSkipBackwards methods to supply the album with Tracks on demand.

```dart
 var album = Album.virtual();
album.onSkipForward = (int currentTrackIndex, Track current) 
		=> Track('http://random/xxxx');
album.onSkipBackwards = (int currentTrackIndex, Track current) 
		=> Track('http://random/xxxx');

album.play();

```

## Monitoring progress
If you need to know when the playback finishes then hook the onFinish callback:

```dart
var player = SoundPlayer.fromPath('sample.aac');
player.onFinished = () => print('playback finished');
player.play();
```
There are a number of other callbacks you can use to receive notifications as the playback proceeds such as:
* onStarted
* onStopped
* onPaused
* onResumed


## Track playback position
If you are building your own widget you might want to display a progress bar that displays the current playback position.

The easiest way to do this is via the Playbar but if you want to write your own then you will want to user the `dispositionStream` with a StreamBuilder.

```dart
class MyWidgetState
{
	void initState()
	{
		super.initState();
		var player = SoundPlayer.fromPath('sample.aac');
	}

	 Widget build() {
    	 return Row(children:
		 	[Button('Play' onTap: onPlay)
		 		, StreamBuilder<PlaybackDisposition>(
					stream: player.dispositionStream,
					initialData: PlaybackDisposition.zero(),
					builder: (context, snapshot) {
					var disposition = snapshot.data;
					return Slider(
						max: disposition.duration.inMilliseconds.toDouble(),
						value: disposition.position.inMilliseconds.toDouble(),
						onChanged: (value) =>
							player._seek(Duration(milliseconds: value.toInt())),
					);
            		}
				))
			]);
      },
    ));
  
  voi onPlay()
  {
	  player.play();
  }
}
```  

## Codec compatibility

The following codecs are supported by flutter_sound:

|                 | AAC | OGG/Opus | CAF/Opus | MP3 | OGG/Vorbis | PCM |
| :-------------- | :-: | :------: | :------- | :-- | :--------- | :-- |
| iOS encoder     | Yes |   Yes    | Yes      | No  | No         | Yes |
| iOS decoder     | Yes |   Yes    | Yes      | Yes | No         | Yes |
| Android encoder | Yes |    No    | No       | No  | No         | No  |
| Android decoder | Yes |   Yes    | No       | Yes | Yes        | Yes |

This table will be updated as codecs are added.

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

## FlutterSoundPlayer Usage

#### Creating instance.

In your view/page/dialog widget's State class, create an instance of FlutterSoundPlayer.
Before acessing the FlutterSoundPlayer API, you must initialize it with initialize().
When finished with this FlutterSoundPlayer instance, you must release it with release().

```dart
FlutterSoundPlayer flutterSoundPlayer = new FlutterSoundPlayer().initialize();

...
...

flutterSoundPlayer.release();
```

#### Start player

- To start playback of a record from a URL call startPlayer.
- To start playback of a record from a memory buffer call startPlayerFromBuffer

You can use both `startPlayer` or `startPlayerFromBuffer` to play a sound. The former takes in a URI that points to the file to play, while the latter takes in a buffer containing the file to play and the codec to decode that buffer.

Those two functions can have an optional parameter `whenFinished:()` for specifying what to do when the playback will be finished.

```dart
// An example audio file
final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";

String result = await flutterSoundPlayer.startPlayer
	(
		fileUri,
		whenFinished: ()
		{
			 print( 'I hope you enjoyed listening to this song' );
		},
	);
```

```dart
// Load a local audio file and get it as a buffer
Uint8List buffer = (await rootBundle.load('samples/audio.mp3'))
    	.buffer
    	.asUint8List();

Future<String> result = await flutterSoundPlayer.startPlayerFromBuffer
	(
		buffer,
		whenFinished: ()
		{
			 print( 'I hope you enjoyed listening to this song' );
		},
	);

```

You must wait for the return value to complete before attempting to add any listeners
to ensure that the player has fully initialised.

```dart
Directory tempDir = await getTemporaryDirectory();
File fin = await File ('${tempDir.path}/flutter_sound-tmp.aac');
Future<String> result = await flutterSoundPlayer.startPlayer(fin.path);

result.then(path) {
	print('startPlayer: $path');

	_playerSubscription = flutterSoundPlayer.onPlayerStateChanged.listen((e) {
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

#### Stop player

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

#### Pause player

```dart
Future<String> result = await flutterSoundPlayer.pausePlayer();
```

#### Resume player

```dart
Future<String> result = await flutterSoundPlayer.resumePlayer();
```

#### iosSetCategory(), androidAudioFocusRequest() and setActive() - (optional)

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

#### Seek player

To seek to a new location the player must already be playing.

```dart
String Future<result> = await flutterSoundPlayer.seekToPlayer(miliSecs);
```

#### Setting subscription duration (Optional). 0.010 is default value when not set.

```dart
/// 0.01 is default
flutterSoundPlayer.setSubscriptionDuration(0.01);
```

#### Setting volume.

```dart
/// 1.0 is default
/// Currently, volume can be changed when player is running. Try manage this right after player starts.
String path = await flutterSoundPlayer.startPlayer(fileUri);
await flutterSoundPlayer.setVolume(0.1);
```

#### Release the player

You MUST ensure that the player has been released when your widget is detached from the ui.
Overload your widget's `dispose()` method to release the player when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the player will be no longer usable.

```dart
@override
void dispose() {
	flutterSoundPlayer.release();
	super.dispose();
}
```

## TrackPlayer

TrackPlayer is a new flutter_sound module which is able to show controls on the lock screen.
Using TrackPlayer is very simple : just use the TrackPlayer constructor instead of the regular FlutterSoundPlayer.

```dart
trackPlayer = TrackPlayer();
```

You call `startPlayerFromTrack` to play a sound. This function takes in 1 required argument and 3 optional arguments:

- a `Track`, which is the track that the player is going to play;
- `whenFinished:()` : A call back function for specifying what to do when the song is finished
- `onSkipBackward:()`, A call back function for specifying what to do when the user press the skip-backward button on the lock screen
- `onSkipForward:()`, A call back function for specifying what to do when the user press the skip-forward button on the lock screen

```dart
path = await trackPlayer.startPlayerFromTrack
(
	track,
	whenFinished: ( )
	{
		print( 'I hope you enjoyed listening to this song' );
	},

	onSkipBackward: ( )
	{
		print( 'Skip backward' );
		stopPlayer( );
		startPlayer( );
	},
	onSkipForward: ( )
	{
		print( 'Skip forward' );
		stopPlayer( );
		startPlayer( );
	},

);

```

#### Create a `Track` object

In order to play a sound when you initialized the player with the audio player features, you must create a `Track` object to pass to `startPlayerFromTrack`.

The `Track` class is provided by the flutter_sound package. Its constructor takes in 1 required argument and 3 optional arguments:

- `trackPath` (required): a `String` representing the path that points to the audio file to play. This must be provided if `dataBuffer` is null, but you cannot provide both;
- `dataBuffer` (required): a `Uint8List`, a buffer that contains an audio file. This must be provided if `trackPath` is null, but you cannot provide both;
- `trackTitle`: the `String` to display in the notification as the title of the track;
- `trackAuthor` the `String` to display in the notification as the name of the author of the track;
- `albumArtUrl` a `String` representing the URL that points to the image to display in the notification as album art.
- `albumArtFile`  a `String` representing a local file that points to the image to display in the notification as album art.
- or `albumArtAsset` : the name of an asset to show in the nofitication

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

You can specify just one field for the Album Art to display on the lock screen. Either :
- albumArtUrl
- albumArtFile
- albumArtFile

If no Album Art field is specified, Flutter Sound will try to display the App icon.

## Informations on a record

There are two utilities functions that you can use to have informations on a file.

- FlutterSoundHelper.FFmpegGetMediaInformation(_<A_file_path>_);
- FlutterSoundHelper.duration(_<A_file_path>_)

The informations got with FFmpegGetMediaInformation() are [documented here](https://pub.dev/packages/flutter_ffmpeg).
The integer returned by flutterSound.duration() is an estimation of the number of milli-seconds for the given record.

```
int duration = await flutterSoundHelper.duration( this._path[_codec.index] );
Map<dynamic, dynamic> info = await flutterSoundHelper.FFmpegGetMediaInformation( uri );
```

### TODO

- [x] Seeking example in `Example` project
- [x] Volume Control
- [x] Sync timing for recorder callback handler
- [ ] Record PCM on Android
- [ ] Record OPUS on Android
- [ ] Streaming records to speech to text

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
