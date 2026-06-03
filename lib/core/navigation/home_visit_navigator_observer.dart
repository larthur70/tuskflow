import 'package:flutter/material.dart';
import 'package:tuskflow/features/notifications/services/notification_banner_service.dart';

/// Tracks real HomePage visits, ignoring modal overlays (bottom sheets, dialogs).
class HomeVisitNavigatorObserver extends NavigatorObserver {
  HomeVisitNavigatorObserver({this.onHomeVisitRecorded});

  final VoidCallback? onHomeVisitRecorded;

  bool _visitRecordedForCurrentHomeDisplay = false;

  static bool _isHomeRoute(Route<dynamic>? route) {
    if (route == null) return false;
    return route.settings.name == '/' || route.isFirst;
  }

  static bool _isOverlayRoute(Route<dynamic> route) => route is PopupRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isHomeRoute(route)) {
      _recordHomeVisit();
      return;
    }
    if (_isHomeRoute(previousRoute) && !_isOverlayRoute(route)) {
      _visitRecordedForCurrentHomeDisplay = false;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isHomeRoute(previousRoute) && !_isOverlayRoute(route)) {
      _recordHomeVisit();
    }
  }

  Future<void> _recordHomeVisit() async {
    if (_visitRecordedForCurrentHomeDisplay) return;
    _visitRecordedForCurrentHomeDisplay = true;
    await NotificationBannerService().recordHomePageVisit();
    onHomeVisitRecorded?.call();
  }
}
