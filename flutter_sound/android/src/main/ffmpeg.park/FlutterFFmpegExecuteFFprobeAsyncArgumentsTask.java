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

import java.util.Arrays;
import java.util.List;

import io.flutter.plugin.common.MethodChannel;

/**
 * Asynchronous task which performs {@link FFprobe#execute(String[])} method invocations.
 *
 * @author Taner Sener
 * @since 0.2.9
 */
public class FlutterFFmpegExecuteFFprobeAsyncArgumentsTask extends AsyncTask<String, Integer, Integer> {

    private final MethodChannel.Result result;
    private final List<String> arguments;
    private final FlutterFFmpegResultHandler flutterFFmpegResultHandler;

    FlutterFFmpegExecuteFFprobeAsyncArgumentsTask(final List<String> arguments, final FlutterFFmpegResultHandler flutterFFmpegResultHandler, final MethodChannel.Result result) {
        this.arguments = arguments;
        this.result = result;
        this.flutterFFmpegResultHandler = flutterFFmpegResultHandler;
    }

    @Override
    protected Integer doInBackground(final String... unusedArgs) {
        final String[] argumentsArray = arguments.toArray(new String[0]);

        Log.d(FlutterSoundFFmpeg.LIBRARY_NAME, String.format("Running FFprobe with arguments: %s.", Arrays.toString(argumentsArray)));

        int rc = FFprobe.execute(argumentsArray);

        Log.d(FlutterSoundFFmpeg.LIBRARY_NAME, String.format("FFprobe exited with rc: %d", rc));

        return rc;
    }

    @Override
    protected void onPostExecute(final Integer rc) {
        flutterFFmpegResultHandler.success(result, FlutterSoundFFmpeg.toIntMap(FlutterSoundFFmpeg.KEY_RC, rc));
    }

}
