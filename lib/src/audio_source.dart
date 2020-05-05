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
/// Determines the source that should be recorded.
/// Currently these are only supported by android.
/// For iOS we always record from the microphone.
class AudioSource {
  final int _value;
  const AudioSource._internal(this._value);
  String toString() => 'AudioSource.$_value';

  ///
  int get value => _value;

  ///
  static const defaultSource = AudioSource._internal(0);

  ///
  static const mic = AudioSource._internal(1);

  ///
  static const voiceUplink = AudioSource._internal(2);

  ///
  static const voiceDownlink = AudioSource._internal(3);

  ///
  static const camcorder = AudioSource._internal(4);

  ///
  static const voiceRecognition = AudioSource._internal(5);

  ///
  static const voiceCommunication = AudioSource._internal(6);

  ///
  static const remoteSubmix = AudioSource._internal(7);

  ///
  static const unprocessed = AudioSource._internal(8);

  ///
  static const radioTuner = AudioSource._internal(9);

  ///
  static const hotword = AudioSource._internal(10);
}
