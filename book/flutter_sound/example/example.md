# Examples/Demo

Flutter Sound comes with several Demo/Examples. All the examples are called from a [driver App](lib/main.dart)

- [Demo](#demo) is a demonstration of what we can do with Flutter Sound. This Demo App is a kind of exerciser which try to implement the major Flutter Sound features. This Demo does not use the Flutter Sound UI Widgets
- [WidgetUIDemo](#widgetuidemo) is an example of what can be done using the Flutter Sound UI Widgets
- [SimplePlayback](#simpleplayback) is a very basic example for Flutter Sound beginners, that shows how to playback a remote file.
- [SimpleRecorder](#simplerecorder) is a very basic example for Flutter Sound beginners, that shows how to record a file and then play it back.
- [RecordToStream](#recordtostream) is an example showing how to record to a live Dart Stream
- [livePlaybackWithBackPressure](#liveplaybackwithbackpressure) is an example showing how to play live data synchronously
- [livePlaybackWithoutBackPressure](#liveplaybackwithoutbackpressure) is an example showing how to play live data asynchronously
- [soundEffect](#soundeffect) is an example showing to play sound effects synchronously
- [streamLoop](#streamLoop) is an example which connect the microphone to a earphone or headset
- [speechToText](#speechtotext) is an example showing how to do Speech to Text recognition.


if Someone update this README.md, please update also the code inside Examples/lib/demo/main.dart and the comment in the header of the demo or example dart file.

--------------------------------------------------------------------------------------------------------------------------------------------------

## [Demo](lib/demo/demo.dart)

<img src="lib/demo/demo.png" width="70%" height="70%" />

This is a Demo of what it is possible to do with Flutter Sound.
The code of this Demo app is not so simple and unfortunately not very clean :-( .

Flutter Sound beginners : you probably should look to [SimplePlayback](#simpleplayback)  and [SimpleRecorder](#simplerecorder) 

The biggest interest of this Demo is that it shows most of the features of Flutter Sound :

- Plays from various media with various codecs
- Records to various media with various codecs
- Pause and Resume control from recording or playback
- Shows how to use a Stream for getting the playback (or recoding) events
- Shows how to specify a callback function when a playback is terminated,
- Shows how to record to a Stream or playback from a stream
- Can show controls on the iOS or Android lock-screen
- ...

It would be really great if someone rewrite this demo soon

--------------------------------------------------------------------------------------------------------------------------------------------------

## [WidgetUIDemo](lib/widgetUI/widgetUI.dart)

<img src="lib/widgetUI/widgetUI.png" width="70%" height="70%" />

This is a Demo of an App which uses the Flutter Sound UI Widgets.

My own feeling is that this Demo is really too much complicated for doing something very simple.
There is too many dependencies and too many sources.

I really hope that someone will write soon another simpler Demo App.

--------------------------------------------------------------------------------------------------------------------------------------------------

## [SimplePlayback](lib/simple_playback/simple_playback.dart)

<img src="lib/simple_playback/simple_playback.png" width="70%" height="70%" />

This is a very simple example for Flutter Sound beginners,
that shows how to play a remote file.

This example is really basic.

--------------------------------------------------------------------------------------------------------------------------------------------------

## [SimpleRecorder](lib/simple_recorder/simple_recorder.dart)

<img src="lib/simple_recorder/simple_recorder.png" width="70%" height="70%" />

This is a very simple example for Flutter Sound beginners,
that shows how to record, and then playback a file.

This example is really basic.

--------------------------------------------------------------------------------------------------------------------------------------------------

## [RecordToStream](lib/recordToStream/recordToStreamExample.dart)

<img src="lib/recordToStream/recordToStreamExample.png" width="40%" height="40%"/>

This is an example showing how to record to a Dart Stream.
It writes all the recorded data from a Stream to a File, which is completely stupid:
if an App wants to record something to a File, it must not use Streams.

The real interest of recording to a Stream is for example to feed a
Speech-to-Text engine, or for processing the Live data in Dart in real time.

--------------------------------------------------------------------------------------------------------------------------------------------------

## [livePlaybackWithoutBackPressure](lib/livePlaybackWithoutBackPressure/livePlaybackWithoutBackPressure.dart)

<img src="lib/livePlaybackWithoutBackPressure/livePlaybackWithoutBackPressure.png" width="40%" height="40%"/>

A very simple example showing how to play Live Data without back pressure.
It feeds a live stream, without waiting that the Futures are completed for each block.
This is simpler than playing buffers synchronously because the App does not need to await that the playback for each block is completed playing another one.

This example get the data from an asset file, which is completely stupid :
if an App wants to play a long asset file he must use [startPlayer()](#startplayer).

Feeding Flutter Sound without back pressure is very simple but you can have two problems :
- If your App is too fast feeding the audio channel, it can have problems with the Stream memory used.
- The App does not have any knowledge of when the provided block is really played.
For example, if it does a "stopPlayer()" it will loose all the buffered data.

This example uses the [FoodEvent](#food) object to resynchronize the output stream before doing a [stopPlayer()](#stopplayer)

-----------------------------------------------------------------------------------------------------------------------------------------------------

## [livePlaybackWithBackPressure](lib/livePlaybackWithBackPressure/livePlaybackWithBackPressure.dart)

<img src="lib/livePlaybackWithBackPressure/livePlaybackWithBackPressure.png" width="40%" height="40%"/>

A very simple example showing how to play Live Data with back pressure.
It feeds a live stream, waiting that the Futures are completed for each block.

This example get the data from an asset file, which is completely stupid :
if an App wants to play an asset file he must use "StartPlayerFromBuffer().

If you do not need any back pressure, you can see another simple example : [LivePlaybackWithoutBackPressure.dart](#liveplaybackwithoutbackpressure).
This other example is a little bit simpler because the App does not need to await the playback for each block before
playing another one.

---------------------------------------------------------------------------------------------------------------------------------------------------

## [soundEffect](lib/soundEffect/soundEffect.dart)

<img src="lib/soundEffect/soundEffect.png" width="40%" height="40%"/>

[startPlayerFromStream](#startplayerfromstream) can be very efficient to play sound effects in real time. For example in a game App.
In this example, the App open the Audio Session and call ```startPlayerFromStream()``` during initialization.
When it want to play a noise, it has just to call the synchronous verb ```feed```. Very fast.

---------------------------------------------------------------------------------------------------------------------------------------------------

## [streamLoop](lib/streamLoop/streamLoop.dart)

<img src="lib/streamLoop/streamLoop.png" width="40%" height="40%"/>

```streamLoop()``` is a very simple example which connect the FlutterSoundRecorder sink
to the FlutterSoundPlayer Stream.
Of course, we do not play to the loudspeaker to avoid a very unpleasant Larsen effect.
this example does not use a new StreamController, but use directely `foodStreamController`
from flutter_sound_player.dart.

---------------------------------------------------------------------------------------------------------------------------------------------------

## [speechtotext](lib/speechToText/speechToTextExample.dart)

<img src="lib/speechToText/speech_to_text_example.png" width="40%" height="40%"/>

This is an example showing how to do Speech To Text.
This is just for FUN :-D, because this example does not use the Flutter Sound library.
But it is included in Flutter Sound examples because it shows how easy it is
to deal with Sounds on Flutter.

This example was provided by @jtkeyva. Thanks to him :-) '''
