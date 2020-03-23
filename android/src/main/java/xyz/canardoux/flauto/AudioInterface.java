package xyz.canardoux.flauto;
/*
 * This is a flutter_sound module.
 * flutter_sound is distributed with a MIT License
 *
 * Copyright (c) 2018 dooboolab
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
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
