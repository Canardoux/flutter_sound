package com.dooboolab.fluttersound;
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

import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Environment;

public class AudioModel {
  final public static String DEFAULT_FILE_LOCATION = Environment.getDataDirectory().getPath() + "/default.aac"; // SDK
                                                                                                                // 29 :
                                                                                                                // you
                                                                                                                // may
                                                                                                                // not
                                                                                                                // write
                                                                                                                // in
                                                                                                                // getExternalStorageDirectory()
  public int subsDurationMillis = 10;
  public long peakLevelUpdateMillis = 800;
  public boolean shouldProcessDbLevel = true;

  private MediaRecorder mediaRecorder;
  private Runnable recorderTicker;
  private Runnable dbLevelTicker;
  private long recordTime = 0;
  public final double micLevelBase = 2700;

  private MediaPlayer mediaPlayer;
  private long playTime = 0;

  public MediaRecorder getMediaRecorder() {
    return mediaRecorder;
  }

  public void setMediaRecorder(MediaRecorder mediaRecorder) {
    this.mediaRecorder = mediaRecorder;
  }

  public Runnable getRecorderTicker() {
    return recorderTicker;
  }

  public void setRecorderTicker(Runnable recorderTicker) {
    this.recorderTicker = recorderTicker;
  }

  public Runnable getDbLevelTicker() {
    return dbLevelTicker;
  }

  public void setDbLevelTicker(Runnable ticker) {
    this.dbLevelTicker = ticker;
  }

  public long getRecordTime() {
    return recordTime;
  }

  public void setRecordTime(long recordTime) {
    this.recordTime = recordTime;
  }

  public MediaPlayer getMediaPlayer() {
    return mediaPlayer;
  }

  public void setMediaPlayer(MediaPlayer mediaPlayer) {
    this.mediaPlayer = mediaPlayer;
  }

  public long getPlayTime() {
    return playTime;
  }

  public void setPlayTime(long playTime) {
    this.playTime = playTime;
  }
}
