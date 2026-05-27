import 'package:flutter/material.dart';
import 'package:tuskflow/features/auth/ui/widgets/social_sign_in_buttons.dart';
import 'package:tuskflow/utils/space.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const String _tuskImagePath =
      'assets/images/tusk_images/tusk_login.png';

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final compactHeight = size.height < 700;
    final compactWidth = size.width < 360;
    final compact = compactHeight || compactWidth;
    final imageSize = compactHeight
        ? 160.0
        : compactWidth
            ? 180.0
            : 220.0;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: colorScheme.secondary),
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Space.vertical(compactHeight ? 16 : 32),
                      Text(
                        'Entre com a sua conta',
                        style: TextStyle(
                          fontSize: compact ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Space.vertical(12),
                      Text(
                        'Use a mesma conta Google ou Apple que você já usou no Tusk.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Space.vertical(compact ? 24 : 40),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.asset(
                          _tuskImagePath,
                          height: imageSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SocialSignInButtons(
                completeOnboardingSetup: true,
                showSuccessSnackBar: false,
              ),
              Space.vertical(compactHeight ? 16 : 24),
              Text(
                'Primeira vez aqui? Volte e toque em Vamos Começar.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
