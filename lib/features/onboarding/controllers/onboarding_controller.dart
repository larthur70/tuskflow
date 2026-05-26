import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuskflow/core/utils/critical_operation_timeout.dart';

class OnboardingController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> initializeUser({
    required bool completedOnboarding,
    String? title,
    DateTime? dueDate
  })async{
    final credential = await withOnboardingOperationTimeout(
      _auth.signInAnonymously(),
    );
    final user = credential.user;
    if (user == null){
      throw Exception("erro ao criar usuário");
    }
    final userRef = _firestore.collection("users").doc(user.uid);
    final batch = _firestore.batch();

    final Map<String, dynamic> userData = {
      "createdAt": FieldValue.serverTimestamp(),
      "lastNotificationSentAt": Timestamp.fromMicrosecondsSinceEpoch(0),
    };

    // usuário saiu pelo X
    if (!completedOnboarding) {
      batch.set(userRef, userData, SetOptions(merge: true));
      await withOnboardingOperationTimeout(batch.commit());
      return;
    }

    if (title == null || dueDate == null) {
      throw Exception("title e dueDate são obrigatórios");
    }

    final now = DateTime.now();
    userData["lastTimerAt"] = Timestamp.fromDate(now);
    userData["habitHour"] = now.hour;

    batch.set(userRef, userData, SetOptions(merge: true));

    final taskRef = userRef.collection("tasks").doc();
    batch.set(taskRef, {
      "title": title,
      "finished": false,
      "createdAt": FieldValue.serverTimestamp(),
      "initialized": false,
      "dueDate": Timestamp.fromDate(dueDate),
    });

    await withOnboardingOperationTimeout(batch.commit());
  }
}