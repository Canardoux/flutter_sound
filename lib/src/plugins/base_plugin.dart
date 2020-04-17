import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// provides a set of common methods used by
/// PluginInterfaces to talk to the underlying
/// Platform specific plugin.
abstract class BasePlugin {
  final List<Proxy> _slots = [];

  ///
  @protected
  MethodChannel channel;

  /// The registered name of the plugin.
  final String _registeredName;

  /// Pass in the [_registeredName] which is the registered
  /// name of the plugin.
  BasePlugin(this._registeredName) {
    channel = MethodChannel(_registeredName);
    channel.setMethodCallHandler(_onMethodCallback);
  }

  Future<dynamic> _onMethodCallback(MethodCall call) {
    var slotNo = call.arguments['slotNo'] as int;
    var connector = _slots[slotNo];

    return onMethodCallback(connector, call);
  }

  /// overload this method to handle callbacks from the underlying
  /// platform specific plugin
  Future<dynamic> onMethodCallback(Proxy connetor, MethodCall call);

  /// Invokes a method in the platform specific plugin for the
  /// given [connector]. The connector is a link either
  /// a specific SoundRecorder or SoundPlayer instance.
  Future<dynamic> invokeMethod(
      Proxy connector, String methodName, Map<String, dynamic> call) {
    /// allocate a slot for this call.
    var slotNo = _findSlot(connector);
    call['slotNo'] = slotNo;
    return getChannel().invokeMethod<dynamic>(methodName, call);
  }

  ///
  @protected
  MethodChannel getChannel() => channel;

  /// Allows you to register a connector with the plugin.
  /// Registering a connector allocates a slot for communicating
  /// with the platform specific plugin.
  /// To use a plugin you start by calling [register]
  /// and finish by calling [release].
  void register(Proxy connector) {
    var inserted = false;
    for (var i = 0; i < _slots.length; ++i) {
      if (_slots[i] == null) {
        _slots[i] = connector;
        inserted = true;
        break;
      }
    }
    if (!inserted) {
      _slots.add(connector);
    }
  }

  /// Releases the slot used by the connector.
  /// To use a plugin you start by calling [register]
  /// and finish by calling [release].
  void release(Proxy connector) {
    var found = false;
    for (var i = 0; i < _slots.length; ++i) {
      if (_slots[i] == null) {
        _slots[i] = null;
        found = true;
        break;
      }
    }
    if (!found) {
      throw PluginConnectorNotRegisteredException(
          'The PluginConnector was not found when releasing the connector.');
    }
  }

  ///
  @protected
  int _findSlot(Proxy connector) {
    var slot = -1;
    for (var i = 0; i < _slots.length; ++i) {
      if (_slots[i] == null) {
        slot = i;
        break;
      }
    }
    if (slot == -1) {
      throw PluginConnectorNotRegisteredException(
          'The PluginConnector was not found.');
    }
    return slot;
  }
}

/// Thrown if you try to release or access a connector that isn't
/// registered.
class PluginConnectorNotRegisteredException implements Exception {
  final String _message;

  ///
  PluginConnectorNotRegisteredException(this._message);

  String toString() => _message;
}

/// Base class for all PluginConnectors
class Proxy {}
