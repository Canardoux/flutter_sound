/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

/// Used to control the audio quality.
class IosQuality {
  final int _value;
  const IosQuality._internal(this._value);
  String toString() => 'IOSQuality.$_value';

  /// returns the quality which is a bit mask
  /// mapped to a set of static consts (MIN, LOW, ...)
  int get value => _value;

  /// minimum quality
  static const min = IosQuality._internal(0);

  /// low quality
  static const low = IosQuality._internal(0x20);

  /// medium quality
  static const medium = IosQuality._internal(0x40);

  /// high quality
  static const high = IosQuality._internal(0x60);

  /// max available quality.
  static const max = IosQuality._internal(0x7F);
}
