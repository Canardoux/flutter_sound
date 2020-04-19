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
enum IOSSessionCategory {
  ///
  ambient,

  ///
  multiRoute,

  ///
  playAndRecord,

  ///
  playback,

  ///
  record,

  ///
  soloAambient,
}

///
final List<String> iosSessionCategory = [
  'AVAudioSessionCategoryAmbient',
  'AVAudioSessionCategoryMultiRoute',
  'AVAudioSessionCategoryPlayAndRecord',
  'AVAudioSessionCategoryPlayback',
  'AVAudioSessionCategoryRecord',
  'AVAudioSessionCategorySoloAmbient',
];
