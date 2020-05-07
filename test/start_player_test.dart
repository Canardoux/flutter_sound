// import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
// import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // final log = <MethodCall>[];

  QuickPlay.fromPath('example/asset/samples/sample.acc');

// SoundRecorder recorder = SoundRecorder.toPath('path to store recording');
// recorder.start();

// recorder.onStopped = () => recorder.release();
//   var player2 = QuickPlay.fromPath(recorder.path)
// 	player2.onFinished = () => player2.release();
// 	player2.play();

//   var player = QuickPlay.fromPath(recorder.path)
// 	..onFinished => player.release();
// 	..play();
/*
  var isinitialized = false;
  var isReleased = false;
  double subscriptionDuration;
  double volume;
  int seekPosition;

  setUpAll(() async {
    MethodChannel('audio_recorder')
        .setMockMethodCallHandler((methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'initializeMediaPlayer':
          isinitialized = true;
          return "Flauto Player Initialized";

        case 'releaseMediaPlayer':
          isReleased = true;
          break;

        case 'isDecoderSupported':
          return true;
        case 'startPlayer':
          return true;
        case 'startPlayerFromBuffer':
          return true;
        case 'stopPlayer':
          break;

        case "pausePlayer":
          break;

        case "resumePlayer":
          if (!isinitialized) {
            // result.error(
            //     "ERR_PLAYER_IS_NULL", "resumePlayer", ERR_PLAYER_IS_NULL);
          }
          break;

        case "seekToPlayer":
          seekPosition = int.parse(methodCall.arguments('sec') as String);

          break;

        case "setVolume":
          volume = double.parse(methodCall.arguments('volume') as String);

          break;

        case "setSubscriptionDuration":
          subscriptionDuration =
              double.parse(methodCall.arguments('sec') as String);

          break;

        case "androidAudioFocusRequest":
          return true;

        case "setActive":
          return true;
      }
      return null;
    });
  });

*/
  // test('startPlayer', () {
  //   var player = QuickPlay();

  //   player.startPlayer('example/asset/samples/sample.acc');
  // }, skip: true);

  // test('startPlayer - whenFinished', () {
  //   var player = QuickPlay();

  //   try {
  //     player.startPlayer('example/asset/samples/sample.acc',
  //         whenFinished: () => Log.d('finished'));
  //   } catch (e) {
  //     Log.d(e);
  //   }
  // }, skip: false);
}
