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

import 'dart:async';

/// Used to track the players state.
class PlayerState {
  static final PlayerState _self = PlayerState._internal();

  bool? _hushOthers = false;

  /// factory to retrieve a PlayerState
  factory PlayerState() {
    return _self;
  }

  PlayerState._internal();

  /// returns `true` if hushOthers (reduce other players volume)
  /// is enabled.
  bool? get hushOthers => _hushOthers;

  /// When we play something during whilst other audio is playing
  ///
  /// E.g. if Spotify is playing
  /// We can:
  // Stop Spotify
  // Play both our sound and Spotify
  // Or lower Spotify Sound during our playback.
  /// [setHush] controls option three.
  /// When passsing `true` to [setHush] the other auidio
  /// player's (e.g. spotify) sound is lowered.
  ///
  Future<void> setHush({bool? hushOthers}) async {
    _hushOthers = hushOthers;
  }
}
