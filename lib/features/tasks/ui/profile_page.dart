import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/models/user_model.dart';
import 'package:tuskflow/core/services/auth_service.dart';
import 'package:tuskflow/core/services/user_service.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_filled_button.dart';
import 'package:tuskflow/utils/space.dart';
import 'package:url_launcher/url_launcher.dart';

bool _userHasGoogleOrAppleLinked(User? user) {
  if (user == null) return false;
  return user.providerData.any(
    (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static final Uri _suggestionEmailUri = Uri(
    scheme: 'mailto',
    path: 'luizarthurbolzani@gmail.com',
    queryParameters: {'subject': 'Sugestão TuksFlow'},
  );

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _googleLoading = false;
  bool _appleLoading = false;
  UserModel? _firestoreUser;

  Future<void> _openSuggestionEmail(BuildContext context) async {
    if (!await launchUrl(ProfilePage._suggestionEmailUri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o e-mail.')),
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

  Future<void> _onAppleTap(BuildContext context) async {
    if (_appleLoading) return;

    final AuthService authService = context.read<AuthService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _appleLoading = true);
    try {
      final credentials = await authService.linkOrSignInWithApple();

      if (!mounted) return;

      if (credentials == null &&
          authService.auth.currentUser?.isAnonymous == true) {
        return;
      }

      await _loadFirestoreUser();

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Conta Apple conectada com sucesso!'),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao conectar Apple: $e')),
      );
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  Future<void> _onGoogleTap(BuildContext context) async {
    if (_googleLoading) return;

    final AuthService authService = context.read<AuthService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _googleLoading = true);
    try {
      final credentials = await authService.linkOrSignInWithGoogle();

      if (!mounted) return;

      if (credentials == null &&
          authService.auth.currentUser?.isAnonymous == true) {
        return;
      }

      await _loadFirestoreUser();

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Conta Google conectada com sucesso!'),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao conectar Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final User? user = authService.auth.currentUser;
    final colorScheme = ColorScheme.of(context);

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

    final bool showSocialLoginButtons = !_userHasGoogleOrAppleLinked(user);

    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 16),
        centerTitle: false,
        title: Text(
          "Perfil",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Space.vertical(16),
                    Text(
                      "Olá, $displayName",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      linkedEmailLine,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    if (showSocialLoginButtons) ...[
                      Space.vertical(32),
                      Space.vertical(32),
                      MyFilledButton(
                        backgroundColor: Colors.black,
                        svgPath: "assets/images/apple_white.svg",
                        text: _appleLoading ? "Aguarde…" : "Logar com a apple",
                        textColor: Colors.white,
                        onPressed: _appleLoading || _googleLoading
                            ? null
                            : () => _onAppleTap(context),
                      ),
                      Space.vertical(16),
                      MyFilledButton(
                        backgroundColor: Colors.white,
                        svgPath: "assets/images/google.svg",
                        text: _googleLoading ? "Aguarde…" : "Logar com Google",
                        onPressed: _googleLoading || _appleLoading
                            ? null
                            : () => _onGoogleTap(context),
                      ),
                      Space.vertical(24),
                    ] else
                      Space.vertical(8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("AÇÕES DA CONTA"),
                        Space.vertical(8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.read<AuthService>().logOut();
                                },
                                child: ListTile(
                                  leading: Icon(Icons.restore),
                                  title: Text("Restaurar compra"),
                                  trailing: Icon(Icons.arrow_right),
                                ),
                              )
                            ],
                          ),
                        ),
                        Space.vertical(24),
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
                                'Não lute sozinho contra a procrastinação 🔔',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Space.vertical(8),
                              Text(
                                'As notificações fazem parte do método do Tusk. Elas ajudam você a lembrar da tarefa no momento certo e facilitam começar antes da pressão chegar. Mantenha-as ativas para aproveitar a experiência completa.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Space.vertical(22),
                    SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _openSuggestionEmail(context),
                child: const Text(
                  'Envie uma sugestão para melhorar o app',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
                  ],
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
