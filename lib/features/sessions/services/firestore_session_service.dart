import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';

class FirestoreSessionService {
  final _firestore = FirebaseFirestore.instance;
  User? get user => FirebaseAuth.instance.currentUser;

  Future<void> createSession({
    required TaskModel task,
    required int durationSeconds,
    required bool continuedBeyond5min,
    WriteBatch? batch,
  }) async {
    if(user == null) return;
    
    final docRef = _firestore.collection('users').doc(user!.uid).collection("sessions").doc();
    final Map<String,dynamic> sessionData = {
      "taskId": task.id,
        "durationSeconds": durationSeconds,
        "continued5min":continuedBeyond5min,
        "createdAt":FieldValue.serverTimestamp()
      };
    if(batch != null){
      batch.set(docRef, sessionData);
    } else {
      await docRef.set(sessionData);
    }
  
    
  }
}