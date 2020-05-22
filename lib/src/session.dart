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



import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/src/session.dart';


enum Initialized {
        notInitialized,
        initializationInProgress,
        fullyInitialized,
        fullyInitializedWithUI,
}

class FlautoPlugin {
        List<Session> slots = [];

        MethodChannel channel;
        MethodChannel getChannel() => channel;


        Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call)  {
                return  getChannel().invokeMethod<dynamic>(methodName, call);
        }

        Session getSession(MethodCall call) {
                int slotNo = call.arguments['slotNo'] as int;
                return slots[slotNo];
        }


        int _lookupEmptySlot(Session aSession) {
                for (var i = 0; i < slots.length; ++i) {
                        if (slots[i] == null) {
                                slots[i] = aSession;
                                return i;
                        }
                }
                slots.add(aSession);
                return slots.length - 1;
        }

        void freeSlot(int slotNo) {
                slots[slotNo] = null;
        }

}

class Session {
        Initialized isInited = Initialized.notInitialized;
        int slotNo;
        FlautoPlugin getPlugin() => null; // Implemented in subClasses

        Future<dynamic> invokeMethod (
                    String methodName, Map<String, dynamic> call)  {
                        call['slotNo'] = slotNo;
                        return getPlugin().invokeMethod(methodName, call);
                    }

        void openSession() {
                slotNo = getPlugin( )._lookupEmptySlot( this );
        }

        void closeSession() {
                getPlugin().freeSlot(slotNo);
                slotNo = null;

        }

}
