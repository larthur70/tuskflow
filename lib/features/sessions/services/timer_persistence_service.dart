import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';

/// Persisted flags so analytics milestones are not re-fired after app restart / restore.
class TimerAnalyticsMilestones {
  const TimerAnalyticsMilestones({
    required this.fiveSecondStart,
    required this.fiveMinSuccess,
    required this.extended15Min,
  });

  final bool fiveSecondStart;
  final bool fiveMinSuccess;
  final bool extended15Min;
}

class TimerPersistenceService {
  final _prefs = SharedPreferencesAsync();

  static const _keyTaskId = "active_task_id";
  static const _keyTaskTitle = 'active_task_title';
  static const _keyTaskDueDateMs = 'active_task_due_date_ms';
  static const _keyTaskCreatedAtMs = 'active_task_created_at_ms';
  static const _keyTaskFinished = 'active_task_finished';
  static const _keyTaskInitialized = 'active_task_initialized';
  static const _keyStartTimestamp = "start_timestamp";
  static const _keyAccumulatedSeconds = 'acumulated_seconds';
  static const _keyIsRunning = 'is_running';

  static const _keyMilestoneFiveSec = 'timer_analytics_five_sec';
  static const _keyMilestoneFiveMinSuccess = 'timer_analytics_five_min_success';
  static const _keyMilestoneExtended15 = 'timer_analytics_extended_15';

  Future<void> _clearAnalyticsMilestoneKeys() async {
    await _prefs.remove(_keyMilestoneFiveSec);
    await _prefs.remove(_keyMilestoneFiveMinSuccess);
    await _prefs.remove(_keyMilestoneExtended15);
  }

  Future<TimerAnalyticsMilestones> getAnalyticsMilestones() async {
    return TimerAnalyticsMilestones(
      fiveSecondStart: await _prefs.getBool(_keyMilestoneFiveSec) ?? false,
      fiveMinSuccess: await _prefs.getBool(_keyMilestoneFiveMinSuccess) ?? false,
      extended15Min: await _prefs.getBool(_keyMilestoneExtended15) ?? false,
    );
  }

  Future<void> setAnalyticsMilestoneFiveSec(bool value) async {
    await _prefs.setBool(_keyMilestoneFiveSec, value);
  }

  Future<void> setAnalyticsMilestoneFiveMinSuccess(bool value) async {
    await _prefs.setBool(_keyMilestoneFiveMinSuccess, value);
  }

  Future<void> setAnalyticsMilestoneExtended15(bool value) async {
    await _prefs.setBool(_keyMilestoneExtended15, value);
  }

  Future<void> saveActiveTaskSnapshot(TaskModel task) async {
    await _prefs.setString(_keyTaskId, task.id);
    await _prefs.setString(_keyTaskTitle, task.title);
    await _prefs.setInt(_keyTaskDueDateMs, task.dueDate.millisecondsSinceEpoch);
    await _prefs.setInt(_keyTaskCreatedAtMs, task.createdAt.millisecondsSinceEpoch);
    await _prefs.setBool(_keyTaskFinished, task.finished);
    await _prefs.setBool(_keyTaskInitialized, task.initialized);
  }

  Future<TaskModel?> getCachedActiveTask() async {
    final String? taskId = await _prefs.getString(_keyTaskId);
    final String? title = await _prefs.getString(_keyTaskTitle);
    final int? dueDateMs = await _prefs.getInt(_keyTaskDueDateMs);
    final int? createdAtMs = await _prefs.getInt(_keyTaskCreatedAtMs);
    final bool? finished = await _prefs.getBool(_keyTaskFinished);
    final bool? initialized = await _prefs.getBool(_keyTaskInitialized);

    if (taskId == null ||
        title == null ||
        dueDateMs == null ||
        createdAtMs == null ||
        finished == null ||
        initialized == null) {
      return null;
    }

    return TaskModel(
      id: taskId,
      title: title,
      dueDate: DateTime.fromMillisecondsSinceEpoch(dueDateMs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      finished: finished,
      initialized: initialized,
    );
  }

  Future<void> _clearActiveTaskSnapshot() async {
    await _prefs.remove(_keyTaskTitle);
    await _prefs.remove(_keyTaskDueDateMs);
    await _prefs.remove(_keyTaskCreatedAtMs);
    await _prefs.remove(_keyTaskFinished);
    await _prefs.remove(_keyTaskInitialized);
  }

  Future<void> savePlayState(String taskId, int currentAccumulated) async {
    final String? existingTaskId = await _prefs.getString(_keyTaskId);
    if (existingTaskId != null && existingTaskId != taskId) {
      await _clearAnalyticsMilestoneKeys();
      await _clearActiveTaskSnapshot();
    }
    await _prefs.setString(_keyTaskId, taskId);
    await _prefs.setInt(_keyStartTimestamp, DateTime.now().millisecondsSinceEpoch);
    await _prefs.setInt(_keyAccumulatedSeconds, currentAccumulated);
    await _prefs.setBool(_keyIsRunning, true);
  }

  Future<void> savePauseState(int finalAccumulated) async {
    await _prefs.setBool(_keyIsRunning, false);
    await _prefs.setInt(_keyAccumulatedSeconds, finalAccumulated);
    await _prefs.remove(_keyStartTimestamp);
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final String? taskId = await _prefs.getString(_keyTaskId);
    final int? startTs = await _prefs.getInt(_keyStartTimestamp);
    final int? accSeconds = await _prefs.getInt(_keyAccumulatedSeconds);
    final bool? isRunning = await _prefs.getBool(_keyIsRunning);

    if (taskId == null) return null;

    return {
      'taskId': taskId,
      'startTime': startTs != null ? DateTime.fromMillisecondsSinceEpoch(startTs) : null,
      'acumulatedSeconds': accSeconds ?? 0,
      'isRunning': isRunning ?? false
    };
  }

  Future<void> clearSession() async {
    await _clearAnalyticsMilestoneKeys();
    await _clearActiveTaskSnapshot();
    await _prefs.remove(_keyTaskId);
    await _prefs.remove(_keyStartTimestamp);
    await _prefs.remove(_keyAccumulatedSeconds);
    await _prefs.remove(_keyIsRunning);
  }
}
