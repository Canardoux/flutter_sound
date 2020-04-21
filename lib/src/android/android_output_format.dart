/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

///
class AndroidOutputFormat {
  final int _value;
  const AndroidOutputFormat._internal(this._value);
  String toString() => 'AndroidOutputFormat.$_value';

  ///
  int get value => _value;

  ///
  static const defaultFormat = AndroidOutputFormat._internal(0);

  ///
  static const threeGpp = AndroidOutputFormat._internal(1);

  ///
  static const mpeg_4 = AndroidOutputFormat._internal(2);

  ///
  static const amrNb = AndroidOutputFormat._internal(3);

  ///
  static const amrWb = AndroidOutputFormat._internal(4);

  ///
  static const aacAdts = AndroidOutputFormat._internal(6);

  ///
  static const outputFormatRtpAvp = AndroidOutputFormat._internal(7);

  ///
  static const mpeg_2Ts = AndroidOutputFormat._internal(8);

  ///
  static const webm = AndroidOutputFormat._internal(9);

  ///
  static const ogg = AndroidOutputFormat._internal(11);
}
