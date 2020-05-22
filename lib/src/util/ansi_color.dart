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


/// Returns a string wrapped with the selected ansi
/// fg color codes.
String red(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.red, text, bgcolor: bgcolor);

///
String black(String text, {AnsiColor bgcolor = AnsiColor.white}) =>
    AnsiColor._apply(AnsiColor.black, text, bgcolor: bgcolor);

///
String green(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.green, text, bgcolor: bgcolor);

///
String blue(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.blue, text, bgcolor: bgcolor);

///
String yellow(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.yellow, text, bgcolor: bgcolor);

///
String magenta(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.magenta, text, bgcolor: bgcolor);

///
String cyan(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.cyan, text, bgcolor: bgcolor);

///
String white(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.white, text, bgcolor: bgcolor);

///
String orange(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.orange, text, bgcolor: bgcolor);

///
String grey(String text,
        {double level = 0.5, AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.grey(level: level), text, bgcolor: bgcolor);

///
class AnsiColor {
  ///
  static String reset() => _emmit(resetCode);

  ///
  static String fgReset() => _emmit(fgResetCode);

  ///
  static String bgReset() => _emmit(bgResetCode);

  final int _code;

  ///
  const AnsiColor(int code) : _code = code;

  ///
  int get code => _code;

  ///
  String apply(String text, {AnsiColor bgcolor = none}) =>
      _apply(this, text, bgcolor: bgcolor);

  static String _apply(AnsiColor color, String text,
      {AnsiColor bgcolor = none}) {
    String output;

    output = "${_fg(color.code)}${_bg(bgcolor?.code)}$text$_reset";
    return output;
  }

  static String get _reset {
    return "$esc${resetCode}m";
  }

  static String _fg(int code) {
    String output;

    if (code == none.code) {
      output = "";
    } else if (code > 39) {
      output = "$esc$fgColor${code}m";
    } else {
      output = "$esc${code}m";
    }
    return output;
  }

  // background colors are fg color + 10
  static String _bg(int code) {
    String output;

    if (code == none.code) {
      output = "";
    } else if (code > 49) {
      output = "$esc$bgColor${code + 10}m";
    } else {
      output = "$esc${code + 10}m";
    }
    return output;
  }

  static String _emmit(String ansicode) {
    return "$esc${ansicode}m";
  }

  /// ANSI Control Sequence Introducer, signals the terminal for new settings.
  static const esc = '\x1B[';

  /// Resets

  /// Reset fg and bg colors
  static const String resetCode = "0";

  /// Defaults the terminal's fg color without altering the bg.
  static const String fgResetCode = "39";

  /// Defaults the terminal's bg color without altering the fg.
  static const String bgResetCode = "49";

  /// emmit this code followed by a color code to set the fg color
  static const String fgColor = "38;5;";

  /// emmit this code followed by a color code to set the fg color
  static const String bgColor = "48;5;";

  /// Colors
  static const AnsiColor black = AnsiColor(30);

  ///
  static const AnsiColor red = AnsiColor(31);

  ///
  static const AnsiColor green = AnsiColor(32);

  ///
  static const AnsiColor yellow = AnsiColor(33);

  ///
  static const AnsiColor blue = AnsiColor(34);

  ///
  static const AnsiColor magenta = AnsiColor(35);

  ///
  static const AnsiColor cyan = AnsiColor(36);

  ///
  static const AnsiColor white = AnsiColor(37);

  ///
  static const AnsiColor orange = AnsiColor(208);

  ///
  static AnsiColor grey({double level = 0.5}) =>
      AnsiColor(232 + (level.clamp(0.0, 1.0) * 23).round());

  /// passing this as the background color will cause
  /// the background code to be suppressed resulting
  /// in the default background color.
  static const AnsiColor none = AnsiColor(-1);
}
