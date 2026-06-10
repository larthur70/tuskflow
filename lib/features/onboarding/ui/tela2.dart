import 'package:flutter/material.dart';
import 'package:tuskflow/features/tasks/ui/widgets/manual_creation.dart';
import 'package:tuskflow/utils/space.dart';

class Tela2 extends StatefulWidget {
  final TextEditingController dateController;
  final TextEditingController titleController;
  final Function(DateTime?) onDateSelected;
  final GlobalKey<FormState> formKey;

  const Tela2({
    super.key,
    required this.formKey,
    required this.dateController,
    required this.titleController,
    required this.onDateSelected,
  });

  @override
  State<Tela2> createState() => _Tela2State();
}

class _Tela2State extends State<Tela2> {
  final ScrollController _scrollController = ScrollController();

  static const String _defaultTitle = 'Trabalho de anatomia';

  @override
  void initState() {
    super.initState();
    _applyDefaultTaskIfEmpty();
  }

  void _applyDefaultTaskIfEmpty() {
    if (widget.titleController.text.isEmpty) {
      widget.titleController.text = _defaultTitle;
    }
    if (widget.dateController.text.isEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      widget.dateController.text =
          '${today.day} / ${today.month} / ${today.year}';
      widget.onDateSelected(today);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final titleSize = compact ? 22.0 : 26.0;

    return SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vamos tirar uma preocupação da sua cabeça.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: keyboardOpen ? 20 : titleSize,
            ),
          ),
          if (!keyboardOpen) ...[
            Space.vertical(compact ? 12 : 16),
            Text(
              'Cadastre uma tarefa da faculdade e eu vou te lembrar antes que ela vire um problema.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            Space.vertical(compact ? 20 : 32),
          ] else
            Space.vertical(12),
          ManualCreation(
            titleController: widget.titleController,
            dateController: widget.dateController,
            formKey: widget.formKey,
            onDateSelected: widget.onDateSelected,
            onFieldFocused: _scrollToForm,
          ),
          Space.vertical(24),
        ],
      ),
    );
  }
}
