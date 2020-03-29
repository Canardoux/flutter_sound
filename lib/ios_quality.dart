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

class IosQuality {
  final _value;
  const IosQuality._internal(this._value);
  toString() => 'IOSQuality.$_value';
  int get value => _value;

  static const MIN = const IosQuality._internal(0);
  static const LOW = const IosQuality._internal(0x20);
  static const MEDIUM = const IosQuality._internal(0x40);
  static const HIGH = const IosQuality._internal(0x60);
  static const MAX = const IosQuality._internal(0x7F);
}
