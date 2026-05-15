
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:tuskflow/core/models/user_model.dart';
import 'package:tuskflow/core/services/user_service.dart';
import 'package:tuskflow/features/pro_analitcs/widgets/white_container.dart';
import 'package:tuskflow/utils/space.dart';

class AnaliticsPage extends StatefulWidget {
  const AnaliticsPage({super.key});

  @override
  State<AnaliticsPage> createState() => _AnaliticsPageState();
}

class _AnaliticsPageState extends State<AnaliticsPage> {
  late final Future<UserModel?> _userFuture;
  bool _interestedInPro = false;
  bool _isSubmittingInterest = false;

  @override
  void initState() {
    super.initState();
    _userFuture = context.read<UserService>().getUserData();
  }

  void _showInterestConfirmationSnackBar() {
    final colorScheme = ColorScheme.of(context);
    showTopSnackBar(
      Overlay.of(context),
      Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8),
            ],
          ),
          child: const Text(
            'Você será avisado quando as novas análises chegarem ✨',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      displayDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _onRegisterInterestTap() async {
    if (_isSubmittingInterest) return;

    setState(() => _isSubmittingInterest = true);

    final userService = context.read<UserService>();
    try {
      await userService.registerInterestInPro();
      if (!mounted) return;
      setState(() {
        _interestedInPro = true;
        _isSubmittingInterest = false;
      });
      _showInterestConfirmationSnackBar();
    } catch (err) {
      if (!mounted) return;
      setState(() => _isSubmittingInterest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar na lista: $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final user = snapshot.data;
        final earlyStartsCount = user?.earlyStartsCount ?? 0;
        final hasEarlyStarts = earlyStartsCount > 0;
        final isInterested =
            _interestedInPro || (user?.interestedInPro ?? false);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Seu Progresso",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Space.vertical(12),
                  Text(
                    "Veja como seus 5 minutos estão combatendo a procrastinação",
                    style: TextStyle(fontSize: 20),
                  ),
                  Space.vertical(32),
                  Container(
                    padding: EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      color: colorScheme.secondary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasEarlyStarts) ...[
                          Container(
                            width: 150,
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.blue.shade500,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                Space.horizontal(8),
                                Text(
                                  "STREAK INICIADA",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Space.vertical(16),
                          Row(
                            textBaseline: TextBaseline.alphabetic,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "$earlyStartsCount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 55,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              Space.horizontal(8),
                              Expanded(
                                child: Text(
                                  "Começos antecipados",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          Space.vertical(12),
                          Text(
                            "Você venceu a barreira de começar antes da última hora!",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ] else ...[
                          Text(
                            "Comece antes da pressão.",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Space.vertical(12),
                          Text(
                            "Seu contador cresce sempre que você inicia uma tarefa antes do último momento.",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                        Space.vertical(22),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade600,
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Space.vertical(24),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 30),
                      Space.horizontal(8),
                      Text(
                        "EM BREVE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Space.vertical(24),
                  WhiteContainer(
                    
                    border: Border.all(
                      color: colorScheme.secondary.withAlpha(50),
                      width: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Seu progresso está evoluindo",
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Space.vertical(12),
                        Text(
                          "Em breve, o Tusk mostrará padrões, progresso e hábitos da sua vida acadêmica.",
                          style: TextStyle(fontSize: 16),
                        ),
                        Space.vertical(12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isInterested || _isSubmittingInterest
                                ? null
                                : _onRegisterInterestTap,
                            child: _isSubmittingInterest
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isInterested
                                        ? 'Você entrou pra lista de interesse'
                                        : 'Quero testar!',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Space.vertical(32)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
