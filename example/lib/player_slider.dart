import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound_player.dart';

import 'player_state.dart';

class PlayerSlider extends StatefulWidget {
  const PlayerSlider({
    Key key,
  }) : super(key: key);

  @override
  _PlayerSliderState createState() => _PlayerSliderState();
}

class _PlayerSliderState extends State<PlayerSlider> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayStatus>(
        stream: PlayerState().playStatusStream,
        initialData: PlayStatus.zero(),
        builder: (context, snapshot) {
          double duration = 0;
          double position = 0;
          var playStatus = snapshot.data;
          duration = playStatus.duration;
          position = playStatus.currentPosition;
          return Container(
              height: 56.0,
              child: Slider(
                  value: min(position, duration),
                  min: 0.0,
                  max: duration,
                  onChanged: (double value) async {
                    await PlayerState().seekToPlayer(value.toInt());
                  },
                  divisions: duration == 0.0 ? 1 : duration.toInt()));
        });
  }
}
