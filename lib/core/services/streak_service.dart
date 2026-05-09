import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  final _firestore = FirebaseFirestore.instance;
  User? get user => FirebaseAuth.instance.currentUser;

  Future<int> calculateStreak({WriteBatch? batch})async{

    final userRef = _firestore.collection("users").doc(user?.uid);
    final now = DateTime.now();

    String today = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
    final yesterdayDate = now.subtract(Duration(days: 1));
    String yesterday = "${yesterdayDate.year}-${yesterdayDate.month.toString().padLeft(2,'0')}-${yesterdayDate.day.toString().padLeft(2,'0')}";

    final doc = await userRef.get();
    
    int currentStreak = 0;
    String? lastDate;

    if(doc.exists && doc.data() != null){
      currentStreak = doc.data()?['currentStreak'] ?? 0;
      lastDate = doc.data()?['lastSessionDate'];
    }

    int newStreak;

    if(lastDate == null){
      newStreak = 1;
    } else if (lastDate == today){
      return currentStreak;
    } else if(lastDate == yesterday){
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }

    final streakData = {
      'currentStreak':newStreak,
      'lastSessionDate': today,
    };

    if(batch != null){
      batch.set(userRef, streakData,SetOptions(merge: true));
    } else {
      await userRef.set(streakData,SetOptions(merge: true));
    }

    

    return newStreak;
  }
}