import 'dart:async';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String notificationPromptHandledKey =
      'notification_prompt_handled';
  static const String _pendingSocialLoginNotificationPromptKey =
      'pending_social_login_notification_prompt';
  static const String _installationIdKey = 'fcm_installation_id';
  static const String _lastFcmTokenKey = 'last_fcm_token';
  static const String _fcmTokensCollection = 'fcmTokens';
  static const String _legacyFcmTokenDocId = '_legacy';
  static const int _maxFcmTokensPerUser = 5;
  static const Duration _staleFcmTokenAge = Duration(days: 30);

  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _tokenRefreshHandlerRegistered = false;

  void registerTokenRefreshHandler() {
    if (_tokenRefreshHandlerRegistered) return;
    _tokenRefreshHandlerRegistered = true;

    _messaging.onTokenRefresh.listen((String token) async {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _persistTokenIfChanged(uid, token);
    });
  }

  Future<void> initialize({required AnalyticsService analytics}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (_) {
        unawaited(analytics.logNotificationClicked());
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message.notification!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      unawaited(analytics.logNotificationClicked());
    });

    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await analytics.logNotificationClicked();
    }
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails('your_channel_id', 'your_channel_name',
    importance: Importance.max,
    priority: Priority.high
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics
    );
    await _localNotifications.show(
      id: 0,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformChannelSpecifics
    );
  }

  static const Duration _fcmTokenTimeout = Duration(seconds: 8);

  Future<bool> shouldShowNotificationPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(notificationPromptHandledKey) ?? false) {
      return false;
    }
    if (await _isNotificationPermissionGranted()) {
      await markNotificationPromptHandled();
      return false;
    }
    return true;
  }

  Future<void> markNotificationPromptHandled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationPromptHandledKey, true);
  }

  /// Set when user reaches home via Google/Apple login from onboarding login.
  Future<void> markPendingSocialLoginNotificationPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSocialLoginNotificationPromptKey, true);
  }

  /// Shows the OS notification dialog once after onboarding social login.
  Future<void> requestSystemPermissionIfPendingFromOnboardingSocialLogin() async {
    await requestSystemPermissionOnHomeIfNeeded();
  }

  /// OS prompt on home: social-login onboarding, or fresh install with restored auth.
  Future<void> requestSystemPermissionOnHomeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final bool pendingSocial =
        prefs.getBool(_pendingSocialLoginNotificationPromptKey) ?? false;
    if (pendingSocial) {
      await prefs.remove(_pendingSocialLoginNotificationPromptKey);
    }

    final bool handled = prefs.getBool(notificationPromptHandledKey) ?? false;
    if (handled && !pendingSocial) return;

    if (await _isNotificationPermissionGranted()) {
      await markNotificationPromptHandled();
      await _uploadFcmIfSignedIn();
      return;
    }

    await markNotificationPromptHandled();
    await requestSystemNotificationPermission();
    await _uploadFcmIfSignedIn();
  }

  Future<void> _uploadFcmIfSignedIn() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(uploadFcmToken(uid));
    }
  }

  Future<bool> areNotificationsEnabled() => _isNotificationPermissionGranted();

  Future<bool> _isNotificationPermissionGranted() async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  Future<void> requestSystemNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
  }

  Future<void> openDeviceNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> uploadFcmToken(String userId) async {
    try {
      final String? currentToken = await _messaging
          .getToken()
          .timeout(_fcmTokenTimeout, onTimeout: () => null);
      if (currentToken == null) return;
      await _persistTokenIfChanged(userId, currentToken);
    } catch (e, st) {
      debugPrint('uploadFcmToken failed: $e\n$st');
    }
  }

  /// Removes this device's token from the user document (call before sign-out).
  Future<void> removeCurrentDeviceToken({String? userId}) async {
    final String? uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final String installationId = await _getOrCreateInstallationId();
      await _db
          .collection('users')
          .doc(uid)
          .collection(_fcmTokensCollection)
          .doc(installationId)
          .delete();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastFcmTokenKey);
    } catch (e, st) {
      debugPrint('removeCurrentDeviceToken failed: $e\n$st');
    }
  }

  Future<void> _persistTokenIfChanged(String userId, String currentToken) async {
    final String installationId = await _getOrCreateInstallationId();
    final DocumentReference<Map<String, dynamic>> tokenDocRef = _db
        .collection('users')
        .doc(userId)
        .collection(_fcmTokensCollection)
        .doc(installationId);

    final DocumentSnapshot<Map<String, dynamic>> tokenDoc = await tokenDocRef.get();
    if (tokenDoc.exists) {
      final String? storedToken = tokenDoc.data()?['token'] as String?;
      if (storedToken == currentToken) {
        await _migrateLegacyFcmTokenIfNeeded(userId);
        await _pruneStaleFcmTokens(userId, installationId);
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString(_lastFcmTokenKey) != currentToken) {
          await prefs.setString(_lastFcmTokenKey, currentToken);
        }
        return;
      }
    }

    await _migrateLegacyFcmTokenIfNeeded(userId);

    await tokenDocRef.set({
      'token': currentToken,
      'platform': _platformLabel(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _pruneStaleFcmTokens(userId, installationId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFcmTokenKey, currentToken);
    debugPrint('FCM token saved for installation $installationId');
  }

  Future<void> _migrateLegacyFcmTokenIfNeeded(String userId) async {
    final DocumentReference<Map<String, dynamic>> userRef =
        _db.collection('users').doc(userId);
    final DocumentSnapshot<Map<String, dynamic>> userDoc = await userRef.get();
    final String? legacyToken = userDoc.data()?['fcmToken'] as String?;
    if (legacyToken == null || legacyToken.isEmpty) return;

    await userRef.collection(_fcmTokensCollection).doc(_legacyFcmTokenDocId).set({
      'token': legacyToken,
      'platform': 'unknown',
      'updatedAt': FieldValue.serverTimestamp(),
      'migratedFromLegacy': true,
    }, SetOptions(merge: true));

    await userRef.update({'fcmToken': FieldValue.delete()});
  }

  /// Removes duplicate, legacy, stale, and excess FCM token docs for this user.
  Future<void> _pruneStaleFcmTokens(
    String userId,
    String currentInstallationId,
  ) async {
    try {
      final CollectionReference<Map<String, dynamic>> tokensRef = _db
          .collection('users')
          .doc(userId)
          .collection(_fcmTokensCollection);
      final QuerySnapshot<Map<String, dynamic>> snap = await tokensRef.get();

      String? currentToken;
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        if (doc.id == currentInstallationId) {
          currentToken = doc.data()['token'] as String?;
          break;
        }
      }

      final Set<DocumentReference<Map<String, dynamic>>> toDelete = {};
      final DateTime staleCutoff =
          DateTime.now().subtract(_staleFcmTokenAge);

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        if (doc.id == currentInstallationId) continue;

        final Map<String, dynamic> data = doc.data();
        final String? token = data['token'] as String?;

        if (doc.id == _legacyFcmTokenDocId) {
          toDelete.add(doc.reference);
          continue;
        }

        if (currentToken != null && token == currentToken) {
          toDelete.add(doc.reference);
          continue;
        }

        final Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
        if (updatedAt == null || updatedAt.toDate().isBefore(staleCutoff)) {
          toDelete.add(doc.reference);
        }
      }

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> remainingOthers =
          snap.docs
              .where(
                (doc) =>
                    doc.id != currentInstallationId &&
                    !toDelete.contains(doc.reference),
              )
              .toList()
            ..sort((a, b) {
              final Timestamp? aTs = a.data()['updatedAt'] as Timestamp?;
              final Timestamp? bTs = b.data()['updatedAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

      const int maxOtherTokens = _maxFcmTokensPerUser - 1;
      if (remainingOthers.length > maxOtherTokens) {
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in remainingOthers.skip(maxOtherTokens)) {
          toDelete.add(doc.reference);
        }
      }

      if (toDelete.isEmpty) return;

      final WriteBatch batch = _db.batch();
      for (final DocumentReference<Map<String, dynamic>> ref in toDelete) {
        batch.delete(ref);
      }
      await batch.commit();
      debugPrint('Pruned ${toDelete.length} stale FCM token(s) for $userId');
    } catch (e, st) {
      debugPrint('_pruneStaleFcmTokens failed: $e\n$st');
    }
  }

  Future<String> _getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? existing = prefs.getString(_installationIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final String installationId = _generateInstallationId();
    await prefs.setString(_installationIdKey, installationId);
    return installationId;
  }

  static String _generateInstallationId() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final String b = bytes.map(hex).join();
    return '${b.substring(0, 8)}-${b.substring(8, 12)}-'
        '${b.substring(12, 16)}-${b.substring(16, 20)}-${b.substring(20)}';
  }

  static String _platformLabel() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}