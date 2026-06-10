import 'package:flutter/material.dart';
import 'package:tuskflow/utils/space.dart';

class TelaNotificacoes extends StatelessWidget {
  const TelaNotificacoes({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compactHeight = size.height < 700;
    final compactWidth = size.width < 360;
    final compact = compactHeight || compactWidth;

    final imageHeight = compactHeight
        ? 160.0
        : compactWidth
            ? 180.0
            : 200.0;
    final imageMaxWidth = size.width * (compact ? 0.78 : 0.82);
    final titleSize = compact ? 22.0 : 26.0;
    final bodySize = compact ? 16.0 : 18.0;
    final sectionGap = compact ? 20.0 : 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: imageMaxWidth),
                      child: Image.asset(
                        'assets/images/tusk_images/tusk_notification.png',
                        height: imageHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Space.vertical(sectionGap),
                  Text(
                    'Para isso funcionar, preciso te avisar quando algo estiver chegando.',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Space.vertical(compact ? 16 : 24),
                  Text(
                    'Sem notificações, o Tusk não consegue cumprir sua principal função: evitar que você esqueça prazos importantes.',
                    style: TextStyle(
                      fontSize: bodySize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
