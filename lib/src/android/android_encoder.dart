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

/// defines the set of codec support by android.
class AndroidEncoder {
  final int _value;
  const AndroidEncoder._internal(this._value);
  String toString() => 'AndroidEncoder.$_value';

  ///
  int get value => _value;

  ///
  static const defaultCodec = AndroidEncoder._internal(0);

  /// AMR (Narrowband) audio codec
  static const amrNbCodec = AndroidEncoder._internal(1);

  /// AMR (Wideband) audio codec
  static const amrWbCodec = AndroidEncoder._internal(2);

  /// AAC Low Complexity (AAC-LC) audio codec
  static const aacCodec = AndroidEncoder._internal(3);

  /// High Efficiency AAC (HE-AAC) audio codec
  static const heAccCodec = AndroidEncoder._internal(4);

  /// Enhanced Low Delay AAC (AAC-ELD) audio codec
  static const aacEldCodec = AndroidEncoder._internal(5);

  /// Enhanced Low Delay AAC (AAC-ELD) audio codec
  static const vorbisCodec = AndroidEncoder._internal(6);

  ///
  static const opusCodec = AndroidEncoder._internal(7);
}
