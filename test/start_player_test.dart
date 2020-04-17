import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];

  var player = SoundPlayer();
  player.startPlayer('example/asset/samples/sample.acc',
      whenFinished: () => print('finished'));
  bool isInitialised = false;
  bool isReleased = false;
  double subscriptionDuration;
  double volume;
  int seekPosition;

  setUpAll(() async {
    MethodChannel('audio_recorder')
        .setMockMethodCallHandler((methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'initializeMediaPlayer':
          isInitialised = true;
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
          if (!isInitialised) {
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
    });
  });

  // test('startPlayer', () {
  //   var player = SoundPlayer();

  //   player.startPlayer('example/asset/samples/sample.acc');
  // }, skip: true);

  // test('startPlayer - whenFinished', () {
  //   var player = SoundPlayer();

  //   try {
  //     player.startPlayer('example/asset/samples/sample.acc',
  //         whenFinished: () => print('finished'));
  //   } catch (e) {
  //     print(e);
  //   }
  // }, skip: false);
}
