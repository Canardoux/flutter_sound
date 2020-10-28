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
import 'dart:typed_data' show Uint8List;
import 'package:flutter_sound_lite/src/flutter_sound_player.dart';

class Food
{
  Future<void> exec(FlutterSoundPlayer player) {}
}

class FoodData extends Food
{
  Uint8List data;
  /* ctor */ FoodData(Uint8List this.data){}
  Future<void> exec(FlutterSoundPlayer player) => player.feedFromStream(data);
}

class FoodEvent extends Food
{
  Function on;
  /* ctor */ FoodEvent(Function this.on){}
  Future<void> exec(FlutterSoundPlayer player) async => on();
}
