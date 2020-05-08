import 'dart:async';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e2e/e2e.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Can get battery level', (tester) async {
    final player = AudioPlayer.noUI();
    expect(player, isNotNull);

    var released = false;
    var finished = Completer<bool>();

    player.onStopped = ({wasUser}) => finished.complete(true);
    Future.delayed(Duration(seconds: 10), () => finished.complete(false));

    player.play(Track.fromPath('assets/sample.acc'));

    finished.future.then<bool>((release) => released = release);

    await finished.future;

    expect(released, true);
  });
}
