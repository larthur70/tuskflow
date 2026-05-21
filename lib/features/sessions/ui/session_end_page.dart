import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
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
    return minutes == 1 ? "1 minuto" : "$minutes minutos";
  }

  Widget _buildContent({
    required String headline,
    required String? subtitle,
    required bool isEarlyStart,
    required int duration,
    required int earlyStartsCount,
  }) {
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
        Text(
          headline,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        if (subtitle != null) ...[
          Space.vertical(12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
        Space.vertical(24),
        if (isEarlyStart)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CongratsCard(
                icon: Icon(Icons.lock_clock, size: 30, color: Colors.blue),
                title: "DURAÇÃO",
                subtitle: _formatMinutes(duration),
                border: const Border(
                  left: BorderSide(width: 4, color: Colors.blue),
                ),
              ),
              Space.horizontal(12),
              CongratsCard(
                icon: Icon(
                  Icons.local_fire_department,
                  size: 30,
                  color: Colors.orange,
                ),
                title: "COMEÇOS\nANTECIPADOS",
                titleFontSize: 11,
                subtitle: "$earlyStartsCount",
                subtitleFontSize: 22,
                border: const Border(
                  right: BorderSide(color: Colors.orange, width: 4),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              CongratsCard(
                icon: Icon(Icons.lock_clock, size: 30, color: Colors.blue),
                title: "DURAÇÃO",
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
              Navigator.pop(context);
            },
            child: const Text(
              "Voltar para tarefas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
    final bool isEarlyStart = args?['isEarlyStart'] as bool? ?? false;
    final int earlyStartsCount = args?['earlyStartsCount'] as int? ?? 0;

    final String headline = isEarlyStart
        ? "Parabéns, você agiu antes da hora final, está evoluindo!"
        : "O mais difícil você já fez, começou! Parabéns";

    final String? subtitle = isEarlyStart
        ? "Cada começo antecipado fortalece seu hábito de agir com antecedência."
        : null;

    final colorScheme = ColorScheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sessão Concluída",
          style: TextStyle(color: colorScheme.primary),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.close, color: colorScheme.primary),
        ),
      ),
      body: Stack(
        children: [
          if (isEarlyStart)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContent(
                headline: headline,
                subtitle: subtitle,
                isEarlyStart: isEarlyStart,
                duration: duration,
                earlyStartsCount: earlyStartsCount,
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(
                  headline: headline,
                  subtitle: subtitle,
                  isEarlyStart: isEarlyStart,
                  duration: duration,
                  earlyStartsCount: earlyStartsCount,
                ),
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
