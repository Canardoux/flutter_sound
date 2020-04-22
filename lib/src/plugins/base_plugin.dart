/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Used to describe any class that can be placed into a slot.
class SlotEntry {}

/// provides a set of common methods used by
/// PluginInterfaces to talk to the underlying
/// Platform specific plugin.
abstract class BasePlugin {
  List<SlotEntry> _slots;

  ///
  @protected
  MethodChannel channel;

  /// The registered name of the plugin.
  final String _registeredName;

  /// Pass in the [_registeredName] which is the registered
  /// name of the plugin.
  BasePlugin(this._registeredName, this._slots) {
    channel = MethodChannel(_registeredName);
    channel.setMethodCallHandler(_onMethodCallback);
  }

  /// overload this method to handle callbacks from the underlying
  /// platform specific plugin
  Future<dynamic> onMethodCallback(SlotEntry slotEntry, MethodCall call);

  Future<dynamic> _onMethodCallback(MethodCall call) {
    var slotNo = call.arguments['slotNo'] as int;
    var slotEntry = _slots[slotNo];

    return onMethodCallback(slotEntry, call);
  }

  /// Invokes a method in the platform specific plugin for the
  /// given [slotEntry]. The connector is a link either
  /// a specific SoundRecorder or QuickPlay instance.
  Future<dynamic> invokeMethod(
      SlotEntry slotEntry, String methodName, Map<String, dynamic> call) {
    /// allocate a slot for this call.
    var slotNo = findSlot(slotEntry);
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
  void register(SlotEntry slotEntry) {
    var inserted = false;
    for (var i = 0; i < _slots.length; ++i) {
      if (_slots[i] == null) {
        _slots[i] = slotEntry;
        inserted = true;
        break;
      }
    }
    if (!inserted) {
      _slots.add(slotEntry);
    }
    print('registered SlotEntry to slot: ${_slots.length - 1}');
  }

  ///
  void release(SlotEntry slotEntry) {
    var slot = findSlot(slotEntry);
    if (slot != -1) {
      _slots[slot] = null;
    } else {
      throw SlotEntryNotRegisteredException(
          'The Slotable was not found when releasing the player.');
    }
  }

  ///
  @protected
  int findSlot(SlotEntry slotEntry) {
    var slot = -1;
    for (var i = 0; i < _slots.length; ++i) {
      if (_slots[i] == slotEntry) {
        slot = i;
        break;
      }
    }
    if (slot == -1) {
      throw SlotEntryNotRegisteredException('The Slotable was not found.');
    }
    return slot;
  }
}

/// Thrown if you try to release or access a connector that isn't
/// registered.
class SlotEntryNotRegisteredException implements Exception {
  final String _message;

  ///
  SlotEntryNotRegisteredException(this._message);

  String toString() => _message;
}
