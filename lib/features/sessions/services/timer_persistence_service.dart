import 'package:shared_preferences/shared_preferences.dart';

class TimerPersistenceService {
  final _prefs = SharedPreferencesAsync();

  static const _keyTaskId = "active_task_id";
  static const _keyStartTimestamp = "start_timestamp";
  static const _keyAccumulatedSeconds = 'acumulated_seconds';
  static const _keyIsRunning = 'is_running';

  Future<void> savePlayState(String taskId, int currentAccumulated) async {
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

  Future<Map<String,dynamic>?> getActiveSession() async {
    final String? taskId = await _prefs.getString(_keyTaskId);
    final int? startTs = await _prefs.getInt(_keyStartTimestamp);
    final int? accSeconds = await _prefs.getInt(_keyAccumulatedSeconds);
    final bool? isRunning = await _prefs.getBool(_keyIsRunning);

    if(taskId == null) return null;

    
    return {
        'taskId':taskId,
        'startTime': startTs != null ? DateTime.fromMillisecondsSinceEpoch(startTs) : null,
        'acumulatedSeconds': accSeconds ?? 0,
        'isRunning': isRunning ?? false
      };
    
    
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyTaskId);
    await _prefs.remove(_keyStartTimestamp);
    await _prefs.remove(_keyAccumulatedSeconds);
    await _prefs.remove(_keyIsRunning);
  }
}