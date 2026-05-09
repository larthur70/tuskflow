import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:tuskflow/features/sessions/ui/widgets/congrats_card.dart';
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
    // TODO: implement dispose
    super.dispose();
    _confettiController.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    final int duration = args['duration'] ?? 0;
    final int streak = args['streak'] ?? 0;

    String formatMinutes(int seconds) {
      final int minutes = seconds ~/ 60;
      return minutes == 1 ? "1 minuto" : "$minutes minutos";
    }

    final colorScheme = ColorScheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sessão Concluíuda",
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    width: 200,
                    child: Image.asset(
                      "assets/images/tusk_images/succes_gif.gif",
                    ),
                  ),
                  Space.vertical(24),
                  Text(
                    "Parabéns! você começou 🎉",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                  ),
                  Text(
                    "Você fez o mais difícil: começar. Continue assim, você está criando consistência",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  Space.vertical(24),
                  Row(
                    children: [
                      CongratsCard(
                        icon: Icon(
                          Icons.lock_clock,
                          size: 30,
                          color: Colors.blue,
                        ),
                        title: "DURAÇÃO",
                        subtitle: formatMinutes(duration),
                        border: Border(
                          left: BorderSide(width: 4, color: Colors.blue),
                        ),
                      ),
                      Space.horizontal(12),
                      CongratsCard(
                        icon: Icon(
                          Icons.local_fire_department,
                          size: 30,
                          color: Colors.red,
                        ),
                        title: "STREAK",
                        subtitle: "$streak",
                        border: Border(
                          right: BorderSide(color: Colors.red, width: 4),
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
                      child: Text(
                        "Voltar para tarefas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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
        ),
      ),
    );
  }
}
