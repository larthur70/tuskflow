import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:tuskflow/app.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message)async{
  if(Firebase.apps.isEmpty){
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  
  print('Handling a background message: ${message.messageId}');
}

void main()async{
  
  WidgetsFlutterBinding.ensureInitialized();

  if(Firebase.apps.isEmpty){
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    );
  }
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  NotificationService().initialize();

    const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await FlutterLocalNotificationsPlugin().initialize(settings: initializationSettings);
  
  runApp(App());
}