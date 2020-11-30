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

import 'package:flutter/material.dart';

import 'demo_util/demo3_body.dart';

// If you update the following test, please update also the Examples/README.md file and the comment inside the dart file.
/*
 * This is a Demo of an App which uses the Flutter Sound UI Widgets.
 *
 * My own feeling is that this Demo is really too much complicated for doing something very simple.
 * There is too many dependencies and too many sources.
 *
 * I really hope that someone will write soon another simpler Demo App.
 */

/// Example app.
class WidgetUIDemo extends StatefulWidget {
  @override
  _WidgetUIDemoState createState() => _WidgetUIDemoState();
}

class _WidgetUIDemoState extends State<WidgetUIDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Widget UI Demo'),
      ),
      body: MainBody(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
