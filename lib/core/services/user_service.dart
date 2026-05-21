import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuskflow/core/models/user_model.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  User? get user => FirebaseAuth.instance.currentUser;

  UserModel? _cachedUser;
  String? _cachedForUid;

  void invalidateUserCache() {
    _cachedUser = null;
    _cachedForUid = null;
  }

  Future<void> incrementProcrastinationDefeated(TaskModel task,WriteBatch batch)async {
    if(user == null) return;

    if (task.isEarlyStartAt()) {
      final userDoc = _firestore.collection('users').doc(user!.uid);
      batch.update(userDoc, {
        'earlyStartsCount': FieldValue.increment(1),
      });
      if (_cachedForUid == user!.uid && _cachedUser != null) {
        _cachedUser = UserModel(
          earlyStartsCount: _cachedUser!.earlyStartsCount + 1,
          interestedInPro: _cachedUser!.interestedInPro,
          email: _cachedUser!.email,
          displayName: _cachedUser!.displayName,
        );
      }
    }
  }

  Future<UserModel?> getUserData({bool forceRefresh = false}) async {
    if (user == null) {
      invalidateUserCache();
      return null;
    }

    if (!forceRefresh &&
        _cachedForUid == user!.uid &&
        _cachedUser != null) {
      return _cachedUser;
    }

    final doc = await _firestore.collection('users').doc(user!.uid).get();
    final data = doc.data();

    if (data == null) {
      invalidateUserCache();
      return null;
    }

    _cachedUser = UserModel.fromMap(data);
    _cachedForUid = user!.uid;
    return _cachedUser;
  }

  Future<void> registerInterestInPro() async {
    if (user == null) return;
    await _firestore.collection('users').doc(user!.uid).update({
      'interestedInPro': true,
      'interestedInProAt': FieldValue.serverTimestamp(),
    });
    _cachedUser = UserModel(
      earlyStartsCount: _cachedUser?.earlyStartsCount ?? 0,
      interestedInPro: true,
      email: _cachedUser?.email,
      displayName: _cachedUser?.displayName,
    );
    _cachedForUid = user!.uid;
  }

  /// Saves profile fields from social login (Apple only sends name/email once).
  Future<void> saveLinkedAccountProfile({
    required String uid,
    String? email,
    String? displayName,
  }) async {
    final Map<String, dynamic> data = {};
    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }
    if (displayName != null && displayName.trim().isNotEmpty) {
      data['displayName'] = displayName.trim();
    }
    if (data.isEmpty) return;

    await _firestore.collection('users').doc(uid).set(
      data,
      SetOptions(merge: true),
    );
    if (user?.uid == uid) {
      invalidateUserCache();
    }
  }
}
