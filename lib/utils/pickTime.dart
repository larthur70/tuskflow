import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Picktime {
  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _clampDate(DateTime date, DateTime min, DateTime max) {
    if (date.isBefore(min)) return min;
    if (date.isAfter(max)) return max;
    return date;
  }

  static Future<DateTime?> pickDate({
    required BuildContext context,
    DateTime? selectedDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final DateTime today = _dateOnly(DateTime.now());
    final DateTime resolvedFirst = _dateOnly(firstDate ?? today);
    final DateTime resolvedLast = _dateOnly(lastDate ?? DateTime(2100));
    final DateTime resolvedInitial = _clampDate(
      _dateOnly(selectedDate ?? today),
      resolvedFirst,
      resolvedLast,
    );

    DateTime? date;
    if (Platform.isIOS) {
      await showModalBottomSheet(
        context: context,
        builder: (_) {
          return SizedBox(
            height: 250,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: resolvedInitial,
              minimumDate: resolvedFirst,
              maximumDate: resolvedLast,
              onDateTimeChanged: (dateModal) {
                date = _dateOnly(dateModal);
              },
            ),
          );
        },
      );
    } else {
      date = await showDatePicker(
        context: context,
        initialDate: resolvedInitial,
        firstDate: resolvedFirst,
        lastDate: resolvedLast,
      );
    }

    if (date != null) {
      return _dateOnly(date!);
    }
    return null;
  }

  static Future<TimeOfDay?> pickTime({
    required BuildContext context,
    required TimeOfDay? selectedTime,
  }) async {
    TimeOfDay? time;
    final now = DateTime.now();
    if (Platform.isIOS) {
      final DateTime initialTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime?.hour ?? now.hour,
        selectedTime?.minute ?? now.minute,
      );
      await showModalBottomSheet(
        context: context,
        builder: (_) {
          return SizedBox(
            height: 250,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: initialTime,
              onDateTimeChanged: (timeModal) {
                time = TimeOfDay.fromDateTime(timeModal);
              },
            ),
          );
        },
      );
    } else {
      time = await showTimePicker(
        context: context,
        initialTime: selectedTime ?? TimeOfDay.now(),
      );
    }

    if (time != null) {
      return time;
    }
    return null;
  }
}
