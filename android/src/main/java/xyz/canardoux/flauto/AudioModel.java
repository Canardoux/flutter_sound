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
