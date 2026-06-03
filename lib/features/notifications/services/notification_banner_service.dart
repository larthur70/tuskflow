import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';

class NotificationBannerService {
  static const String notificationsGrantedKey = 'notifications_granted';

  Future<bool> shouldShowBanner() async {
    final granted =
        await NotificationService.instance.areNotificationsEnabled();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsGrantedKey, granted);
    return !granted;
  }

  Future<bool?> getCachedNotificationsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsGrantedKey);
  }
}
