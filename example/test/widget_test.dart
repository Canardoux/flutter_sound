// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:flutter_sound_example/main.dart';

void main() {
  final List<MethodCall> log = <MethodCall>[];
  MethodChannel channel = const MethodChannel('plugins.flutter_sound/flutter_sound');
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    log.add(methodCall);
  });

  test('Audio Recorder', () async {
    expect(log, equals(<MethodCall>[new MethodCall('startRecorder', "")]));
  });

  // Unregister the mock handler.
  channel.setMockMethodCallHandler(null);

  testWidgets('Render test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(new MyApp());

    // Verify that platform version is retrieved.
    expect(
        find.byWidgetPredicate(
              (Widget widget) =>
          widget is Text && widget.data.startsWith('Flutter Sound'),
        ),
        findsOneWidget);
  });
}
