import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';

/// Tracks local calendar-day app opens to fire [user_returned] on a new day.
class AppOpenTrackingService {
  static const String _lastAppOpenLocalDateKey = 'last_app_open_local_date';

  Future<void> recordAppOpen(AnalyticsService analytics) async {
    final prefs = await SharedPreferences.getInstance();
    final String today = _formatLocalDate(DateTime.now());
    final String? lastOpen = prefs.getString(_lastAppOpenLocalDateKey);

    if (lastOpen != null && lastOpen != today) {
      await analytics.logUserReturned();
    }

    await prefs.setString(_lastAppOpenLocalDateKey, today);
  }

  static String _formatLocalDate(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}
