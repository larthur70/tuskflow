import 'package:flutter/material.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';

class TaskController extends ChangeNotifier {
  final FirestoreTaskService _service;

  Stream<List<TaskModel>>? _taskStream;

  TaskController(this._service);

  Stream<List<TaskModel>> get taskStream{
    _taskStream ??= _service.getTasks();
    return _taskStream!;
  }
}