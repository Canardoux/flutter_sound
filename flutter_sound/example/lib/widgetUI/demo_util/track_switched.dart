/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

import 'demo_player_state.dart';

/// UI widget from the TrackPlayer specific settings
/// Allow Tracks and Hush Others
class TrackSwitch extends StatefulWidget {
  final void Function(bool useOSUI) _switchPlayer;

  /// ctor
  const TrackSwitch({
    Key? key,
    required bool isAudioPlayer,
    required void Function(bool userOSUI) switchPlayer,
  })   : _isAudioPlayer = isAudioPlayer,
        _switchPlayer = switchPlayer,
        super(key: key);

  final bool _isAudioPlayer;

  @override
  _TrackSwitchState createState() => _TrackSwitchState();
}

class _TrackSwitchState extends State<TrackSwitch> {
  _TrackSwitchState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('Use OS Media Player:'),
          ),
          Switch(
            value: widget._isAudioPlayer,
            onChanged: (allow) =>
                onAudioPlayerSwitchChanged(allowTracks: allow),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text('Hush Others:'),
          ),
          Switch(
            value: PlayerState().hushOthers!,
            onChanged: (hushOthers) =>
                hushOthersSwitchChanged(hushOthers: hushOthers),
          ),
        ],
      ),
    );
  }

  void onAudioPlayerSwitchChanged({bool allowTracks = false}) async {
    widget._switchPlayer(allowTracks);
  }

  void hushOthersSwitchChanged({bool? hushOthers}) {
    PlayerState().setHush(hushOthers: hushOthers);
  }
}
