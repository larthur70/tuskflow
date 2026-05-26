
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String title;
  final DateTime dueDate;
  final DateTime createdAt;
  final bool finished;
  final bool initialized;

  TaskModel({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.createdAt,
    required this.initialized,
    required this.finished
  });

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Returns null when the document is missing required fields.
  static TaskModel? tryFromFirestore(DocumentSnapshot doc) {
    final Object? raw = doc.data();
    if (raw is! Map<String, dynamic>) return null;

    final String? title = raw['title'] as String?;
    final DateTime? dueDate = _timestampToDate(raw['dueDate']);
    if (title == null || title.trim().isEmpty || dueDate == null) {
      return null;
    }

    final DateTime createdAt =
        _timestampToDate(raw['createdAt']) ?? DateTime.now();

    return TaskModel(
      id: doc.id,
      title: title.trim(),
      dueDate: dueDate,
      finished: raw['finished'] as bool? ?? false,
      createdAt: createdAt,
      initialized: raw['initialized'] as bool? ?? false,
    );
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final TaskModel? task = tryFromFirestore(doc);
    if (task == null) {
      throw FormatException('Invalid task document: ${doc.id}');
    }
    return task;
  }

  String get remainingTimeText {
    final now = DateTime.now();
    final today = DateTime(now.year,now.month,now.day);
    final dateToCompare = DateTime(dueDate.year,dueDate.month,dueDate.day);

    final differenceDay = dateToCompare.difference(today).inDays;
    final diferenceWeek = (differenceDay / 7).round();
    final diferenceMonth = (differenceDay / 30).round();

    if(differenceDay < 0) return "ATRASADA";
    if(differenceDay == 0) return "VENCE HOJE!";
    if(differenceDay == 1) return "FALTA 1 DIA";
    if(differenceDay > 1 && differenceDay <= 6) return "FALTAM $differenceDay DIAS";
    if(diferenceWeek == 1) return "FALTA 1 SEMANA";
    if(diferenceWeek > 1 && diferenceWeek < 4) return "FALTAM $diferenceWeek SEMANAS";
    if(diferenceMonth == 1) return "FALTA 1 MÊS";
    return "FALTAM $diferenceMonth MESES";
  }

  Color get statusColor {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCompare = DateTime(dueDate.year, dueDate.month, dueDate.day);
  
    final difference = dateToCompare.difference(today).inDays;

    if(difference <= 3) return Colors.red;
    if(difference <= 7) return Colors.amber;
    return Colors.green;
  }

  /// True when [at] is more than 24 hours before [dueDate] (early start window).
  bool isEarlyStartAt([DateTime? at]) {
    final DateTime reference = at ?? DateTime.now();
    return dueDate.difference(reference).inHours > 24;
  }
}