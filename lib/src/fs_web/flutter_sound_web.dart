/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 * Copyright 2021, 2022, 2023, 2024 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL-2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
//import 'dart:html' as html;
import 'package:web/web.dart';
//import 'dart:js_util';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

//import 'package:meta/meta.dart';
import 'package:flutter_sound_advanced/src/fs_platform/flutter_sound_recorder_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_sound_advanced/src/fs_web/flutter_sound_player_web.dart';
import 'package:flutter_sound_advanced/src/fs_web/flutter_sound_recorder_web.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter_sound_advanced/src/fs_logger_compat.dart' show Logger;

var mime_types = [
  'audio/webm\;codecs=opus', // defaultCodec,
  'audio/aac', // aacADTS, //*
  'audio/opus\;codecs=opus', // opusOGG, // 'audio/ogg' 'audio/opus'
  'audio/x-caf', // opusCAF,
  'audio/mpeg', // mp3, //*
  'audio/ogg\;codecs=vorbis', // vorbisOGG,// 'audio/ogg' // 'audio/vorbis'
  'audio/pcm', // pcm16,
  'audio/wav\;codecs=1', // pcm16WAV,
  'audio/aiff', // pcm16AIFF,
  'audio/x-caf', // pcm16CAF,
  'audio/x-flac', // flac, // 'audio/flac'
  'audio/mp4', // aacMP4, //*
  'audio/AMR', // amrNB, //*
  'audio/AMR-WB', // amrWB, //*
  'audio/pcm', // pcm8,
  'audio/pcm', // pcmFloat32,
  'audio/webm\;codecs=pcm', // pcmWebM,
  'audio/webm\;codecs=opus', // opusWebM,
  'audio/webm\;codecs=vorbis', // vorbisWebM
];
/*
class ImportJsLibraryWeb {
  /// Injects the library by its [url]
  static Future<void> import(String url) {
    return _importJSLibraries([url]);
  }

  static html.ScriptElement _createScriptTag(String library) {
    final html.ScriptElement script = html.ScriptElement()
      ..type = "text/javascript"
      ..charset = "utf-8"
      ..async = true
      //..defer = true
      ..src = library;
    return script;
  }

  /// Injects a bunch of libraries in the <head> and returns a
  /// Future that resolves when all load.
  static Future<void> _importJSLibraries(List<String> libraries) {
    final List<Future<void>> loading = <Future<void>>[];
    final head = html.querySelector('head')!;

    libraries.forEach((String library) {
      if (!isImported(library)) {
        final scriptTag = _createScriptTag(library);
        head.children.add(scriptTag);
        loading.add(scriptTag.onLoad.first);
      }
    });

    return Future.wait(loading);
  }

  static bool _isLoaded(html.Element head, String url) {
    if (url.startsWith("./")) {
      url = url.replaceFirst("./", "");
    }
    for (var element in head.children) {
      if (element is html.ScriptElement) {
        if (element.src.endsWith(url)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool isImported(String url) {
    final html.Element head = html.querySelector('head')!;
    return _isLoaded(head, url);
  }
}

class ImportJsLibrary {
  static Future<void> import(String url) {
    if (kIsWeb)
      return ImportJsLibraryWeb.import(url);
    else
      return Future.value(null);
  }

  static bool isImported(String url) {
    if (kIsWeb) {
      return ImportJsLibraryWeb.isImported(url);
    } else {
      return false;
    }
  }

  static registerWith(dynamic _) {
    // useful for flutter registrar
  }
}

String _libraryUrl(String url, String pluginName) {
  if (url.startsWith("./")) {
    url = url.replaceFirst("./", "");
    return "./assets/packages/$pluginName/$url";
  }
  if (url.startsWith("assets/")) {
    return "./assets/packages/$pluginName/$url";
  } else {
    return url;
  }
}

void importJsLibrary({required String url, required String flutterPluginName}) {
  ImportJsLibrary.import(_libraryUrl(url, flutterPluginName)).then((value) {
    --FlutterSoundPlugin._numberOfScripts;
    if (FlutterSoundPlugin._numberOfScripts == 0) {
      FlutterSoundPlugin.ScriptLoaded.complete();
    }
  });
}


bool isJsLibraryImported(String url, {required String flutterPluginName}) {
  //if (flutterPluginName == null) {
  //        return ImportJsLibrary.isImported(url);
  //} else {
  return ImportJsLibrary.isImported(_libraryUrl(url, flutterPluginName));
  //}
}
*/

/// The web implementation of [FlutterSoundRecorderPlatform].
///
/// This class implements the `package:FlutterSoundPlayerPlatform` functionality for the web.
class FlutterSoundPlugin //extends FlutterSoundPlatform
{
  static Future<bool> loadScript(String scriptName) async {
    //print('Loding $scriptName');
    Logger().i('Loding $scriptName');
    Element newScript = document.createElement('script');
    newScript.setProperty('src'.toJS, scriptName.toJS);
    newScript.setProperty('type'.toJS, 'text/javascript'.toJS);
    newScript.setProperty('async'.toJS, true.toJS);
    Completer<bool> completer = Completer<bool>();

    newScript.setProperty(
      'onload'.toJS,
      (MessageEvent e) {
        completer.complete(true);
      }.toJS,
    );

    newScript.setProperty(
      'onerror'.toJS,
      (MessageEvent e) {
        completer.completeError(
          AssertionError('Cannot load script $scriptName'),
        );
      }.toJS,
    );

    //newScript.onload = () => console.log(`${file} loaded successfully.`);
    //newScript.onerror = () => console.error(`Error loading script: ${file}`);

    document.head!.appendChild(newScript);
    return completer.future;
  }

  static bool _alreadyInited = false;
  static Future<bool> loadScripts() async {
    if (!_alreadyInited) {
      //print('Loading scripts');
      await loadScript('./assets/packages/flutter_sound_advanced/web_assets/howler/howler.js');
      await loadScript(
        './assets/packages/flutter_sound_advanced/web_assets/src/flutter_sound.js',
      );
      await loadScript(
        './assets/packages/flutter_sound_advanced/web_assets/src/flutter_sound_player.js',
      );
      await FlutterSoundPlugin.loadScript(
        './assets/packages/flutter_sound_advanced/web_assets/src/flutter_sound_recorder.js',
      );
    }
    _alreadyInited = true;
    return true;
  }

  /// Registers this class as the default instance of [FlutterSoundPlatform].
  static void registerWith(Registrar registrar) {
    FlutterSoundPlayerWeb.registerWith(registrar);
    FlutterSoundRecorderWeb.registerWith(registrar);
    /*
    importJsLibrary(
      url: "./howler/howler.js",
      flutterPluginName: "flutter_sound_web",
    );
    importJsLibrary(
      url: "./src/flutter_sound.js",
      flutterPluginName: "flutter_sound_web",
    );
    importJsLibrary(
      url: "./src/flutter_sound_player.js",
      flutterPluginName: "flutter_sound_web",
    );
    importJsLibrary(
      url: "./src/flutter_sound_recorder.js",
      flutterPluginName: "flutter_sound_web",
    );

     */
  }
}
