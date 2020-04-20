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

/// Options for setSessionCategory on iOS
class IOSSessionCategoryOption {
  ///
  static const iosMixWithOthers = 0x1;

  ///
  static const iosDuckOthers = 0x2;

  ///
  static const iosInterruptSpokenAudioAndMixWithOthers = 0x11;

  ///
  static const iosAllowBluetooth = 0x4;

  ///
  static const iosAllowBluetoothA2Dp = 0x20;

  ///
  static const iosAllowAirPlay = 0x40;

  ///
  static const iosDefaultToSpeaker = 0x8;
}
