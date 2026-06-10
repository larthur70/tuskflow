import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/models/user_model.dart';
import 'package:tuskflow/core/services/auth_service.dart';
import 'package:tuskflow/core/services/user_service.dart';
import 'package:tuskflow/features/notifications/services/notification_banner_service.dart';
import 'package:tuskflow/features/notifications/ui/notification_disabled_banner.dart';
import 'package:tuskflow/features/auth/services/social_sign_in_flow.dart';
import 'package:tuskflow/features/auth/ui/widgets/social_sign_in_buttons.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_setup_controller.dart';
import 'package:tuskflow/features/onboarding/services/onboarding_setup_service.dart';
import 'package:tuskflow/utils/space.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.embeddedInHome = false,
  });

  final bool embeddedInHome;

  static final Uri _suggestionFormUri = Uri.parse(
    'https://docs.google.com/forms/d/e/1FAIpQLSe-ETmM9FxWk_c_X2UZ9KVC_wzapCvkc-R3OiPlooxem0mr_A/viewform?usp=publish-editor',
  );

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _logoutLoading = false;
  UserModel? _firestoreUser;

  Future<void> _openSuggestionForm(BuildContext context) async {
    if (!await launchUrl(
      ProfilePage._suggestionFormUri,
      mode: LaunchMode.externalApplication,
    )) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o formulário.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFirestoreUser();
    });
  }

  Future<void> _loadFirestoreUser() async {
    if (!mounted) return;
    final data = await context.read<UserService>().getUserData();
    if (mounted) setState(() => _firestoreUser = data);
  }

  Future<void> _onSocialSignInSuccess() async {
    await _loadFirestoreUser();
    if (mounted) setState(() {});
  }

  Future<void> _onLogoutTap(BuildContext context) async {
    if (_logoutLoading) return;

    final authService = context.read<AuthService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _logoutLoading = true);
    try {
      await authService.logOut();
      await OnboardingSetupService().clearSetupComplete();
      if (mounted) {
        await context.read<OnboardingSetupController>().reset();
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao sair: $e')),
      );
    } finally {
      if (mounted) setState(() => _logoutLoading = false);
    }
  }

  Widget _buildBody(ColorScheme colorScheme) {
    final authService = context.read<AuthService>();
    final User? user = authService.auth.currentUser;

    final String? authDisplayName = user?.displayName?.trim();
    final String? firestoreDisplayName = _firestoreUser?.displayName?.trim();
    final String displayName = (authDisplayName != null && authDisplayName.isNotEmpty)
        ? authDisplayName
        : (firestoreDisplayName != null && firestoreDisplayName.isNotEmpty)
            ? firestoreDisplayName
            : 'Estudante';

    final String? authEmail = user?.email?.trim();
    final String? firestoreEmail = _firestoreUser?.email?.trim();
    final String linkedEmailLine;
    if (authEmail != null && authEmail.isNotEmpty) {
      linkedEmailLine = authEmail;
    } else if (firestoreEmail != null && firestoreEmail.isNotEmpty) {
      linkedEmailLine = firestoreEmail;
    } else if (user != null && !user.isAnonymous) {
      linkedEmailLine = 'E-mail não disponível';
    } else {
      linkedEmailLine = 'Faça login para ver seu e-mail';
    }

    final bool showSocialLoginButtons = !userHasGoogleOrAppleLinked(user);

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Space.vertical(16),
                  Text(
                    'Olá, $displayName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    linkedEmailLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  if (showSocialLoginButtons) ...[
                    Space.vertical(32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faça login para proteger seus dados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Space.vertical(8),
                          Text(
                            'Faça login para não perder seus dados em caso de desinstalação e troca de dispositivo.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                          Space.vertical(16),
                          SocialSignInButtons(
                            completeOnboardingSetup: false,
                            googleLabel: 'Logar com Google',
                            appleLabel: 'Logar com a apple',
                            googleSuccessSnackBar:
                                'Conta Google conectada com sucesso!',
                            appleSuccessSnackBar:
                                'Conta Apple conectada com sucesso!',
                            onSuccess: _onSocialSignInSuccess,
                          ),
                        ],
                      ),
                    ),
                    Space.vertical(24),
                  ] else
                    Space.vertical(8),
                  const NotificationDisabledBanner(
                    placement: NotificationBannerPlacement.profile,
                  ),
                  Space.vertical(22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openSuggestionForm(context),
                      child: const Text(
                        'Envie uma sugestão para melhorar o app',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (kDebugMode)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logoutLoading ? null : () => _onLogoutTap(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _logoutLoading ? 'Saindo…' : 'Sair (teste)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    if (widget.embeddedInHome) {
      return SafeArea(child: _buildBody(colorScheme));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
      ),
      body: SafeArea(child: _buildBody(colorScheme)),
    );
  }
}
