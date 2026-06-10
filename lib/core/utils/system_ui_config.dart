import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android edge-to-edge only — iOS handles safe areas natively via [SafeArea].
Future<void> configureSystemUi() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
}

/// System UI inset at the bottom (nav bar / home indicator).
double bottomViewInset(BuildContext context) {
  return MediaQuery.viewPaddingOf(context).bottom;
}

/// Minimal scroll padding so last items clear the center-docked FAB.
/// Body already sits above [BottomNavigationBar] — do not pad for tab bar height.
const double kHomeFabScrollPadding = 32.0;
