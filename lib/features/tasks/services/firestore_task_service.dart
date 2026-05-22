import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuskflow/core/utils/critical_operation_timeout.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';

class FirestoreTaskService {
  User? get user => FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;

  Future<void> inicializeTask(String taskId, {WriteBatch? batch}) async {
    final docRef = _firestore
        .collection("users")
        .doc(user!.uid)
        .collection("tasks")
        .doc(taskId);
    if (batch != null) {
      batch.update(docRef, {'initialized': true});
    } else {
      await docRef.update({'initialized': true});
    }
  }

  Future<void> createTask(
    String title,
    DateTime dueDate,
    {
    bool initialized = false,
    
  }) async {
    if (user == null) return;

    final taskRef = _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('tasks');
    await withCriticalOperationTimeout(
      taskRef.add({
        "title": title,
        "finished": false,
        "createdAt": FieldValue.serverTimestamp(),
        "initialized": initialized,
        "dueDate": Timestamp.fromDate(dueDate),
      }),
    );
  }

  Stream<List<TaskModel>> getTasks() {
    if (user == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .where("finished", isEqualTo: false)
        .orderBy('dueDate', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore
          .collection("users")
          .doc(user!.uid)
          .collection("tasks")
          .doc(taskId)
          .delete();
    } catch (e) {
      print("erro ao deletar $e");
    }
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    if (user == null) return null;

    final doc = await _firestore
        .collection("users")
        .doc(user!.uid)
        .collection("tasks")
        .doc(taskId)
        .get();

    if (!doc.exists) return null;
    return TaskModel.fromFirestore(doc);
  }

  Future<void> editTask(
    String taskId,
    String title,
    DateTime dueDate,
    bool initialized,
  ) async {
    try {
      await _firestore
          .collection("users")
          .doc(user!.uid)
          .collection("tasks")
          .doc(taskId)
          .update({
            'title': title,
            'dueDate': Timestamp.fromDate(dueDate),
            'initialized': initialized,
          });
    } catch (err) {
      print("erro ao editar $err");
    }
  }

  Future<void> finishTask(String taskId) async {
    try {
      await _firestore
          .collection("users")
          .doc(user!.uid)
          .collection("tasks")
          .doc(taskId)
          .update({'finished': true});
    } catch (err) {
      print("erro ao concluir $err");
    }
  }

  Future<void> editTaskStatus(String taskId, bool isFinished) async {
    await _firestore
        .collection("users")
        .doc(user!.uid)
        .collection("tasks")
        .doc(taskId)
        .update({'finished': isFinished});
  }
}
