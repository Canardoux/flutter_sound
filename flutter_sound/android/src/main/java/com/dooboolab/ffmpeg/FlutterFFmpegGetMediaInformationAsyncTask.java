/*
 * Copyright (c) 2019 Taner Sener
 *
 * This file is part of FlutterFFmpeg.
 *
 * FlutterFFmpeg is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FlutterFFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with FlutterFFmpeg.  If not, see <http://www.gnu.org/licenses/>.
 */

package com.dooboolab.ffmpeg;

import android.os.AsyncTask;
import android.util.Log;

import com.arthenica.mobileffmpeg.FFprobe;
import com.arthenica.mobileffmpeg.MediaInformation;

import io.flutter.plugin.common.MethodChannel;

/**
 * Asynchronous task which performs {@link FFprobe#getMediaInformation(String, Long)} method invocations.
 *
 * @author Taner Sener
 * @since 0.1.0
 */
public class FlutterFFmpegGetMediaInformationAsyncTask extends AsyncTask<String, Integer, MediaInformation> {

    private final String path;
    private final MethodChannel.Result result;
    private final FlutterFFmpegResultHandler flutterFFmpegResultHandler;

    FlutterFFmpegGetMediaInformationAsyncTask(final String path, final FlutterFFmpegResultHandler flutterFFmpegResultHandler, final MethodChannel.Result result) {
        this.path = path;
        this.result = result;
        this.flutterFFmpegResultHandler = flutterFFmpegResultHandler;
    }

    @Override
    protected MediaInformation doInBackground(final String... unusedArgs) {
        Log.d(FlutterSoundFFmpeg.LIBRARY_NAME, String.format("Getting media information for %s.", path));
        return FFprobe.getMediaInformation(path);
    }

    @Override
    protected void onPostExecute(final MediaInformation mediaInformation) {
        flutterFFmpegResultHandler.success(result, FlutterSoundFFmpeg.toMediaInformationMap(mediaInformation));
    }

}
