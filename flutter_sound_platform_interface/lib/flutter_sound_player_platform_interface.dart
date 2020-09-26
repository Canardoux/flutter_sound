import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_flutter_sound_player.dart';

/// The interface that implementations of url_launcher must implement.
///
/// Platform implementations should extend this class rather than implement it as `url_launcher`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [FlutterSoundPlayerPlatform] methods.
abstract class FlutterSoundPlayerPlatform extends PlatformInterface {
  /// Constructs a UrlLauncherPlatform.
  FlutterSoundPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSoundPlayerPlatform _instance = MethodChannelFlutterSound();

  /// The default instance of [UrlLauncherPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSoundPlayer].
  static FlutterSoundPlayerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [MethodChannelFlutterSoundPlayer] when they register themselves.
  static set instance(FlutterSoundPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Launches the given [url]. Completes to [true] if the launch was successful.
  Future<bool> launch(String url) {
    throw UnimplementedError('launch() has not been implemented.');
  }
}