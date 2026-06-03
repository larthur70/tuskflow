import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';

enum NotificationBannerPlacement { home, profile }

class NotificationBannerService {
  static const String notificationsGrantedKey = 'notifications_granted';
  static const String homePageVisitCountKey = 'notification_banner_home_visits';
  static const int maxHomeBannerVisits = 3;

  Future<void> recordHomePageVisit() async {
    final granted =
        await NotificationService.instance.areNotificationsEnabled();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsGrantedKey, granted);
    if (granted) {
      await prefs.remove(homePageVisitCountKey);
      return;
    }

    final count = prefs.getInt(homePageVisitCountKey) ?? 0;
    await prefs.setInt(homePageVisitCountKey, count + 1);
  }

  Future<bool> shouldShowBanner(NotificationBannerPlacement placement) async {
    final granted =
        await NotificationService.instance.areNotificationsEnabled();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsGrantedKey, granted);
    if (granted) return false;

    final count = prefs.getInt(homePageVisitCountKey) ?? 0;
    return switch (placement) {
      NotificationBannerPlacement.home => count <= maxHomeBannerVisits,
      NotificationBannerPlacement.profile => count > maxHomeBannerVisits,
    };
  }

  Future<bool?> getCachedNotificationsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsGrantedKey);
  }
}
