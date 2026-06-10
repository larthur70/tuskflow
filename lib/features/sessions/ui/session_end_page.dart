import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:tuskflow/core/utils/system_ui_config.dart';
import 'package:tuskflow/features/sessions/ui/widgets/congrats_card.dart';
import 'package:tuskflow/features/sessions/ui/widgets/looping_asset_video.dart';
import 'package:tuskflow/utils/space.dart';

class SessionEndPage extends StatefulWidget {
  const SessionEndPage({super.key});

  @override
  State<SessionEndPage> createState() => _SessionEndPageState();
}

class _SessionEndPageState extends State<SessionEndPage> {
  late ConfettiController _confettiController;

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _confettiController.play();
  }

  String _formatMinutes(int seconds) {
    final int minutes = seconds ~/ 60;
    return minutes == 1 ? '1 minuto' : '$minutes minutos';
  }

  Widget _buildContent({required int duration}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            width: 200,
            child: const LoopingAssetVideo(
              assetPath: 'assets/images/tusk_images/succes_gif.mp4',
              width: 180,
            ),
          ),
        ),
        Space.vertical(24),
        const Text(
          'O mais difícil você já fez, começou! Parabéns',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        Space.vertical(24),
        Row(
          children: [
            CongratsCard(
              icon: Icon(Icons.lock_clock, size: 30, color: Colors.blue),
              title: 'DURAÇÃO',
              subtitle: _formatMinutes(duration),
              border: const Border(
                left: BorderSide(width: 4, color: Colors.blue),
                right: BorderSide(width: 4, color: Colors.blue),
              ),
            ),
          ],
        ),
        Space.vertical(32),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text(
              'Voltar para tarefas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Space.vertical(24),
        Text(
          'Tem mais alguma tarefa, prova ou trabalho ocupando espaço na sua cabeça?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final int duration = args?['duration'] as int? ?? 0;
    final colorScheme = ColorScheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sessão Concluída',
          style: TextStyle(color: colorScheme.primary),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
          icon: Icon(Icons.close, color: colorScheme.primary),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + bottomViewInset(context),
              ),
              child: _buildContent(duration: duration),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
          ),
        ],
      ),
    );
  }
}
