# Flutter Sound

<img src="https://raw.githubusercontent.com/dooboolab/flutter_sound/master/Logotype primary.png" width="70%" height="70%" />

<p align="left">
  <a href="https://pub.dartlang.org/packages/flutter_sound"><img alt="pub version" src="https://img.shields.io/pub/v/flutter_sound.svg?style=flat-square"></a>
</p>

This package provides audio recording and playback functionalities for both `android` and `ios` platforms

Flutter Sound provides both an api and widgets for recording and playback.

We support playback from:
Assets
Files
URL
Native Streams (with sync).

To control recording and playback: 
* Play audio without any UI
* Play audio using the built in SoundPlayerUI
* Play audio using the OSs' Media Player
* Roll your own UI utilising the Flutter Sound api.
* Record audio without any UI
* Record audio using the builtin SoundRecorderUI
* Roll your own Recording UI utilising the Flutter Sound api.


The key classes are:

## Api classes

QuickPlay - instantly play audio either using the OSs' audio UI or headless.

Track - Defines a track including artist and a link to the media.

Album - play a collection of tracks via the OSs' audio UI.

TrackPlayer - provides migration path from 3.0 TrackPlayer

SoundPlayer - provides migration path from 3.0 SoundPlayer

AudioPlayer - api for detailed control over your audio streams. You can choose to have the session attached to the OSs' audio UI or not.

SoundRecorder -  api to records audio.


## Wdigets

SoundPlayerUI - displays an HTML 5 style audio controller widget.

SoundRecorderUI - displays a recording widget.

RecorderPlaybackController - pairs a SoundPlayerUI and SoundRecorderUI to provide a co-ordinated recording/playback UI.

Note: there are some limitations on the supported codecs. See the [codec] section below.

![Demo](https://user-images.githubusercontent.com/27461460/77531555-77c9ec00-6ed6-11ea-9813-320f943b08cc.gif)

# Migration Guide

## `3.x.x` to `4.0.0`.

To migrate to  you must do some minor changes in your configurations files.
Please refer to the **FFmpeg** section below.

## `4.0.0` to `5.0.0`
The Flutter Sound team have undertaken a major re-architecture of the api in order to provide a solid and flexible foundation moving forward.

The aims of 5.0.0 were:

* Make the api simplier to use.
* Improve documentation
* Deliver 'out of the box' widgets for recording and playback.
* Resolve architecual issues which have caused a number of hard to resolve race conditions resulting in crashes.
* Hide internal apis from the public api.
* Provide a consistent error handling mechanisim via exceptions.
* Remove duplicated code.
* Bring the code in line with Google's recommended best practices.


### Players

In `5.0.0` the `TrackPlayer` and `FlutterSoundPlayer` has been merged into a single class `AudioPlayer`.

`AudioPlayer` now has two constructors:

Code that previously used `TrackPlayer` should now call the `AudioPlayer.withUI()` constructor.

Code that used the old `FlutterSoundPlayer` should now call the `AudioPlayer.noUI()` constructor.

The equivalent method names on the `AudioPlayer` class have also been shortend.

Example changes:

`FlutterSoundPlayer.startPlayer()` -> `AudioPlayer.play()`
`FlutterSoundPlayer.pausePlayer()` -> `AudioPlayer.pause()`
`FlutterSoundPlayer.stopPlayer()` ->  `AudioPlayer.stop()`

The new `play` methods replaces both `startPlayer(uri)` and `startPlayerFromBuffer()` and can
now take a `Track`.

### Track
A Track now holds track information as well as the audio media.

The Track class has two constructors:
`Track.fromPath` and `Track.fromBuffer`.

To play a track from a path use:
```dart
var player AudioPlayer.withUI();
player.onFinish = () => player.release();
player.seekTo(Duration(seconds: 5)); // yes, you can call seek before play.
player.play(Track.fromPath(uri));
```

To play a track from a buffer use:

```dart
var player AudioPlayer.withUI();
player.onFinish = () => player.release();
player.seekTo(Duration(seconds: 5)); 
player.play(Track.fromBuffer(buffer));
```

The Track class constructors have been simplified to take just the path (or buffer) and a codec.

The Track details are now set via properties:

```dart
var track = Track.fromPath('path to media');
track.title = 'Quarantine Jig';
track.author = 'The Jiggy Kids';
var player = AudioPlayer.withUI();
player.onFinish = () => player.release();
player.play(track);
```

### Monitoring

Flutter sounds now uses streams to allow you to monitor both recording and playback progress.

You can now use a StreamBuilder which will greatly simplify the construction of UI components (or you can use one of the new Flutter Sound UI widgets).

#### AudioPlayer

In the AudioPlayer the original `SoundPlayer` subscription model is now been unified into a single stream via:

```dart 
var Stream<PlaybackDisposition> = AudioPlayer.noUI().dispositionStream(interval);
```

The result is a stream of `PlaybackDisposition`s which includes both the audio's duration (length) and current position.

The following methods have been replaced by `dispositionStream`:
* setSubscriptionDuration
* setPlayerCallback

#### SoundRecorder
The `SoundRecorder` subscription model is now been unified into a single stream via:

```dart 
var Stream<RecordingDisposition> 
  = SoundRecorder(). dispositionStream(interval);
```

The `RecordingDisposition` contains both the duration of the recording and the decibels (previously DbPeak).

```dart
class RecordingDisposition {
  final Duration duration;

  final double decibels;
```  


### Types
Types and enums now consistently use camelCase.

e.g. 
`t_PLAYER_STATE.IS_STOPPED -> PlayerState.isStopped`

### New classes
`5.0.0` introduces a number of new convenience classes:

`QuickPlay` plays a single audio file immediatley (there is no `play` method).

This is ideal for small audio files and has the benefit that it frees its own resources.

```dart
QuickPlay.fromPath('path to file', volume: 0.5);
QuickPlay.fromTrack(Track.fromPath('path to file'), volume: 0.5);
```

`Album` allows you to create an album of Track (statically or dynamically) and play them sequentiall via the OSs' UI.




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
And will not be able to offer some helping functions, like `FlutterSoundHelper.FFmpegGetMediaInformation()` or `FlutterSoundHelper.duration()`

Add `flutter_sound` or `flutter_sound_lite` as a dependency in pubspec.yaml. The actual versions are `^flutter_sound: 4.0.0` and `^flutter_sound_lite: 4.0.0`

```
dependencies:
  flutter:
    sdk: flutter
  flutter_sound: ^4.0.0
```
or
```
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite: ^4.0.0
```

The Flutter-Sound sources [are here](https://github.com/dooboolab/flutter_sound).

### FFmpeg

flutter_sound makes use of flutter_ffmpeg. In contrary to Flutter Sound Version 3.x.x, in Version 4.0.x your App can be built without any Flutter-FFmpeg dependency.

If you come from Flutter Sound Version 3.x.x, you must remove this dependency from your ```pubspec.yaml```.
You must also delete the line ```ext.flutterFFmpegPackage = 'audio-lts'``` from your ```android/build.gradle```
and the special line ```pod name+'/audio-lts', :path => File.join(symlink, 'ios')``` in your Podfile.
If you do not do that, you will have duplicates modules during your App building.

```flutter_ffmpeg audio-lts``` is now embedding inside flutter_sound. If your App needs to use FFmpeg, you must use the embedded version inside flutter_sound instead of adding a new dependency in your pubspec.yaml.


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


# Using Flutter Sound

## QuickPlay
The QuickPlay class provides the simplest means of playing audio.

If you just want to play an audio file then this is the place to start.

By default the QuickPlay doesn't display any UI, it simply plays the audio until it completes.

You have no control over the audio once it starts but you don't have to do any cleanup once it completes.

```dart
QuickPlay.fromPath('path to file');
```

QuickPlay provides a number of constructors that allow you play audio from different sources.

You set the volume and display the OSs' audio player if you choose.

```dart
QuickPlay.fromBuffer(databuffer, codec: Codec.aac, volume: 1.0, withUI: true);
```

## Displaying a UI

If you need a UI to allow your user to control playback then you have three options:

1) Use `AudioPlayer.withUI()` 
This will display the OSs' audio player allowing the user to control playback.

2) Use Flutter Sound's SoundPlayerUI widget which provide a HTML5 like audio player.

3) Directly use `AudioPlayer.noUI()` to roll your own widget. You can start with the SoundPlayerUI code as an example of how to do this.

The API is documented in detail at [pub.dev](https://pub.dev/documentation/flutter_sound/latest/)

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
/// play the audio with no controls
QuickPlay.fromPath('beep.acc');

/// If you need to control/monitor the playback
var player = AudioPlayer.noUI();

// If you stop the playback onFinish will not be called so you
// must call release via another method.
player.onFinish = player.release();
player.play(Track.fromPath('sample.aac'));
```

CRITICAL: 

You must be certain to release the player once you have finished playing the audio.

You can reuse a `AudioPlayer` as many times as you want as long as you call `AudioPlayer.release()` once you are done with it.

Track.fromPath uses the passed filename extension to determine the correct codec to play. If you need to play a file with an extension that doesn't match one of the known file extensions then you MUST pass in the codec.

See the [codec](https://pub.dev/documentation/flutter_sound/latest/codec/codec-library.html) documentation
for details on the supported codecs.

## Specify a codec

If you audio file doesn't have an appropriate file extension then you can explicitly pass a codec.

```dart
var player = AudioPlayer.noUI();
player.onFinish = player.release;
player.play(Track.fromPath('sample.blit', codec: Codec.mp3));
```

## Play audio from an external URL

You can play a remote audio file by passing a URL to QuickPlay.

See the [codec](https://pub.dev/documentation/flutter_sound/latest/codec/codec-library.html) documentation
for details on the supported codecs.

```dart

var player = AudioPlayer.noUI();
player.onFinish = player.release;
player.play(Track.fromPath('https://some audio file', codec: Codec.mp3););
```

## Play audio from an in memory buffer 
When playing a audio file from a buffer you MUST provide the codec.


See the [codec](https://pub.dev/documentation/flutter_sound/latest/codec/codec-library.html) documentation
for details on the supported codecs.

```dart
Uint8List buffer = ....
var player = AudioPlayer.noUI();
player.onFinish = player.release;
player.onStop = player.release;
player.play(Track.fromBuffer(buffer, codec: Codec.mp3));
```

## Play audio allowing the user to control playback via OSs' UI

AudioPlayer can display the OSs' Audio player UI allowing the user to control playback.

```dart
var player = AudioPlayer.withUI();
player.onFinish = player.release;
player.play(Track.fromPath('sample.blit', codec: Codec.mp3));
```

## Control the OSs' UI

The OSs' media player has three buttons, skip forward, skip backwards and pause.
By default the skip buttons are disabled and the pause button enabled.

You can modify the the state of these buttons with the `SoundPlaye.withUI` constructor.

```dart
var player = AudioPlayer.withUI(canPause:true, canSkipBackward:false
	, canSkipForward: true);
player.onFinish = player.release;
player.play(Track.fromPath('sample.blit', codec: Codec.mp3));
```

## Display artist details
You can also have the OSs' audio player display artist details by 
using a `Track`.

```dart
var track = Track.fromPath('sample.aac');
track.title = 'Reckless';
track.author = 'Flutter Sound';
track.albumArtUrl = 'http://some image url';

var player = AudioPlayer.withUI()
track.onFinish = track.release;
player.fromTrack(track);
```
The artist, author and album art will be displayed on the OSs' Audio Player.

# Albums
Flutter Sound supports the concept of Albums which are, as you would expect, a collection of `Track`s which can be played in order.

The `Album` uses the OSs Media Player to display the tracks as they are played. 

A user can use the skip back, forward and pause buttons to navigate the album.

## Playing an Album

If you want to play a collection of tracks then you can create an Album with a static set of Tracks or a virtual set of Tracks.

### Play album with static set of Tracks

```dart
var album = Album.fromTracks([
	Track.fromPath('sample.acc'),
	Track.fromPath('http://fqdn/sample.mp3'),
]);
album.onFinish = album.release;
album.play();
```
By default an Ablum displays the OSs' audio UI.
You can suppress the UI via by passing in AudioPlayer.noUI() to the Album.


```dart
var album = Album.fromTracks([
	Track.fromPath('sample.acc'),
	Track.fromPath('http://fqdn/sample.mp3'),
]
, session: AudioPlayer.noUI());
album.onFinish = album.release;
album.play();
```

### Play album with a virtual set of Tracks

Virtual tracks allow you to create an album of infinite size which
could be useful if you are pulling audio from an external source.

If you create a virtual album you MUST implement the `onSkipForward` 
, `onSkipBackwards` and `onFirstTrack` methods to supply the album with Tracks on demand.

```dart
 var album = Album.virtual();
 album.onFirstTrack = (int currentTrackIndex, Track current) 
		=> Track('http://random/xxxx');
album.onSkipForward = (int currentTrackIndex, Track current) 
		=> Track('http://random/xxxx');
album.onSkipBackwards = (int currentTrackIndex, Track current) 
		=> Track('http://random/xxxx');
album.onFinish = album.release;		
album.play();

```

## Controlling Playback
An AudioPlayer provides fined grained control over how the audio is played as well as been able to monitor playback and respond to user events.

Importantly `AudioPlayer` also allows you to play multiple audio files using the same session. 

Maintaining the same session is important if you are using the OSs' audio UI for user control. 
If you don't use a single `AudioPlayer` then the user will experience flicker between tracks as the OSs' audio player is destroyed and recreated between each track.

The `Album` class provides an easy to use method of utilising a single session without the complications of an `AudioPlayer`.


```dart
var player = AudioPlayer.withUI();

var track = Track.fromPath('sample.aac');
track.title = 'Corona Virus Rock';
player.onStarted => print('started');
player.onStopped => print('stopped');
player.onPause => print('paused');
player.onResume => print('resumed');
player.onFinished => print('finished');
player.play(track);

...

player.release();

```


## Monitor playback position
If you are building your own widget you might want to display a progress bar that displays the current playback position.

The easiest way to do this is via the SoundPlayerUI widget but if you want to write your own then you will want to use the `dispositionStream` with a StreamBuilder.

To use a `dispositionStream` you need to create an `AudioPlayer`.

```dart
class MyWidgetState
{
	/// use .noUI() as you are going to build your own UI.
	var player = AudioPlayer().noUI();

	void initState()
	{
		super.initState();
		
	}

	void dispose()
	{
		player.release();
		super.dispose();
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
  
  /// you would wire this to a button
  void onPlay()
  {
	  player.play(Track.fromPath('sample.aac'));
  }

   /// you would wire this to a pause button
  void onPause()
  {
	  player.pause();
  }

   /// you would wire this to a button
  void onResume()
  {
	  player.resume();
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

## SoundRecorder Usage
The `SoundRecorder` class provides an api for recording audio.

The `SoundRecorder` does not have a UI so you must either build your own or you can use Flutter Sound's `SoundRecorderUI` widget.


#### Recording

When you have finished with your `SoundRecorder` you MUST call `SoundRecorder.release()`.

```dart
var track = Track.fromPath('fred.aac');
var recorder = SoundRecorder();
recorder.onStopped = () {
	recorder.release();
	// quick play will release the track resources!
 	QuickPlay.fromTrack(track);
});
recorder.record(track);
```
### recording to a temporary file

SoundRecoder can also create a temporary file to record into. After recording completes you can access the temporary file
via `SoundRecorder.path`.

Deleting the temporary file is your responsiblity!

```dart
SoundRecorder recorder = SoundRecorder.toTempPath();

recorder.onStopped = () {
	recorder.release();
	/// recorder.path contains the path of the temp file
	var player = QuickPlay.fromPath(recorder.path)
	player.onFinished = () { 
		player.release();
		File(recorder.path).deleteSync();
	});
	player.play();
});

recorder.start();

```

SoundRecorder requests the necessary permissions (microphone and storage) when you call `SoundRecorder.start()`.

If you want to control the permissions yourself you need to set `SoundRecorder.requestPermission = false`.


```dart
var recorder = SoundRecorder.tempPath();
recorder.requestPermission = false;
recorder.start();
```

### Listen to duration and dbLevel updates

SoundRecorder provides a stream that you can listen to to get live updates as the recording progresses.

The stream of `RecordingDisposition` events contain the duration of the recording and the instantanous dB level.

The dbLevel is in the range of 0-120dB.

```dart
SoundRecorder recorder = SoundRecorder.toPath('path to store recording', codec: Codec.aac,);
recorder.dispositionStream().listen((disposition) {
	Duration duration = dispostion.duration;
	double dbLevel = disposition.dbLevel;
	print('The recording has grown to: $duration');
	print('At this very moment the the audio is $dbLevel loud');
});

recorder.onStopped(() {
	recorder.release()
	/// Now play the recording back.
	QuickPlay.fromPath(recorder.path).play();
});

recorder.start();
```

### Supported Codecs

Currently a limited set of Codecs are supported by `SoundRecorder`.

#### iOS

- AAC (this is the default)
- CAF/OPUS
- OGG/OPUS
- PCM

#### Android

- AAC (this is the default)


For example, to encode with OPUS you do the following :

```dart
var recorder = SoundRecorder.toTemp(codec: Codec.opus);
recorder.start();
```

#### Stop recorder
You can programatically stop the recorder by calling  `stop()`.

```dart
var recorder = SoundRecorder.toTemp(codec: Codec.opus);
recorder.start();

/// some widget event
void onTap()
{
	recorder.stop();
}
```

You MUST ensure that the recorder has been stopped when your widget is detached from the ui.
Overload your widget's dispose() method to stop the recorder when your widget is disposed.

```dart
@override
void dispose() {
	recorder.release();
	super.dispose();
}
```

#### Pause recorder

On Android this API verb needs al least SDK-24.

```dart
await recorder.pause();
```

#### Resume recorder

On Android this API verb needs al least SDK-24.

```dart
await recoder.resume();
```

## SoundRecorderUI
Flutter Sounds contains a standard SoundRecorderUI widget that allows you to record.

```dart

void build(BuildContext build)
{
	Track track = Track.fromPath('path to file to record into');
	SoundRecorderUI recorderUI =  SoundRecorderUI(track.
		onStart:  () => onStart(),
		onStop:  () => onStop());

	return recorderUI;
}

```

#### iosSetCategory(), androidFocusRequest(), requestFocus() and abandonFocus()  - (optional)

Those three functions are optional. If you do not control the audio focus with the function `requestFocus()`, flutter_sound will request the audio focus each time you call 'play()' on either the `AudioPlayer` or `QuickPlay`.
The focus will be automatically release it when playback is finished or when you call the `stop()` method on the `AudioPlayer`.


## TODO this section needs reviewing as I don't think it is correct.
## The android documentation stats that requestFocus should be called on the play() callback which we do by default.
Before controlling the focus with `requestFocs()` you must call `iosSetCategory()` on iOS or `androidAudioFocusRequest()` on Android. `requesFocus()` and `androidAudioFocusRequest()` are useful if you want to `hush others` (in android terminology duck others).
Those functions are probably called just once when the app starts.
After calling this function, the caller is calling `requestFocus()/abandonFocus() as required`.


You can refer to [iOS documentation](https://developer.apple.com/documentation/avfoundation/avSoundPlayer/1771734-setcategory) to understand the parameters needed for `iosSetCategory()` and to the [Android documentation](https://developer.android.com/reference/android/media/AudioFocusRequest) to understand the parameter needed for `androidAudioFocusRequest()`.

Remark : those three functions do NOT work on Android before SDK 26.

```dart
if (_hushOthers)
{
	if (Platform.isIOS)
		await player.iosSetCategory( t_IOS_SESSION_CATEGORY.PLAY_AND_RECORD, t_IOS_SESSION_MODE.DEFAULT, IOS_DUCK_OTHERS |  IOS_DEFAULT_TO_SPEAKER );
	else if (Platform.isAndroid)
		await player.androidAudioFocusRequest( ANDROID_AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK );
} else
{
	if (Platform.isIOS)
		await player.iosSetCategory( t_IOS_SESSION_CATEGORY.PLAY_AND_RECORD, t_IOS_SESSION_MODE.DEFAULT, IOS_DEFAULT_TO_SPEAKER );
	else if (Platform.isAndroid)
		await player.androidAudioFocusRequest( ANDROID_AUDIOFOCUS_GAIN );
}
...
...
player.requestFocus(); // Get the audio focus
player.play(track);
// wait
player.play(track2);
player.abandonFocus(); // Release the audio focus
```

#### Seek player

When using the `AudioPlayer` you can seek to a specific position in the audio stream before or whilst playing the audio.

```dart
await player.seekTo(Duration(seconds: 1));
```


#### Setting volume.

```dart
/// 1.0 is default
/// Currently, volume can be changed when the player is running. 
/// You must ensure that the play method has completed before calling
/// setVolume.
var player = AudioPlayer.noUI();
await player.play(fileUri);
player.setVolume(0.1);
```

#### Release the player

You MUST ensure that the player has been released when your widget is detached from the ui.
Overload your widget's `dispose()` method to release the player when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the player will be no longer usable.

```dart
@override
void dispose() {
	player.release();
	super.dispose();
}
```

## TrackPlayer

TrackPlayer is a new flutter_sound module which is able to show controls on the lock screen.
Using TrackPlayer is very simple : just use the TrackPlayer constructor instead of the regular FlutterQuickPlay.

```dart
trackPlayer = TrackPlayer();
```

You call `startPlayerFromTrack` to play a sound. This function takes in 1 required argument and 4 optional arguments:

- a `Track`, which is the track that the player is going to play;
- `whenFinished:()` : A call back function for specifying what to do when the song is finished
- `onPaused: (boolean)` : A call back function for specifying what to do when the user press the `pause/resume` button on the lock screen.
- `onSkipBackward:()`, A call back function for specifying what to do when the user press the skip-backward button on the lock screen
- `onSkipForward:()`, A call back function for specifying what to do when the user press the skip-forward button on the lock screen

If `onSkipBackward:()` is not specified then the button is not shown on the lock screen.
If `onSkipForward:()` is not specified, then the  button is not shown on the lock screen.
If `onPaused: (boolean)` is not specified, then flutter_sound will handle itself the pause/resume function.
There is actually no way to hide the pause button on the lock screen.

If `onPaused: (boolean)` is specified, then flutter_sound will not handle itself the pause/resume function and it will be the App responsability to handle correctly this function. The boolean argument is `true` if the playback is playing (and probably must me paused). The boolean argument is `false` if the playback is in 'pause' state (and probably must be resumed).

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
        onPaused: ( boolean mustBePaused)
        {
                if( mustBePaused )
                        trackPlayer.pause();
                else
                        trackPlayer.resume();
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
