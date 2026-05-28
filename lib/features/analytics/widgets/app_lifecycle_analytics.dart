import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';
import 'package:tuskflow/features/analytics/services/app_open_tracking_service.dart';

/// Fires retention analytics whenever the app is opened (lifecycle resumed).
class AppLifecycleAnalytics extends StatefulWidget {
  const AppLifecycleAnalytics({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleAnalytics> createState() => _AppLifecycleAnalyticsState();
}

class _AppLifecycleAnalyticsState extends State<AppLifecycleAnalytics>
    with WidgetsBindingObserver {
  final AppOpenTrackingService _appOpenTracking = AppOpenTrackingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recordAppOpen();
    }
  }

  void _recordAppOpen() {
    if (!mounted) return;
    unawaited(
      _appOpenTracking.recordAppOpen(context.read<AnalyticsService>()),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
