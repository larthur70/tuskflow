
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuskflow/core/utils/critical_operation_timeout.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/sessions/controller/timer_controller.dart';
import 'package:tuskflow/features/sessions/services/firestore_session_service.dart';
import 'package:tuskflow/features/sessions/services/timer_persistence_service.dart';
import 'package:tuskflow/features/sessions/ui/widgets/control_timer_button.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';

import 'package:tuskflow/utils/space.dart';

class TimerPage extends StatefulWidget {
  final TaskModel task;
  final bool autoStart;

  const TimerPage({
    super.key,
    required this.task,
    this.autoStart = true,
  });

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final timerController = context.read<TimerController>();
      timerController.setTask(widget.task);
      await TimerPersistenceService().saveActiveTaskSnapshot(widget.task);
      final bool restored = await timerController.restoreSession();

      if ((!restored || widget.autoStart) && !timerController.isRuning) {
        timerController.startTimer();
      }
    });
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // TODO: implement dispose

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final timerController = context.read<TimerController>();
    switch (state) {
      case AppLifecycleState.resumed:
        timerController.onAppResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        timerController.onAppBackgrounded();
      default:
        break;
    }
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _navigateToSessionSuccess({
    required int durationSeconds,
    required bool syncedOnline,
  }) async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    await navigator.pushReplacementNamed(
      '/succes_page',
      arguments: {
        'duration': durationSeconds,
      },
    );

    if (!syncedOnline && messenger != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text(offlineSessionSyncSnackbarMessage)),
      );
    }
  }

  Future<void> finishSession() async {
    final timerController = context.read<TimerController>();
    final int finalRealTempo = timerController.getElapsedSeconds();
    final loader = context.loaderOverlay;

    loader.show();
    final batch = FirebaseFirestore.instance.batch();
    Object? syncError;
    try {
      await timerController.cancelTimer();

      if (!widget.task.initialized) {
        await context.read<FirestoreTaskService>().inicializeTask(
          widget.task.id,
          batch: batch,
        );
      }
      await context.read<FirestoreSessionService>().createSession(
        task: widget.task,
        durationSeconds: finalRealTempo,
        continuedBeyond5min: finalRealTempo > 300,
        batch: batch,
      );

      try {
        await withCriticalOperationTimeout(batch.commit());
      } catch (err) {
        if (!isCriticalOperationOfflineError(err)) rethrow;
        syncError = err;
        try {
          await batch.commit();
        } catch (retryErr) {
          debugPrint('Offline batch commit retry: $retryErr');
        }
      }

      loader.hide();
      await _navigateToSessionSuccess(
        durationSeconds: finalRealTempo,
        syncedOnline: syncError == null,
      );
    } catch (err) {
      debugPrint('Erro ao finalizar sessão: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(criticalOperationErrorMessage(err))),
        );
      }
    } finally {
      if (mounted) loader.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerController = context.watch<TimerController>();
    final progress = timerController.isCrescentTimer
        ? 1.0
        : (1 - (timerController.actualSeconds / 300)).clamp(0.0, 1.0);
    final colorScheme = ColorScheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              if (timerController.isCrescentTimer)
                Text(
                  "Parabéns, o mais difícil já passou, agora é só aproveitar o embalo🔥",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              Space.vertical(32),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        timerController.isCrescentTimer
                            ? "+ ${formatTime(timerController.actualSeconds)}"
                            : formatTime(timerController.actualSeconds),
                        style: TextStyle(
                          fontSize: 56,
                          color: Color(0xff09314d),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "MINUTOS",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Space.vertical(40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ControllTimerButton(
                    onTap: timerController.isRuning ? timerController.pauseTimer : timerController.startTimer,
                    icon: timerController.isRuning
                        ? Icon(Icons.pause, size: 56, color: Colors.white)
                        : Icon(Icons.play_arrow, size: 56, color: Colors.white),
                    backgroundColor: colorScheme.primary,
                  ),
                  ControllTimerButton(
                    onTap: () async {
                      final secondsNow = timerController.getElapsedSeconds();
                      
                      if(secondsNow <= 5){
                        await timerController.cancelTimer();
                        if (context.mounted) Navigator.pop(context);
                      } else {
                        showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Text(
                              "Deseja finalizar a sessão?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Cancelar",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: finishSession,
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    Colors.red,
                                  ),
                                ),
                                child: Text("Finalizar"),
                              ),
                            ],
                          );
                        },
                      );
                      }
                      
                    },
                    icon: Icon(Icons.close, size: 30),
                    border: Border.all(color: Color(0xffcde5ff), width: 2),
                  ),
                ],
              ),
              Space.vertical(40),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xffe8f2ff),
                  borderRadius: BorderRadius.circular(20),
                  border: Border(
                    left: BorderSide(width: 8, color: colorScheme.primary),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SESSÃO ATUAL",
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
