/// Firebase Analytics custom event names (snake_case, max 40 chars).
abstract final class AnalyticsEvents {
  static const String taskCreated = 'task_created';
  static const String timer5MinStart = 'timer_5min_start';
  static const String timer5MinSuccess = 'timer_5min_success';
  static const String sessionExtended15Min = 'session_extended_15min';
  static const String notificationAccepted = 'notification_accepted';
  static const String notificationDeclined = 'notification_declined';
  static const String notificationClicked = 'notification_clicked';
  static const String userReturned = 'user_returned';
}
