import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/services/auth_service.dart';
import 'package:tuskflow/core/utils/critical_operation_timeout.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_setup_controller.dart';
import 'package:tuskflow/features/onboarding/services/onboarding_setup_service.dart';

bool userHasGoogleOrAppleLinked(User? user) {
  if (user == null) return false;
  return user.providerData.any(
    (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
  );
}

/// Runs after a successful social sign-in from onboarding login.
Future<void> completeOnboardingSetupAfterSocialLogin(
  OnboardingSetupController setupController,
) async {
  final setupService = OnboardingSetupService();
  final bool ensured = await withOnboardingOperationTimeout(
    setupService.ensureMinimalUserProfile(),
  );
  if (!ensured) {
    await withOnboardingOperationTimeout(setupService.markSetupComplete());
  }
  await setupController.markComplete();

  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    unawaited(NotificationService.instance.uploadFcmToken(uid));
  }
}

/// Returns `true` when sign-in linked or recovered an account (not canceled).
Future<bool> runGoogleSignIn(
  BuildContext context, {
  required bool completeOnboardingSetup,
}) async {
  final AuthService authService = context.read<AuthService>();
  final UserCredential? credentials =
      await authService.linkOrSignInWithGoogle();

  if (!context.mounted) return false;

  final User? user = authService.auth.currentUser;
  if (credentials == null && !userHasGoogleOrAppleLinked(user)) {
    return false;
  }

  if (completeOnboardingSetup) {
    await completeOnboardingSetupAfterSocialLogin(
      context.read<OnboardingSetupController>(),
    );
  }

  return true;
}

/// Returns `true` when sign-in linked or recovered an account (not canceled).
Future<bool> runAppleSignIn(
  BuildContext context, {
  required bool completeOnboardingSetup,
}) async {
  final AuthService authService = context.read<AuthService>();
  final UserCredential? credentials =
      await authService.linkOrSignInWithApple();

  if (!context.mounted) return false;

  final User? user = authService.auth.currentUser;
  if (credentials == null && !userHasGoogleOrAppleLinked(user)) {
    return false;
  }

  if (completeOnboardingSetup) {
    await completeOnboardingSetupAfterSocialLogin(
      context.read<OnboardingSetupController>(),
    );
  }

  return true;
}

bool get showAppleSignInButton {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

String socialSignInErrorMessage(Object error) {
  if (error is UnsupportedError) {
    return 'Login com Google não está disponível neste dispositivo.';
  }
  return criticalOperationErrorMessage(error);
}
