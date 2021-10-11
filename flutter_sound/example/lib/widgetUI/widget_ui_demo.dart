/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
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
