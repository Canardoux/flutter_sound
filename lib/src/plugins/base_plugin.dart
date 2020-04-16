import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// provides a set of common methods needed by plugins.
class BasePlugin {
  ///
  @protected
  MethodChannel channel;

  /// The registered name of the plugin.
  String pluginName;

  BasePlugin(this.pluginName);
}
