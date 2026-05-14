import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuskflow/core/models/user_model.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
    User? get user => FirebaseAuth.instance.currentUser;

  Future<void> incrementProcrastinationDefeated(TaskModel task,WriteBatch batch)async {
    final now = DateTime.now();
    final difference = task.dueDate.difference(now);

    if(user == null) return;

    if(difference.inHours > 24 && !task.initialized){
      final userDoc = _firestore.collection('users').doc(user!.uid);
      batch.update(userDoc, {
        'earlyStartsCount': FieldValue.increment(1)
      });
    }
  }

  Future<UserModel?> getUserData()async{
    if(user == null) return null;
    final doc = await _firestore.collection('users').doc(user!.uid).get();

    final data = doc.data();

    if(data == null) return null;

    return UserModel.fromMap(data);
  }

  
}