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

import android.content.Context;

import com.arthenica.mobileffmpeg.AbiDetect;
import com.arthenica.mobileffmpeg.Config;
import com.arthenica.mobileffmpeg.FFmpeg;
import com.arthenica.mobileffmpeg.Level;
import com.arthenica.mobileffmpeg.LogCallback;
import com.arthenica.mobileffmpeg.LogMessage;
import com.arthenica.mobileffmpeg.MediaInformation;
import com.arthenica.mobileffmpeg.Statistics;
import com.arthenica.mobileffmpeg.StatisticsCallback;
import com.arthenica.mobileffmpeg.StreamInformation;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * <h3>Flutter FFmpeg Plugin</h3>
 *
 * @author Taner Sener
 * @since 0.1.0
 */
public class FlutterFFmpegPlugin implements MethodCallHandler, EventChannel.StreamHandler {
    public static final String LIBRARY_NAME = "flutter-ffmpeg";

    public static final String PLATFORM_NAME = "android";
    public static final String KEY_VERSION = "version";
    public static final String KEY_RC = "rc";
    public static final String KEY_PLATFORM = "platform";
    public static final String KEY_PACKAGE_NAME = "packageName";
    public static final String KEY_LAST_RC = "lastRc";
    public static final String KEY_PIPE = "pipe";

    public static final String KEY_LAST_COMMAND_OUTPUT = "lastCommandOutput";
    public static final String KEY_LOG_TEXT = "log";

    public static final String KEY_LOG_LEVEL = "level";
    public static final String KEY_STAT_TIME = "time";
    public static final String KEY_STAT_SIZE = "size";
    public static final String KEY_STAT_BITRATE = "bitrate";
    public static final String KEY_STAT_SPEED = "speed";
    public static final String KEY_STAT_VIDEO_FRAME_NUMBER = "videoFrameNumber";
    public static final String KEY_STAT_VIDEO_QUALITY = "videoQuality";
    public static final String KEY_STAT_VIDEO_FPS = "videoFps";

    public static final String EVENT_LOG = "FlutterFFmpegLogCallback";
    public static final String EVENT_STAT = "FlutterFFmpegStatisticsCallback";

    private EventChannel.EventSink eventSink;
    //private final Registrar registrar;
    private final FlutterFFmpegResultHandler flutterFFmpegResultHandler;

    static FlutterFFmpegPlugin flutterFFmpegPlugin; // singleton
    static Context              androidContext;


    public static void attachFFmpegPlugin( Context ctx, BinaryMessenger messenger )
    {
        assert ( flutterFFmpegPlugin == null );
        flutterFFmpegPlugin = new FlutterFFmpegPlugin();
        final MethodChannel channel = new MethodChannel(messenger, "flutter_ffmpeg");
        channel.setMethodCallHandler(flutterFFmpegPlugin);
        androidContext = ctx;
        final EventChannel eventChannel = new EventChannel(messenger, "flutter_ffmpeg_event");
        eventChannel.setStreamHandler(flutterFFmpegPlugin);
    }



    /**
     * Registers plugin to registry.
     */
    /*
    public static void registerWith(final Registrar registrar) {
        FlutterFFmpegPlugin flutterFFmpegPlugin = new FlutterFFmpegPlugin(registrar);

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_ffmpeg");
        channel.setMethodCallHandler(flutterFFmpegPlugin);

        final EventChannel eventChannel = new EventChannel(registrar.messenger(), "flutter_ffmpeg_event");
        eventChannel.setStreamHandler(flutterFFmpegPlugin);
    }
*/
    private FlutterFFmpegPlugin() {


        this.flutterFFmpegResultHandler = new FlutterFFmpegResultHandler();
    }


    private Context getActiveContext() {
        return androidContext;
    }

    /**
     * Handles method calls.
     *
     * @param call   method call
     * @param result result callback
     */
    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        if (call.method.equals("getPlatform")) {

            final String abi = AbiDetect.getAbi();
            flutterFFmpegResultHandler.success(result, toStringMap(KEY_PLATFORM, PLATFORM_NAME + "-" + abi));

        } else if (call.method.equals("getFFmpegVersion")) {

            final String version = Config.getFFmpegVersion();
            flutterFFmpegResultHandler.success(result, toStringMap(KEY_VERSION, version));

        } else if (call.method.equals("executeFFmpegWithArguments")) {

            List<String> arguments = call.argument("arguments");

            final FlutterFFmpegExecuteFFmpegAsyncArgumentsTask asyncTask = new FlutterFFmpegExecuteFFmpegAsyncArgumentsTask(arguments, flutterFFmpegResultHandler, result);
            asyncTask.execute("dummy-trigger");

        } else if (call.method.equals("executeFFprobeWithArguments")) {

            List<String> arguments = call.argument("arguments");

            final FlutterFFmpegExecuteFFprobeAsyncArgumentsTask asyncTask = new FlutterFFmpegExecuteFFprobeAsyncArgumentsTask(arguments, flutterFFmpegResultHandler, result);
            asyncTask.execute("dummy-trigger");

        } else if (call.method.equals("cancel")) {

            FFmpeg.cancel();

        } else if (call.method.equals("enableRedirection")) {

            Config.enableRedirection();

        } else if (call.method.equals("disableRedirection")) {

            Config.disableRedirection();

        } else if (call.method.equals("getLogLevel")) {

            final Level level = Config.getLogLevel();
            flutterFFmpegResultHandler.success(result, toIntMap(KEY_LOG_LEVEL, levelToInt(level)));

        } else if (call.method.equals("setLogLevel")) {

            Integer level = call.argument("level");
            if (level == null) {
                level = Level.AV_LOG_TRACE.getValue();
            }
            Config.setLogLevel(Level.from(level));

        } else if (call.method.equals("enableLogs")) {

            Config.enableLogCallback(new LogCallback() {

                @Override
                public void apply(final LogMessage logMessage) {
                    emitLogMessage(logMessage);
                }
            });

        } else if (call.method.equals("disableLogs")) {

            Config.enableLogCallback(null);

        } else if (call.method.equals("enableStatistics")) {

            Config.enableStatisticsCallback(new StatisticsCallback() {

                @Override
                public void apply(final Statistics statistics) {
                    emitStatistics(statistics);
                }
            });

        } else if (call.method.equals("disableStatistics")) {

            Config.enableStatisticsCallback(null);

        } else if (call.method.equals("getLastReceivedStatistics")) {

            flutterFFmpegResultHandler.success(result, toMap(Config.getLastReceivedStatistics()));

        } else if (call.method.equals("resetStatistics")) {

            Config.resetStatistics();

        } else if (call.method.equals("setFontconfigConfigurationPath")) {
            String path = call.argument("path");

            Config.setFontconfigConfigurationPath(path);

        } else if (call.method.equals("setFontDirectory")) {

            String path = call.argument("fontDirectory");
            Map<String, String> map = call.argument("fontNameMap");

            Config.setFontDirectory(getActiveContext(), path, map);

        } else if (call.method.equals("getPackageName")) {

            final String packageName = Config.getPackageName();
            flutterFFmpegResultHandler.success(result, toStringMap(KEY_PACKAGE_NAME, packageName));

        } else if (call.method.equals("getExternalLibraries")) {

            final List<String> externalLibraries = Config.getExternalLibraries();
            flutterFFmpegResultHandler.success(result, externalLibraries);

        } else if (call.method.equals("getLastReturnCode")) {

            int lastReturnCode = Config.getLastReturnCode();
            flutterFFmpegResultHandler.success(result, toIntMap(KEY_LAST_RC, lastReturnCode));

        } else if (call.method.equals("getLastCommandOutput")) {

            final String lastCommandOutput = Config.getLastCommandOutput();
            flutterFFmpegResultHandler.success(result, toStringMap(KEY_LAST_COMMAND_OUTPUT, lastCommandOutput));

        } else if (call.method.equals("getMediaInformation")) {
            final String path = call.argument("path");
            Integer timeout = call.argument("timeout");
            if (timeout == null) {
                timeout = 10000;
            }

            final FlutterFFmpegGetMediaInformationAsyncTask asyncTask = new FlutterFFmpegGetMediaInformationAsyncTask(path, flutterFFmpegResultHandler, result);
            asyncTask.execute();

        } else if (call.method.equals("registerNewFFmpegPipe")) {

            final String pipe = Config.registerNewFFmpegPipe(getActiveContext());
            flutterFFmpegResultHandler.success(result, toStringMap(KEY_PIPE, pipe));

        } else {
            flutterFFmpegResultHandler.notImplemented(result);
        }
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        this.eventSink = null;
    }

    protected void emitLogMessage(final LogMessage logMessage) {
        final HashMap<String, Object> logWrapperMap = new HashMap<>();
        final HashMap<String, Object> logMap = new HashMap<>();

        logMap.put(KEY_LOG_LEVEL, levelToInt(logMessage.getLevel()));
        logMap.put(KEY_LOG_TEXT, logMessage.getText());

        logWrapperMap.put(EVENT_LOG, logMap);

        flutterFFmpegResultHandler.success(eventSink, logWrapperMap);
    }

    protected void emitStatistics(final Statistics statistics) {
        final HashMap<String, Object> statisticsMap = new HashMap<>();
        statisticsMap.put(EVENT_STAT, toMap(statistics));
        flutterFFmpegResultHandler.success(eventSink, statisticsMap);
    }

    public static int levelToInt(final Level level) {
        return (level == null) ? Level.AV_LOG_TRACE.getValue() : level.getValue();
    }

    public static HashMap<String, String> toStringMap(final String key, final String value) {
        final HashMap<String, String> map = new HashMap<>();
        map.put(key, value);
        return map;
    }

    public static HashMap<String, Integer> toIntMap(final String key, final int value) {
        final HashMap<String, Integer> map = new HashMap<>();
        map.put(key, value);
        return map;
    }

    public static Map<String, Object> toMap(final Statistics statistics) {
        final HashMap<String, Object> statisticsMap = new HashMap<>();

        if (statistics != null) {
            statisticsMap.put(KEY_STAT_TIME, statistics.getTime());
            statisticsMap.put(KEY_STAT_SIZE, (statistics.getSize() < Integer.MAX_VALUE) ? (int) statistics.getSize() : (int) (statistics.getSize() % Integer.MAX_VALUE));
            statisticsMap.put(KEY_STAT_BITRATE, statistics.getBitrate());
            statisticsMap.put(KEY_STAT_SPEED, statistics.getSpeed());

            statisticsMap.put(KEY_STAT_VIDEO_FRAME_NUMBER, statistics.getVideoFrameNumber());
            statisticsMap.put(KEY_STAT_VIDEO_QUALITY, statistics.getVideoQuality());
            statisticsMap.put(KEY_STAT_VIDEO_FPS, statistics.getVideoFps());
        }

        return statisticsMap;
    }

    public static HashMap<String, Object> toMediaInformationMap(final MediaInformation mediaInformation) {
        final HashMap<String, Object> map = new HashMap<>();

        if (mediaInformation != null) {
            if (mediaInformation.getFormat() != null) {
                map.put("format", mediaInformation.getFormat());
            }
            if (mediaInformation.getPath() != null) {
                map.put("path", mediaInformation.getPath());
            }
            if (mediaInformation.getStartTime() != null) {
                map.put("startTime", mediaInformation.getStartTime().intValue());
            }
            if (mediaInformation.getDuration() != null) {
                map.put("duration", mediaInformation.getDuration().intValue());
            }
            if (mediaInformation.getBitrate() != null) {
                map.put("bitrate", mediaInformation.getBitrate().intValue());
            }
            if (mediaInformation.getRawInformation() != null) {
                map.put("rawInformation", mediaInformation.getRawInformation());
            }

            final Set<Map.Entry<String, String>> metadata = mediaInformation.getMetadataEntries();
            if ((metadata != null) && (metadata.size() > 0)) {
                final HashMap<String, String> metadataMap = new HashMap<>();

                for (Map.Entry<String, String> entry : metadata) {
                    metadataMap.put(entry.getKey(), entry.getValue());
                }

                map.put("metadata", metadataMap);
            }

            final List<StreamInformation> streams = mediaInformation.getStreams();
            if ((streams != null) && (streams.size() > 0)) {
                final ArrayList<Map<String, Object>> array = new ArrayList<>();

                for (StreamInformation streamInformation : streams) {
                    array.add(toStreamInformationMap(streamInformation));
                }

                map.put("streams", array);
            }
        }

        return map;
    }

    public static Map<String, Object> toStreamInformationMap(final StreamInformation streamInformation) {
        final HashMap<String, Object> map = new HashMap<>();

        if (streamInformation != null) {
            if (streamInformation.getIndex() != null) {
                map.put("index", streamInformation.getIndex().intValue());
            }
            if (streamInformation.getType() != null) {
                map.put("type", streamInformation.getType());
            }
            if (streamInformation.getCodec() != null) {
                map.put("codec", streamInformation.getCodec());
            }
            if (streamInformation.getFullCodec() != null) {
                map.put("fullCodec", streamInformation.getFullCodec());
            }
            if (streamInformation.getFormat() != null) {
                map.put("format", streamInformation.getFormat());
            }
            if (streamInformation.getFullFormat() != null) {
                map.put("fullFormat", streamInformation.getFullFormat());
            }
            if (streamInformation.getWidth() != null) {
                map.put("width", streamInformation.getWidth().intValue());
            }
            if (streamInformation.getHeight() != null) {
                map.put("height", streamInformation.getHeight().intValue());
            }
            if (streamInformation.getBitrate() != null) {
                map.put("bitrate", streamInformation.getBitrate().intValue());
            }
            if (streamInformation.getSampleRate() != null) {
                map.put("sampleRate", streamInformation.getSampleRate().intValue());
            }
            if (streamInformation.getSampleFormat() != null) {
                map.put("sampleFormat", streamInformation.getSampleFormat());
            }
            if (streamInformation.getChannelLayout() != null) {
                map.put("channelLayout", streamInformation.getChannelLayout());
            }
            if (streamInformation.getSampleAspectRatio() != null) {
                map.put("sampleAspectRatio", streamInformation.getSampleAspectRatio());
            }
            if (streamInformation.getDisplayAspectRatio() != null) {
                map.put("displayAspectRatio", streamInformation.getDisplayAspectRatio());
            }
            if (streamInformation.getAverageFrameRate() != null) {
                map.put("averageFrameRate", streamInformation.getAverageFrameRate());
            }
            if (streamInformation.getRealFrameRate() != null) {
                map.put("realFrameRate", streamInformation.getRealFrameRate());
            }
            if (streamInformation.getTimeBase() != null) {
                map.put("timeBase", streamInformation.getTimeBase());
            }
            if (streamInformation.getCodecTimeBase() != null) {
                map.put("codecTimeBase", streamInformation.getCodecTimeBase());
            }

            final Set<Map.Entry<String, String>> metadata = streamInformation.getMetadataEntries();
            if ((metadata != null) && (metadata.size() > 0)) {
                final HashMap<String, String> metadataMap = new HashMap<>();

                for (Map.Entry<String, String> entry : metadata) {
                    metadataMap.put(entry.getKey(), entry.getValue());
                }

                map.put("metadata", metadataMap);
            }

            final Set<Map.Entry<String, String>> sidedata = streamInformation.getSidedataEntries();
            if ((sidedata != null) && (sidedata.size() > 0)) {
                final HashMap<String, String> sidedataMap = new HashMap<>();

                for (Map.Entry<String, String> entry : sidedata) {
                    sidedataMap.put(entry.getKey(), entry.getValue());
                }

                map.put("sidedata", sidedataMap);
            }
        }

        return map;
    }

}
