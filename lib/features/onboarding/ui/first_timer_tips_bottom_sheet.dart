import 'package:flutter/material.dart';
import 'package:tuskflow/features/onboarding/ui/tela3.dart';
import 'package:tuskflow/features/sessions/services/first_timer_tips_service.dart';

Future<void> showFirstTimerTipsBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.9;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => _onDismiss(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: const Tela3(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _onDismiss(sheetContext),
                    child: const Text(
                      'Entendi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _onDismiss(BuildContext context) async {
  await FirstTimerTipsService().markTipsSheetShown();
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}
