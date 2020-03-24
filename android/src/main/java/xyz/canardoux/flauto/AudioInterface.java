package xyz.canardoux.flauto;
/*
 * This file is part of Flauto.
 *
 *   Flauto is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flauto is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flauto.  If not, see <https://www.gnu.org/licenses/>.
 */


import io.flutter.plugin.common.MethodChannel;

// this enum MUST be synchronized with lib/flutter_sound.dart and ios/Classes/FlutterSoundPlugin.h
enum t_CODEC
{
  DEFAULT
  , AAC
  , OPUS
  , CODEC_CAF_OPUS // Apple encapsulates its bits in its own special envelope : .caf instead of a regular ogg/opus (.opus). This is completely stupid, this is Apple.
  , MP3
  , VORBIS
  , PCM
}

interface AudioInterface {
  void startRecorder(Integer numChannels, Integer sampleRate, Integer bitRate, t_CODEC codec, int androidEncoder, int androidAudioSource, int androidOutputFormat, String path, MethodChannel.Result result);
  void stopRecorder(MethodChannel.Result result);
  //void startPlayer(Track path, boolean canSkipForward,
  //boolean canSkipBackward, MethodChannel.Result result);
  void stopPlayer(MethodChannel.Result result);
  void pausePlayer(MethodChannel.Result result);
  void resumePlayer(MethodChannel.Result result);
  void seekToPlayer(int sec, MethodChannel.Result result);
  void setVolume(double volume, MethodChannel.Result result);
  void setSubscriptionDuration(double sec, MethodChannel.Result result);
  void setDbPeakLevelUpdate(double intervalInSecs, MethodChannel.Result result);
  void setDbLevelEnabled(boolean enabled, MethodChannel.Result result);
//void initializeMediaPlayer(boolean includeAudioPlayerFeatures, MethodChannel.Result result);
//void releaseMediaPlayer(MethodChannel.Result result);
}
