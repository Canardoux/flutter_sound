import 'dart:async';
import 'dart:html' as html;

import 'package:meta/meta.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_sound_web/flutter_sound_player_web.dart';
import 'package:flutter_sound_web/flutter_sound_recorder_web.dart';



/// The web implementation of [FlutterSoundRecorderPlatform].
///
/// This class implements the `package:FlutterSoundPlayerPlatform` functionality for the web.
class FlutterSoundPlugin //extends FlutterSoundPlatform
{
        /// Registers this class as the default instance of [FlutterSoundPlatform].
        static void registerWith(Registrar registrar)
        {
                FlutterSoundPlayerWeb.registerWith(registrar);
                FlutterSoundRecorderWeb.registerWith(registrar);
        }
}
