import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/core/utils/critical_operation_timeout.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_controller.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_setup_controller.dart';
import 'package:tuskflow/features/auth/ui/login_page.dart';
import 'package:tuskflow/features/notifications/ui/notification_permission_content.dart';
import 'package:tuskflow/features/onboarding/ui/tela1.dart';
import 'package:tuskflow/features/onboarding/ui/tela_notificacoes.dart';
import 'package:tuskflow/features/onboarding/ui/tela2.dart';
import 'package:tuskflow/features/sessions/services/first_timer_tips_service.dart';
import 'package:tuskflow/utils/space.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  DateTime? dueDate;
  
  int currentPage = 0;
  final PageController _controller = PageController();
 

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    dateController.dispose();
    titleController.dispose();
    super.dispose();
    
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
   
  }

  Future<void> exitOnboarding(bool allFlux)async{
    final title = titleController.text;
    final overlay = context.loaderOverlay;
    final onboardingController = context.read<OnboardingController>();
    final setupController = context.read<OnboardingSetupController>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    if(allFlux && dueDate == null) return;
    
    overlay.show();
    setupController.beginOnboardingExit();
    try {
      await onboardingController.initializeUser(
        completedOnboarding: allFlux,
        title: title,
        dueDate: dueDate,
      );

      await setupController.markComplete();

      if (allFlux) {
        await FirstTimerTipsService().markPendingTipsSheetAfterLogin();
      }

      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(NotificationService.instance.uploadFcmToken(uid));
      }
    } catch (err) {
      debugPrint('erro no onboarding $err');
      if (FirebaseAuth.instance.currentUser != null) {
        await NotificationService.instance.removeCurrentDeviceToken();
        await FirebaseAuth.instance.signOut();
        await setupController.reset();
      }
      messenger?.showSnackBar(
        SnackBar(content: Text(criticalOperationErrorMessage(err))),
      );
    } finally {
      setupController.endOnboardingExit();
      // Must hide even when unmounted: sign-in rebuilds AuthWrapper and
      // disposes this page while the GlobalLoaderOverlay is still visible.
      overlay.hide();
    }
    
  }

  void _openLoginPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _onNotificationContinue() async {
    await acceptNotificationPermission(context);
    if (!mounted) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _onNotificationBack() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _onTaskPageBack() {
    FocusScope.of(context).unfocus();
    _controller.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildBackButton(ColorScheme colorScheme, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Voltar',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPage1Actions(ColorScheme colorScheme) {
    final continueButton = FilledButton(
      onPressed: _onNotificationContinue,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
      ),
      child: const Text(
        'Entendi',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBackButton(colorScheme, _onNotificationBack),
          const SizedBox(width: 8),
          continueButton,
        ],
      ),
    );
  }

  Widget _buildPage2Actions(ColorScheme colorScheme) {
    final createButton = FilledButton(
      onPressed: () {
        final validate = formKey.currentState!.validate();
        if (!validate) return;
        exitOnboarding(true);
      },
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
      ),
      child: const Text(
        'Criar tarefa',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBackButton(colorScheme, _onTaskPageBack),
          const SizedBox(width: 8),
          createButton,
        ],
      ),
    );
  }

  Widget _buildPage0Actions(ColorScheme colorScheme) {
    final compactHeight = MediaQuery.sizeOf(context).height < 700;

    final startButton = FilledButton(
      onPressed: () {
        _controller.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      },
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vamos Começar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: compactHeight ? 16 : 18,
            ),
          ),
          Space.horizontal(4),
          const Icon(Icons.keyboard_arrow_right, size: 24),
        ],
      ),
    );

    final knownUserButton = TextButton(
      onPressed: _openLoginPage,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Já conheço o Tusk',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
          fontSize: compactHeight ? 14 : 16,
        ),
      ),
    );

    // Side by side when wide enough: "Já conheço" left, "Vamos Começar" right.
    // Otherwise stack with primary CTA on top (right-aligned), link below.
    const sideBySideMinWidth = 340.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= sideBySideMinWidth;

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: knownUserButton),
              const SizedBox(width: 8),
              startButton,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerRight, child: startButton),
            knownUserButton,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'TuskFlow',
          style: TextStyle(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: keyboardOpen ? 8 : 16,
          ),
          child: Column(
           
            children: [
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  controller: _controller,
                  children: [
                    const Tela1(),
                    const TelaNotificacoes(),
                    Tela2(
                      formKey: formKey,
                      dateController: dateController,
                      titleController: titleController,
                      onDateSelected: (selectedDate) {
                        dueDate = selectedDate;
                      },
                    ),
                  ],
                ),
              ),
              if (currentPage == 0)
                _buildPage0Actions(colorScheme)
              else if (currentPage == 1)
                _buildPage1Actions(colorScheme)
              else
                _buildPage2Actions(colorScheme),
              if (!keyboardOpen) ...[
                Space.vertical(8),
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: ExpandingDotsEffect(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}