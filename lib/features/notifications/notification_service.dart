import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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

  Future<void> uploadFcmToken(String userId) async {
    try {
      await Future.delayed(Duration(seconds: 2));
      String? currentToken = await _messaging.getToken();
      if (currentToken == null) return;

      final prefs = await SharedPreferences.getInstance();
      String? lastSavedToken = prefs.getString('last_fcm_token');

      //if (currentToken != lastSavedToken){
        await _db.collection('users').doc(userId).set({
          'fcmToken':currentToken,
          'lastActivity':FieldValue.serverTimestamp(),
        },SetOptions(merge: true));

        await prefs.setString('last_fcm_token',currentToken);
        print("Token novo detectado e atualizado no Firestore! $currentToken");
      //} else {
        print("Token não mudou. Escrita no Firestore poupada. 🐘✅");
      //}
    } catch (e) {
      print("Erro ao salvar token: $e");
    }
  }
}