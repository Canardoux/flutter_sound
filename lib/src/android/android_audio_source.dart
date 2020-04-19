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
class AndroidAudioSource {
  final int _value;
  const AndroidAudioSource._internal(this._value);
  String toString() => 'AndroidAudioSource.$_value';

  ///
  int get value => _value;

  ///
  static const defaultSource = AndroidAudioSource._internal(0);

  ///
  static const mic = AndroidAudioSource._internal(1);

  ///
  static const voiceUplink = AndroidAudioSource._internal(2);

  ///
  static const voiceDownlink = AndroidAudioSource._internal(3);

  ///
  static const camcorder = AndroidAudioSource._internal(4);

  ///
  static const voiceRecognition = AndroidAudioSource._internal(5);

  ///
  static const voiceCommunication = AndroidAudioSource._internal(6);

  ///
  static const remoteSubmix = AndroidAudioSource._internal(7);

  ///
  static const unprocessed = AndroidAudioSource._internal(8);

  ///
  static const radioTuner = AndroidAudioSource._internal(9);

  ///
  static const hotword = AndroidAudioSource._internal(10);
}
