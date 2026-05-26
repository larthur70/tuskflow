import 'package:tuskflow/features/tasks/models/task_model.dart';

class TimerRouteArgs {
  const TimerRouteArgs({
    required this.task,
    this.autoStart = true,
  });

  final TaskModel task;

  /// When false, only restores persisted play/pause state (e.g. reopening app).
  final bool autoStart;
}
