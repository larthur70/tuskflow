import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Picktime {
  static Future<DateTime?> pickDate({
    required BuildContext context,
    
    DateTime? selectedDate
  }) async {
    final DateTime now = DateTime.now();
    DateTime? date;
    if(Platform.isIOS){
      await showModalBottomSheet(context: context, builder: (_){
        return SizedBox(
          height: 250,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: selectedDate ?? now,
            minimumDate: now.subtract(Duration(seconds: 1)),
            onDateTimeChanged: (dateModal){
              date = dateModal;
            }
            )
        );
      });
    } else {
      date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100));
    }
    
    
    if (date != null){
      return date;
    }
    return null;
  }


  static Future<TimeOfDay?> pickTime({
    required BuildContext context,
    required TimeOfDay? selectedTime
   
  }) async {
    TimeOfDay? time;
    final now = DateTime.now();
    if(Platform.isIOS){
      final DateTime initialTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime?.hour ?? now.hour,
        selectedTime?.minute ?? now.minute
      );
       await showModalBottomSheet(context: context, builder: (_){
         return SizedBox(
           height: 250,
           child: CupertinoDatePicker(
             mode: CupertinoDatePickerMode.time,
             use24hFormat: true,
             initialDateTime: initialTime,
             onDateTimeChanged: (timeModal){
               time = TimeOfDay.fromDateTime(timeModal);
             }
             )
         );
       });
     } else {
      time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
     }
    
    
    if (time != null){
      return time;
  }
    return null;
  }
}