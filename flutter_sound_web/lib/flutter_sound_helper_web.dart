import 'dart:async';
import 'dart:html' as html;

import 'package:meta/meta.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_helper_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';


/// The web implementation of [FlutterSoundHelper].
///
/// This class implements the `package:flutter_sound_helper` functionality for the web.
class FlutterSoundHelperWeb extends FlutterSoundPlatform {
  /// Registers this class as the default instance of [FlutterSoundHelperPlatform].
  static void registerWith(Registrar registrar) {
    FlutterSoundHelperPlatform.instance = FlutterSoundHelperWeb();
  }

  @override
  Future<bool> launch(String url) {
    return Future<bool>.value(html.window.open(url, '') != null);
  }
}
