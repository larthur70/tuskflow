import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/tasks/controllers/task_controller.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/ui/widgets/task_card.dart';
import 'package:tuskflow/features/tasks/ui/widgets/tusk_mascot_avatar.dart';
import 'package:tuskflow/utils/space.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  final _mascotKey = GlobalKey<TuskMascotAvatarState>();
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onTaskCompleted() {
    _mascotKey.currentState?.celebrate();
    _confettiController
      ..stop()
      ..play();
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final taskStream = taskController.taskStream;
    final uidKey =
        FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 40,
            left: 20,
            right: 20,
            bottom: 16,
          ),
          child: StreamBuilder(
            key: ValueKey<String>('${uidKey}_${taskController.streamGeneration}'),
            stream: taskStream,
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              if (snapshot.hasError) {
                print(snapshot.error);
                return const Center(child: Text("Erro ao carregar dados."));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (tasks.isEmpty) {
                return _buildEmptyState();
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: tasks.length == 1
                    ? _buildUniqueTaskLayout(tasks.first)
                    : _buildListLayout(tasks),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 112, right: 92),
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 18,
              gravity: 0.2,
              maxBlastForce: 18,
              minBlastForce: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/tusk_images/tusk_placeholder.png',
            width: 220,
          ),
          Space.vertical(32),
          Text(
            'Sem tarefas pendentes! Agora é só curtur',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniqueTaskLayout(TaskModel task) {
    return LayoutBuilder(
      key: const ValueKey('unique'),
      builder: (context, _) {
        final compact = MediaQuery.sizeOf(context).height < 700;
        final headlineSize = compact ? 26.0 : 32.0;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Sua tarefa está pronta para ser começada!",
                style: TextStyle(
                  fontSize: headlineSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Space.vertical(compact ? 8 : 12),
              Text(
                "Inicie por 5 minutos e vença a procrastinação!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              Space.vertical(compact ? 20 : 32),
              TaskCard(
                task: task,
                unique: true,
                onTaskCompleted: _onTaskCompleted,
              ),
              Space.vertical(compact ? 16 : 24),
              Text(
                '"O segredo é apenas começar. Pequenos passos geram grandes conquistas"',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListLayout(List<TaskModel> tasks) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Olá, Estudante!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  "O que temos\npara hoje?",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            TuskMascotAvatar(key: _mascotKey),
          ],
        ),
        Space.vertical(24),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) {
              return Space.vertical(16);
            },
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                key: ValueKey(task.id),
                unique: false,
                onTaskCompleted: _onTaskCompleted,
              );
            },
          ),
        ),
      ],
    );
  }
}
