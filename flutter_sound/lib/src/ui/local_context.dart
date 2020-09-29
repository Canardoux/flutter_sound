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

///
class LocalContext extends StatefulWidget {
  final Widget Function(BuildContext context) _builder;

  ///
  LocalContext(
      {Key key, @required Widget Function(BuildContext context) builder})
      : _builder = builder,
        super(key: key);

  @override
  LocalContextState createState() => LocalContextState();
}

///
class LocalContextState extends State<LocalContext> {
  @override
  Widget build(BuildContext context) {
    return widget._builder(context);
  }
}
