import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/services/auth_service.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_setup_controller.dart';
import 'package:tuskflow/features/onboarding/ui/onboarding_page.dart';
import 'package:tuskflow/features/tasks/ui/home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder(
      stream: auth.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const OnBoardingPage();
        }
        return const _AuthenticatedGate();
      },
    );
  }
}

class _AuthenticatedGate extends StatefulWidget {
  const _AuthenticatedGate();

  @override
  State<_AuthenticatedGate> createState() => _AuthenticatedGateState();
}

class _AuthenticatedGateState extends State<_AuthenticatedGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSetup());
  }

  Future<void> _resolveSetup() async {
    if (!mounted) return;
    context.loaderOverlay.hide();
    await context.read<OnboardingSetupController>().loadAndRecoverIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final setup = context.watch<OnboardingSetupController>();

    if (!setup.isInitialized || setup.isResolving) {
      return const _OnboardingPreparingScreen();
    }

    if (!setup.isComplete) {
      return const _OnboardingPreparingScreen();
    }

    return const HomePage();
  }
}

class _OnboardingPreparingScreen extends StatefulWidget {
  const _OnboardingPreparingScreen();

  @override
  State<_OnboardingPreparingScreen> createState() =>
      _OnboardingPreparingScreenState();
}

class _OnboardingPreparingScreenState extends State<_OnboardingPreparingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.loaderOverlay.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Preparando sua conta…',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
