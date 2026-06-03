import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuskflow/core/utils/critical_operation_timeout.dart';

/// Gates [HomePage] until Firestore onboarding writes finish (avoids auth racing ahead).
class OnboardingSetupService {
  static const String _setupDoneKey = 'onboarding_setup_done';
  static const String _pendingStartFiveMinutesTaskIdKey =
      'pending_start_five_minutes_task_id';

  Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_setupDoneKey) ?? false) {
      return true;
    }
    return _migrateIfUserAlreadyProvisioned(prefs);
  }

  Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupDoneKey, true);
  }

  Future<void> clearSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupDoneKey, false);
    await clearPendingStartFiveMinutesTaskId();
  }

  Future<void> setPendingStartFiveMinutesTaskId(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingStartFiveMinutesTaskIdKey, taskId);
  }

  Future<String?> takePendingStartFiveMinutesTaskId() async {
    final prefs = await SharedPreferences.getInstance();
    final taskId = prefs.getString(_pendingStartFiveMinutesTaskIdKey);
    if (taskId != null) {
      await prefs.remove(_pendingStartFiveMinutesTaskIdKey);
    }
    return taskId;
  }

  Future<void> clearPendingStartFiveMinutesTaskId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingStartFiveMinutesTaskIdKey);
  }

  /// Creates a minimal user profile when Auth exists but Firestore doc does not.
  Future<bool> ensureMinimalUserProfile() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await withOnboardingOperationTimeout(docRef.get());

      if (!doc.exists) {
        await withOnboardingOperationTimeout(
          docRef.set(
            {
              'createdAt': FieldValue.serverTimestamp(),
              'lastNotificationSentAt':
                  Timestamp.fromMicrosecondsSinceEpoch(0),
            },
            SetOptions(merge: true),
          ),
        );
        await markSetupComplete();
        return true;
      }

      return false;
    } catch (e, st) {
      debugPrint('ensureMinimalUserProfile failed: $e\n$st');
      return false;
    }
  }

  Future<bool> _migrateIfUserAlreadyProvisioned(SharedPreferences prefs) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final doc = await withOnboardingOperationTimeout(
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
      );
      if (!doc.exists) return false;

      await prefs.setBool(_setupDoneKey, true);
      return true;
    } catch (e, st) {
      debugPrint('onboarding migration check failed: $e\n$st');
      return false;
    }
  }
}
