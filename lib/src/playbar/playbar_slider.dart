import 'dart:async';

import 'package:flutter/material.dart';

import '../playback_disposition.dart';

///
class PlaybarSlider extends StatefulWidget {
  final void Function(Duration position) _seek;

  ///
  final Stream<PlaybackDisposition> stream;

  ///
  PlaybarSlider(this.stream, this._seek);

  @override
  State<StatefulWidget> createState() {
    return PlaybarSliderState();
  }
}

///
class PlaybarSliderState extends State<PlaybarSlider> {
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
        data: SliderTheme.of(context).copyWith(
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
            inactiveTrackColor: Colors.blueGrey),
        child: StreamBuilder<PlaybackDisposition>(
            stream: widget.stream,
            initialData: PlaybackDisposition.zero(),
            builder: (context, snapshot) {
              var disposition = snapshot.data;
              return Slider(
                max: disposition.duration.inMilliseconds.toDouble(),
                value: disposition.position.inMilliseconds.toDouble(),
                onChanged: (value) =>
                    widget._seek(Duration(milliseconds: value.toInt())),
              );
            }));
  }
}
