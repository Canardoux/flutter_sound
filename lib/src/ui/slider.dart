/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */


import 'dart:async';

import 'package:flutter/material.dart';

//import '../playback_disposition.dart';
import '../flutter_sound_player.dart';

///
class PlaybarSlider extends StatefulWidget {
  final void Function(Duration position) _seek;

  ///
  final Stream<PlaybackDisposition> stream;

  final SliderThemeData _sliderThemeData;

  ///
  PlaybarSlider(this.stream, this._seek, this._sliderThemeData,);

  @override
  State<StatefulWidget> createState() {
    return PlaybarSliderState();
  }
}

///
class PlaybarSliderState extends State<PlaybarSlider> {
  @override
  Widget build(BuildContext context) {
  SliderThemeData sliderThemeData;
    if (widget._sliderThemeData == null)
            sliderThemeData = SliderTheme.of(context);
    else
            sliderThemeData = widget._sliderThemeData;
    return SliderTheme(
        data: sliderThemeData.copyWith(
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
            //thumbColor: Colors.amber,

            //inactiveTrackColor: Colors.green,
        ),
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
