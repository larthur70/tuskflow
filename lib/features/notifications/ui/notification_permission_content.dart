import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';

Future<void> markNotificationPromptHandledAndRequestSystemPermission() async {
  await NotificationService.instance.markNotificationPromptHandled();
  await NotificationService.instance.requestSystemNotificationPermission();
}

Future<void> uploadFcmTokenIfSignedIn() async {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    unawaited(NotificationService.instance.uploadFcmToken(uid));
  }
}

/// User tapped allow / understood — logs acceptance, then OS permission dialog.
Future<void> acceptNotificationPermission(BuildContext context) async {
  unawaited(context.read<AnalyticsService>().logNotificationAccepted());
  await markNotificationPromptHandledAndRequestSystemPermission();
  await uploadFcmTokenIfSignedIn();
}
