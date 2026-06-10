import 'package:flutter/material.dart';
import 'package:tuskflow/features/sessions/ui/widgets/looping_asset_video.dart';
import 'package:tuskflow/utils/space.dart';

class Tela1 extends StatelessWidget {
  const Tela1({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compactHeight = size.height < 700;
    final compactWidth = size.width < 360;
    final compact = compactHeight || compactWidth;

    final videoHeight = compactHeight
        ? 180.0
        : compactWidth
            ? 200.0
            : 250.0;
    final videoMaxWidth = size.width * (compact ? 0.78 : 0.82);
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
                constraints: BoxConstraints(maxWidth: videoMaxWidth),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: LoopingAssetVideo(
                    assetPath: 'assets/images/tusk_images/onboarding.mp4',
                    height: videoHeight,
                  ),
                ),
              ),
            ),
            Space.vertical(sectionGap),
            Text(
              'Nunca mais seja pego de surpresa por trabalhos e provas.',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Space.vertical(compact ? 16 : 24),
            Text(
              'O Tusk acompanha seus prazos e te avisa antes que eles virem um problema. 🐘',
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
