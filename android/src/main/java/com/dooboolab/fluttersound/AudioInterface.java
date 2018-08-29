package com.dooboolab.fluttersound;

import io.flutter.plugin.common.MethodChannel;

interface AudioInterface {
  void startRecorder(String path, MethodChannel.Result result);
  void stopRecorder(MethodChannel.Result result);
  void startPlayer(String path, MethodChannel.Result result);
  void stopPlayer(MethodChannel.Result result);
  void pausePlayer(MethodChannel.Result result);
  void resumePlayer(MethodChannel.Result result);
  void seekToPlayer(int sec, MethodChannel.Result result);
  void setVolume(double volume, MethodChannel.Result result);
  void setSubscriptionDuration(double sec, MethodChannel.Result result);
}
