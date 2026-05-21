import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

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

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(settings: initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message){
      print('Got a message whilst in the foreground');
      print('Message data: ${message.data}');

      if(message.notification != null){
        _showLocalNotification(message.notification!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Handle navigation or actions here
    });
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

  Future<void> uploadFcmToken(String userId) async {
    try {
      final String? currentToken = await _messaging
          .getToken()
          .timeout(_fcmTokenTimeout, onTimeout: () => null);
      if (currentToken == null) return;
      await _persistTokenIfChanged(userId, currentToken);
    } catch (e) {
      print("Erro ao salvar token: $e");
    }
  }

  Future<void> _persistTokenIfChanged(String userId, String currentToken) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSavedToken = prefs.getString('last_fcm_token');

    if (currentToken == lastSavedToken) {
      print("Token não mudou. Escrita no Firestore poupada.");
      return;
    }

    await _db.collection('users').doc(userId).set(
      {'fcmToken': currentToken},
      SetOptions(merge: true),
    );

    await prefs.setString('last_fcm_token', currentToken);
    print("Token FCM atualizado no Firestore.");
  }
}