/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

@JS()
library flutter_sound;

import 'dart:async';
import 'dart:html' as html;

import 'package:meta/meta.dart';
import 'package:flauto_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flauto_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:typed_data';

import 'package:js/js.dart';

//========================================  JS  ===============================================================

@JS('newRecorderInstance')
external FlutterSoundRecorder newRecorderInstance(FlutterSoundRecorderCallback callBack, List<Function> callbackTable);

@JS('FlutterSoundRecorder')
class FlutterSoundRecorder
{
        @JS('newInstance')
        external static FlutterSoundRecorder newInstance(FlutterSoundRecorderCallback callBack, List<Function> callbackTable);

        @JS('initializeFlautoRecorder')
        external void initializeFlautoRecorder( int focus, int category, int mode, int audioFlags, int device);

        @JS('releaseFlautoRecorder')
        external void releaseFlautoRecorder();

        @JS('setAudioFocus')
        external void setAudioFocus(int focus, int category, int mode, int audioFlags, int device);

        @JS('isEncoderSupported')
        external bool isEncoderSupported(int codec);

        @JS('setSubscriptionDuration')
        external void setSubscriptionDuration(int duration);

        @JS('startRecorder')
        external void startRecorder(String path, int sampleRate, int numChannels, int bitRate, int codec, bool toStream, int audioSource);

        @JS('stopRecorder')
        external void stopRecorder();

        @JS('pauseRecorder')
        external void pauseRecorder();

        @JS('resumeRecorder')
        external void resumeRecorder();

}


List<Function> callbackTable =
[
        allowInterop( (FlutterSoundRecorderCallback cb, int duration, double dbPeakLevel) { cb.updateRecorderProgress(duration: duration, dbPeakLevel: dbPeakLevel);} ),
        allowInterop( (FlutterSoundRecorderCallback cb, {Uint8List data}) { cb.recordingData(data: data);} ),
];


//============================================================================================================================

/// The web implementation of [FlutterSoundRecorderPlatform].
///
/// This class implements the `package:FlutterSoundPlayerPlatform` functionality for the web.
class FlutterSoundRecorderWeb extends FlutterSoundRecorderPlatform //implements FlutterSoundRecorderCallback
{

        /// Registers this class as the default instance of [FlutterSoundRecorderPlatform].
        static void registerWith(Registrar registrar)
        {
                FlutterSoundRecorderPlatform.instance = FlutterSoundRecorderWeb();
        }



//============================================ Session manager ===================================================================


        List<FlutterSoundRecorder> _slots = [];
        FlutterSoundRecorder getWebSession(FlutterSoundRecorderCallback callback)
        {
                return _slots[findSession(callback)];
        }


//================================================================================================================


        @override
        Future<void> initializeFlautoRecorder(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device}) async
        {
                int slotno = findSession(callback);
                if (slotno < _slots.length)
                {
                        assert (_slots[slotno] == null);
                        _slots[slotno] = newRecorderInstance(callback, callbackTable);
                } else
                {
                        assert(slotno == _slots.length);
                        _slots.add( newRecorderInstance(callback, callbackTable));
                }
                getWebSession(callback).initializeFlautoRecorder(focus.index, category.index, mode.index, audioFlags, device.index);
        }


        @override
        Future<void> releaseFlautoRecorder(FlutterSoundRecorderCallback callback, ) async
        {
                int slotno = findSession(callback);
                _slots[slotno].releaseFlautoRecorder();
                _slots[slotno] = null;
        }

        @override
        Future<void> setAudioFocus(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} ) async
        {
                getWebSession(callback).setAudioFocus(focus.index, category.index, mode.index, audioFlags, device.index);
        }

        @override
        Future<bool> isEncoderSupported(FlutterSoundRecorderCallback callback, {Codec codec,}) async
        {
                return getWebSession(callback).isEncoderSupported(codec.index);
        }

        @override
        Future<void> setSubscriptionDuration(FlutterSoundRecorderCallback callback, {Duration duration,}) async
        {
                getWebSession(callback).setSubscriptionDuration(duration.inMilliseconds);
        }

        @override
        Future<void> startRecorder(FlutterSoundRecorderCallback callback,
            {
                    String path,
                    int sampleRate,
                    int numChannels,
                    int bitRate,
                    Codec codec,
                    bool toStream,
                    AudioSource audioSource,
            }) async
        {
                getWebSession(callback).startRecorder(path, sampleRate, numChannels, bitRate, codec.index, toStream, audioSource.index,);
        }

        @override
        Future<void> stopRecorder(FlutterSoundRecorderCallback callback,  ) async
        {
                FlutterSoundRecorder session = getWebSession(callback);
                if (session != null)
                        session.stopRecorder();
                else
                        print('Recorder already stopped');
        }

        @override
        Future<void> pauseRecorder(FlutterSoundRecorderCallback callback,  ) async
        {
                getWebSession(callback).pauseRecorder();
        }

        @override
        Future<void> resumeRecorder(FlutterSoundRecorderCallback callback, ) async
        {
                getWebSession(callback).resumeRecorder();
        }

}
