import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:tuskflow/features/analytics/analytics_events.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  Future<void> logTaskCreated() =>
      _safeLog(AnalyticsEvents.taskCreated);

  Future<void> logTaskCompleted() =>
      _safeLog(AnalyticsEvents.taskCompleted);

  Future<void> logTimer5MinStart() =>
      _safeLog(AnalyticsEvents.timer5MinStart);

  Future<void> logTimer5MinSuccess() =>
      _safeLog(AnalyticsEvents.timer5MinSuccess);

  Future<void> logSessionExtended15Min() =>
      _safeLog(AnalyticsEvents.sessionExtended15Min);

  Future<void> logNotificationAccepted() =>
      _safeLog(AnalyticsEvents.notificationAccepted);

  Future<void> logNotificationDeclined() =>
      _safeLog(AnalyticsEvents.notificationDeclined);

  Future<void> logNotificationClicked() =>
      _safeLog(AnalyticsEvents.notificationClicked);

  Future<void> logUserReturned() =>
      _safeLog(AnalyticsEvents.userReturned);

  Future<void> logProgressScreenOpened() =>
      _safeLog(AnalyticsEvents.progressScreenOpened);

  Future<void> logStartFiveMinutesStartTapped() =>
      _safeLog(AnalyticsEvents.startFiveMinutesStartTapped);

  Future<void> logStartFiveMinutesCloseTapped() =>
      _safeLog(AnalyticsEvents.startFiveMinutesCloseTapped);

  Future<void> _safeLog(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e, st) {
      debugPrint('AnalyticsService.logEvent($name): $e\n$st');
    }
  }
}
