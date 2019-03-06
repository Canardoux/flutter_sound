package com.dooboolab.fluttersound;

import io.flutter.plugin.common.MethodChannel;

interface AudioInterface {
  void startRecorder(int numChannels, int sampleRate, Integer bitRate, int androidEncoder, String path, MethodChannel.Result result);
  void stopRecorder(MethodChannel.Result result);
  void startPlayer(String path, MethodChannel.Result result);
  void stopPlayer(MethodChannel.Result result);
  void pausePlayer(MethodChannel.Result result);
  void resumePlayer(MethodChannel.Result result);
  void seekToPlayer(int sec, MethodChannel.Result result);
  void setVolume(double volume, MethodChannel.Result result);
  void setSubscriptionDuration(double sec, MethodChannel.Result result);
  void setDbPeakLevelUpdate(double intervalInSecs, MethodChannel.Result result);
  void setDbLevelEnabled(boolean enabled, MethodChannel.Result result);
}
