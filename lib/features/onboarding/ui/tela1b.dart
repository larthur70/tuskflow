import 'package:flutter/material.dart';
import 'package:tuskflow/utils/space.dart';

class Tela1b extends StatelessWidget {
  const Tela1b({super.key});

  static const String _tuskImagePath =
      'assets/images/tusk_images/tusk_juiz_2.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compactHeight = size.height < 700;
    final compactWidth = size.width < 360;
    final compact = compactHeight || compactWidth;

    final imageHeight = compactHeight
        ? 180.0
        : compactWidth
            ? 200.0
            : 250.0;
    final imageMaxWidth = size.width * (compact ? 0.78 : 0.82);
    final titleSize = compact ? 22.0 : 26.0;
    final bodySize = compact ? 16.0 : 18.0;
    final sectionGap = compact ? 20.0 : 32.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: imageMaxWidth),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    _tuskImagePath,
                    height: imageHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Space.vertical(sectionGap),
            Text(
              'Vamos usar a regra dos 5 minutos⏳',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Space.vertical(compact ? 16 : 24),
            Text(
              'Quando você começa uma tarefa por 5 minutos, a chance de pegar embalo e continuar é muito grande',
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
    );
  }
}
