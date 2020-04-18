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
