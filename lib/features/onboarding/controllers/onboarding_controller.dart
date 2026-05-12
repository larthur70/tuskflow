import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> initializeUser({
    required bool completedOnboarding,
    String? title,
    DateTime? dueDate
  })async{
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null){
      throw Exception("erro ao criar usuário");
    }
    final userRef = _firestore.collection("users").doc(user.uid);
    final batch = _firestore.batch();

    batch.set(userRef, {
      "createdAt":FieldValue.serverTimestamp(),
      "lastNotificationSentAt":Timestamp.fromMicrosecondsSinceEpoch(0)
    },SetOptions(merge: true));
    // usuário saiu pelo X
    if (!completedOnboarding) {

      await batch.commit();

      return;
    }

    // segurança
    if (title == null || dueDate == null) {
      throw Exception(
        "title e dueDate são obrigatórios"
      );
    }

    final now = DateTime.now();

    final taskRef =
        userRef.collection("tasks").doc();

    // cria primeira task
    batch.set(taskRef, {
      "title": title,
      "finished": false,
      "createdAt":
          FieldValue.serverTimestamp(),
      "initialized": false,
      "dueDate":
          Timestamp.fromDate(dueDate),
    });

    // ativa sistema de reminder
    batch.set(
      userRef,
      {
        "lastTimerAt":
            Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}