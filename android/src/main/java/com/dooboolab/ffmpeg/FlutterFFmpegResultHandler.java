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

import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

/**
 * <h3>Flutter FFmpeg Result Handler</h3>
 *
 * @author Taner Sener
 * @since 0.2.2
 */
class FlutterFFmpegResultHandler {
    private final Handler handler;

    FlutterFFmpegResultHandler() {
        handler = new Handler(Looper.getMainLooper());
    }

    void notImplemented(final MethodChannel.Result result) {
        handler.post(new Runnable() {

            @Override
            public void run() {
                if (result != null) {
                    result.notImplemented();
                }
            }
        });
    }

    void success(final MethodChannel.Result result, final Object object) {
        handler.post(new Runnable() {

            @Override
            public void run() {
                if (result != null) {
                    result.success(object);
                }
            }
        });
    }

    void success(final EventChannel.EventSink eventSink, final Object object) {
        handler.post(new Runnable() {

            @Override
            public void run() {
                if (eventSink != null) {
                    eventSink.success(object);
                }
            }
        });
    }

}
