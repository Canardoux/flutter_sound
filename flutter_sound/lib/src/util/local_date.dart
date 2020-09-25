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


import 'package:flutter/foundation.dart';

import 'local_time.dart';

/// Provides a class which wraps a DateTime but just supplies
/// the date component.
@immutable
class LocalDate {
  ///
  final DateTime date;

  ///
  int get weekday => date.weekday;

  ///
  int get year => date.year;

  ///
  int get month => date.month;

  ///
  int get day => date.day;

  /// Creates a [LocalDate] with the date set to today's date.
  /// This is the same as calling [LocalDate()].
  /// required by json.
  LocalDate(int year, int month, int day)
      : date = DateTime(year, month, day, 0, 0, 0);

  /// Creates a ]LocalDate] by taking the date component of the past
  /// DateTime.
  LocalDate.fromDateTime(DateTime dateTime) : date = stripTime(dateTime);

  /// Converts a LocalDate to a DateTime.
  /// If you passed in [time] then
  /// That time is set as the time component
  /// on the resulting DateTime.
  /// If [time] is null then the time component
  /// is set to midnight at the start of this
  /// [LocalDate].
  DateTime toDateTime({LocalTime time}) {
    if (time == null) {
      return date;
    } else {
      return DateTime(
          date.year, date.month, date.day, time.hour, time.minute, time.second);
    }
  }

  ///
  static DateTime stripTime(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Creates a [LocalDate] with todays date.
  LocalDate.today() : date = stripTime(DateTime.now());

  ///
  LocalDate addDays(int days) {
    return LocalDate.fromDateTime(date.add(Duration(days: days)));
  }

  ///
  LocalDate subtractDays(int days) {
    return LocalDate.fromDateTime(date.subtract(Duration(days: days)));
  }

  ///
  bool isAfter(LocalDate rhs) {
    return date.isAfter(rhs.date);
  }

  ///
  bool isAfterOrEqual(LocalDate rhs) {
    return isAfter(rhs) || isEqual(rhs);
  }

  ///
  bool isBefore(LocalDate rhs) {
    return date.isBefore(rhs.date);
  }

  ///
  bool isBeforeOrEqual(LocalDate rhs) {
    return isBefore(rhs) || isEqual(rhs);
  }

  ///
  bool isEqual(LocalDate rhs) {
    return date.compareTo(rhs.date) == 0;
  }

  ///
  LocalDate add(Duration duration) {
    return LocalDate.fromDateTime(date.add(duration));
  }

  /// returns the no. of days between this date and the
  /// passed [other] date.
  int daysBetween(LocalDate other) {
    return date.difference(other.date).inDays;
  }
}
