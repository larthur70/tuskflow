import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/auth/services/social_sign_in_flow.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_setup_controller.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_filled_button.dart';
import 'package:tuskflow/utils/space.dart';

class SocialSignInButtons extends StatefulWidget {
  const SocialSignInButtons({
    super.key,
    required this.completeOnboardingSetup,
    this.onSuccess,
    this.googleLabel = 'Continuar com Google',
    this.appleLabel = 'Continuar com Apple',
    this.googleSuccessSnackBar,
    this.appleSuccessSnackBar,
    this.showSuccessSnackBar = true,
  });

  /// When true, ensures Firestore profile + onboarding setup flag after sign-in.
  final bool completeOnboardingSetup;

  final VoidCallback? onSuccess;
  final String googleLabel;
  final String appleLabel;
  final String? googleSuccessSnackBar;
  final String? appleSuccessSnackBar;
  final bool showSuccessSnackBar;

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  bool _googleLoading = false;
  bool _appleLoading = false;

  bool get _isLoading => _googleLoading || _appleLoading;

  Future<void> _revertOnboardingLoginOnFailure() async {
    if (!widget.completeOnboardingSetup) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    await context.read<OnboardingSetupController>().reset();
  }

  /// LoginPage is pushed on the root navigator; pop it so [AuthWrapper] Home shows.
  void _leaveOnboardingLoginRoute() {
    if (!widget.completeOnboardingSetup) return;
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  Future<void> _onGoogleTap() async {
    if (_isLoading) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _googleLoading = true);
    try {
      final bool success = await runGoogleSignIn(
        context,
        completeOnboardingSetup: widget.completeOnboardingSetup,
      );
      if (!mounted) return;
      if (!success) return;

      _leaveOnboardingLoginRoute();
      if (!mounted) return;

      widget.onSuccess?.call();
      if (!mounted) return;
      if (widget.showSuccessSnackBar) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              widget.googleSuccessSnackBar ?? 'Login realizado com sucesso!',
            ),
          ),
        );
      }
    } catch (e) {
      await _revertOnboardingLoginOnFailure();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(socialSignInErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _onAppleTap() async {
    if (_isLoading) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _appleLoading = true);
    try {
      final bool success = await runAppleSignIn(
        context,
        completeOnboardingSetup: widget.completeOnboardingSetup,
      );
      if (!mounted) return;
      if (!success) return;

      _leaveOnboardingLoginRoute();
      if (!mounted) return;

      widget.onSuccess?.call();
      if (!mounted) return;
      if (widget.showSuccessSnackBar) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              widget.appleSuccessSnackBar ?? 'Login realizado com sucesso!',
            ),
          ),
        );
      }
    } catch (e) {
      await _revertOnboardingLoginOnFailure();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(socialSignInErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyFilledButton(
          backgroundColor: Colors.white,
          svgPath: 'assets/images/google.svg',
          text: _googleLoading ? 'Aguarde…' : widget.googleLabel,
          onPressed: _isLoading ? null : _onGoogleTap,
        ),
        if (showAppleSignInButton) ...[
          Space.vertical(16),
          MyFilledButton(
            backgroundColor: Colors.black,
            svgPath: 'assets/images/apple_white.svg',
            text: _appleLoading ? 'Aguarde…' : widget.appleLabel,
            textColor: Colors.white,
            onPressed: _isLoading ? null : _onAppleTap,
          ),
        ],
      ],
    );
  }
}
