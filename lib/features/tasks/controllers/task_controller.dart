import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';

class TaskController extends ChangeNotifier {
  TaskController(this._service) {
    _lastUid = FirebaseAuth.instance.currentUser?.uid;
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final String? newUid = user?.uid;
      if (newUid != _lastUid) {
        _lastUid = newUid;
        _taskStream = null;
        _streamGeneration++;
        notifyListeners();
      }
    });
  }

  final FirestoreTaskService _service;

  Stream<List<TaskModel>>? _taskStream;
  StreamSubscription<User?>? _authSubscription;
  String? _lastUid;
  int _streamGeneration = 0;

  int get streamGeneration => _streamGeneration;

  Stream<List<TaskModel>> get taskStream {
    _taskStream ??= _service.getTasks();
    return _taskStream!;
  }

  void invalidateTaskStream() {
    _taskStream = null;
    _streamGeneration++;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
