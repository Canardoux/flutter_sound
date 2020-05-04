/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL-3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'dart:io';


FlutterSoundHelper flutterSoundHelper = FlutterSoundHelper(); // Singleton

class FlutterSoundHelper {
        FlutterFFmpeg flutterFFmpeg;
        FlutterFFmpegConfig _flutterFFmpegConfig;
        FlutterFFprobe _flutterFFprobe;
        bool ffmpegAvailable;


        Future<bool> isFFmpegAvailable() async {
                if (_flutterFFmpegConfig == null) {
                        _flutterFFmpegConfig = FlutterFFmpegConfig();
                        String version = await _flutterFFmpegConfig.getFFmpegVersion();
                        String platform = await _flutterFFmpegConfig.getPlatform();
                        ffmpegAvailable = (version != null && platform != null);
                }
                return ffmpegAvailable;

        }

        /// We use here our own ffmpeg "execute" procedure instead of the one provided by the flutter_ffmpeg plugin,
        /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
        /// and without any complain from the link-editor.
        ///
        /// Executes FFmpeg with [commandArguments] provided.
        Future<int> executeFFmpegWithArguments(List<String> arguments) {
                if (flutterFFmpeg == null) flutterFFmpeg = FlutterFFmpeg();
                return flutterFFmpeg.executeWithArguments(arguments);
        }

        /// We use here our own ffmpeg "getLastReturnCode" procedure instead of the one provided by the flutter_ffmpeg plugin,
        /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
        /// and without any complain from the link-editor.
        ///
        /// Returns return code of last executed command.
        Future<int> getLastFFmpegReturnCode() async {
                await isFFmpegAvailable();
                return _flutterFFmpegConfig.getLastReturnCode();

        }

        /// We use here our own ffmpeg "getLastCommandOutput" procedure instead of the one provided by the flutter_ffmpeg plugin,
        /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
        /// and without any complain from the link-editor.
        ///
        /// Returns log output of last executed command. Please note that disabling redirection using
        /// This method does not support executing multiple concurrent commands. If you execute multiple commands at the same time, this method will return output from all executions.
        /// [disableRedirection()] method also disables this functionality.
        Future<String> getLastFFmpegCommandOutput() async {
                await isFFmpegAvailable();
                return _flutterFFmpegConfig.getLastCommandOutput();
           }

        Future<Map<dynamic, dynamic>> FFmpegGetMediaInformation(String uri) async {
                if (uri == null) return null;
                if (_flutterFFprobe == null) _flutterFFprobe = FlutterFFprobe();
                try {
                        return await _flutterFFprobe.getMediaInformation(uri);
                } catch (e) {
                        return null;
                }
        }

        Future<int> duration(String uri) async {
                if (uri == null) return null;
                Map<dynamic, dynamic> info = await FFmpegGetMediaInformation(uri);
                if (info == null) return null;
                int duration = info['duration'] as int;
                return duration;
        }
        Future<bool> convertFile(String infile, FlutterSoundCodec codecin, String outfile, FlutterSoundCodec codecout) async
        {
                File fout = File(outfile);
                //if (fout.existsSync( ))
                {
                        // delete the old temporary file if it exists
                        //await fout.delete( );
                }
                // The following ffmpeg instruction
                // does not decode and re-encode the file.
                // It just remux the OPUS data into an Apple CAF envelope.
                // It is probably very fast
                // and the user will not notice any delay,
                // even with a very large data.
                // This is the price to pay for the Apple stupidity.
                int rc;
                if (codecin == FlutterSoundCodec.opusOGG && codecout == FlutterSoundCodec.opusCAF) // Do not need to re-encode. Just remux
                        rc =
                await flutterSoundHelper.executeFFmpegWithArguments( [
                                                                       '-loglevel',
                                                                       'error',
                                                                       '-y',
                                                                       '-i',
                                                                       infile,
                                                                       '-c:a',
                                                                       'copy',
                                                                       outfile,
                                                               ] ); // remux OGG to CAF
                else
                rc = await flutterSoundHelper.executeFFmpegWithArguments( [
                                                                                        '-loglevel',
                                                                                        'error',
                                                                                        '-y',
                                                                                        '-i',
                                                                                        infile,
                                                                                        outfile,
                ] );

                return (rc != 0) ;
        }

}

