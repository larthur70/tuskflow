import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/utils/space.dart';

Future<void> showNotificationPermissionBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/tusk_images/tusk_notification.png',
                height: 180,
                fit: BoxFit.contain,
              ),
              Space.vertical(20),
              Text(
                'Não seja pego de surpresa. 🐘',
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Space.vertical(8),
              Text(
                'O Tusk avisa quando trabalhos, provas e tarefas precisam da sua atenção, antes que elas virem uma preocupação.',
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.4,
                    ),
              ),
              Space.vertical(28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _onAllowNotifications(sheetContext),
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  child: const Text(
                    'Permitir notificações',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Space.vertical(12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _onDismiss(sheetContext),
                  child: const Text(
                    'Agora não',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _onAllowNotifications(BuildContext context) async {
  unawaited(context.read<AnalyticsService>().logNotificationAccepted());
  Navigator.of(context).pop();
  await NotificationService.instance.markNotificationPromptHandled();
  await NotificationService.instance.requestSystemNotificationPermission();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    unawaited(NotificationService.instance.uploadFcmToken(uid));
  }
}

Future<void> _onDismiss(BuildContext context) async {
  unawaited(context.read<AnalyticsService>().logNotificationDeclined());
  await NotificationService.instance.markNotificationPromptHandled();
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}
