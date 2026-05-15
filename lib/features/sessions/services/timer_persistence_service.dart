import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> savePlayState(String taskId, int currentAccumulated) async {
    final String? existingTaskId = await _prefs.getString(_keyTaskId);
    if (existingTaskId != null && existingTaskId != taskId) {
      await _clearAnalyticsMilestoneKeys();
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
    await _prefs.remove(_keyTaskId);
    await _prefs.remove(_keyStartTimestamp);
    await _prefs.remove(_keyAccumulatedSeconds);
    await _prefs.remove(_keyIsRunning);
  }
}
