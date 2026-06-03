import 'package:flutter/material.dart';
import 'package:tuskflow/features/sessions/ui/timer_route_args.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_button.dart';
import 'package:tuskflow/utils/space.dart';

class StartFiveMinutesPage extends StatelessWidget {
  const StartFiveMinutesPage({
    super.key,
    required this.task,
  });

  final TaskModel task;

  static const String _tuskImagePath =
      'assets/images/tusk_images/tusk_estudando-Photoroom.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700;
    final titleSize = compact ? 20.0 : 24.0;
    final bodySize = compact ? 16.0 : 18.0;
    final colorScheme = ColorScheme.of(context);
    final imageSize = compact ? 200.0 : 260.0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: colorScheme.secondary),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset(
                        _tuskImagePath,
                        height: imageSize,
                        fit: BoxFit.contain,
                      ),
                      Space.vertical(compact ? 24 : 32),
                      Text(
                        'Quanto mais você demora para começar, mais preocupado fica',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Space.vertical(compact ? 12 : 16),
                      Text(
                        'Começe ${task.title} por apenas 5 minutos. Provavelmente vai parecer menor depois disso.',
                        style: TextStyle(
                          fontSize: bodySize,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Space.vertical(compact ? 12 : 16),
                    ],
                  ),
                ),
              ),
              MyButton(
                text: 'Começar por 5 minutos',
                width: double.infinity,
                fontSize: compact ? 18 : 20,
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: compact ? 14 : 16,
                ),
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/timer_page',
                    arguments: TimerRouteArgs(task: task, autoStart: true),
                  );
                },
              ),
              Space.vertical(compact ? 8 : 12),
            ],
          ),
        ),
      ),
    );
  }
}
