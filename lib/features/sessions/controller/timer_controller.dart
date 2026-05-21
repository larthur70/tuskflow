import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';
import 'package:tuskflow/features/sessions/services/timer_persistence_service.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';

class TimerController extends ChangeNotifier {
  TimerController(this._analytics);

  final AnalyticsService _analytics;
  final _persistence = TimerPersistenceService();

  TaskModel? _currentTask;
  TaskModel? get currentTask => _currentTask;

  static const totalSeconds = 300;
  /// Five minutes initial countdown plus 15 minutes in progressive mode.
  static const int _extendedSessionSeconds = totalSeconds + 900;

  int totalFinalSeconds = 0;
  int actualSeconds = totalSeconds;
  Timer? timer;
  bool isRuning = false;
  bool isCrescentTimer = false;
  int acumulatedSeconds = 0;
  DateTime? startTime;

  bool _firedFiveSecondMilestone = false;
  bool _firedFiveMinSuccess = false;
  bool _firedExtended15Min = false;

  void _resetMilestoneFlags() {
    _firedFiveSecondMilestone = false;
    _firedFiveMinSuccess = false;
    _firedExtended15Min = false;
  }

  void setTask(TaskModel task) {
    if (_currentTask?.id != task.id) {
      actualSeconds = totalSeconds;
      isCrescentTimer = false;
      acumulatedSeconds = 0;
      startTime = null;
      _resetMilestoneFlags();
    }
    _currentTask = task;
    Future.microtask(() => notifyListeners());
  }

  void startTimer() {
    final task = _currentTask;

    if (task == null) return;

    if (isRuning) return;

    startTime ??= DateTime.now();
    isRuning = true;
    notifyListeners();

    _persistence.savePlayState(task.id, acumulatedSeconds);
    _persistence.saveActiveTaskSnapshot(task);
    _resumeTimerLoop();
  }

  void _updateDisplayTime() {
    final now = DateTime.now();
    final int currentSessionDiff = (isRuning && startTime != null)
        ? now.difference(startTime!).inSeconds
        : 0;
    final int totalElapsed = acumulatedSeconds + currentSessionDiff;

    if (totalElapsed < totalSeconds) {
      actualSeconds = totalSeconds - totalElapsed;
      isCrescentTimer = false;
    } else {
      actualSeconds = totalElapsed - totalSeconds;
      isCrescentTimer = true;
    }
    _maybeLogSessionMilestones(totalElapsed);
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    final task = _currentTask;
    if (task == null) return false;
    final session = await _persistence.getActiveSession();

    if (session != null && session['taskId'] == task.id) {
      final milestones = await _persistence.getAnalyticsMilestones();
      _firedFiveSecondMilestone = milestones.fiveSecondStart;
      _firedFiveMinSuccess = milestones.fiveMinSuccess;
      _firedExtended15Min = milestones.extended15Min;

      final bool wasRunning = session['isRunning'] ?? false;
      final int savedAccumulated = session['acumulatedSeconds'] ?? 0;
      final DateTime? savedStartTime = session['startTime'];

      acumulatedSeconds = savedAccumulated;
      startTime = savedStartTime;
      isRuning = wasRunning;
      Future.microtask(() => notifyListeners());

      if (wasRunning && savedStartTime != null) {
        acumulatedSeconds = savedAccumulated;
        startTime = savedStartTime;
        isRuning = true;
        notifyListeners();
        recalculateTime();
        _resumeTimerLoop();
      } else {
        acumulatedSeconds = savedAccumulated;
        startTime = null;
        isRuning = false;
        notifyListeners();
        _updateDisplayTime();
      }
      return true;
    }
    return false;
  }

  Future<void> _updateLastTimerAt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'lastTimerAt': FieldValue.serverTimestamp(),
          'habitHour': DateTime.now().hour
        });
        debugPrint('Fogo inicial de 5s batido! lastTimerAt atualizado. 🐘🔥');
      } catch (e) {
        debugPrint("Erro ao atualizar atividade: $e");
      }
    }
  }

  void _maybeLogSessionMilestones(int totalElapsed) {
    if (totalElapsed >= 5 && !_firedFiveSecondMilestone) {
      _firedFiveSecondMilestone = true;
      _updateLastTimerAt();
      _analytics.logTimer5MinStart();
      _persistence.setAnalyticsMilestoneFiveSec(true);
    }
    if (totalElapsed >= totalSeconds && !_firedFiveMinSuccess) {
      _firedFiveMinSuccess = true;
      _analytics.logTimer5MinSuccess();
      _persistence.setAnalyticsMilestoneFiveMinSuccess(true);
    }
    if (totalElapsed >= _extendedSessionSeconds && !_firedExtended15Min) {
      _firedExtended15Min = true;
      _analytics.logSessionExtended15Min();
      _persistence.setAnalyticsMilestoneExtended15(true);
    }
  }

  void _resumeTimerLoop() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDisplayTime();
    });
  }

  int getElapsedSeconds() {
    if (isRuning && startTime != null) {
      final now = DateTime.now();
      return acumulatedSeconds + now.difference(startTime!).inSeconds;
    }
    return acumulatedSeconds;
  }

  void pauseTimer() async {
    if (!isRuning) return;

    final now = DateTime.now();
    final int elapsedThisSession = now.difference(startTime!).inSeconds;

    acumulatedSeconds += elapsedThisSession;

    timer?.cancel();

    isRuning = false;
    startTime = null;
    notifyListeners();

    await _persistence.savePauseState(acumulatedSeconds);
  }

  void cancelTimer() async {
    timer?.cancel();

    _resetMilestoneFlags();
    totalFinalSeconds = getElapsedSeconds();
    startTime = null;
    acumulatedSeconds = 0;
    isRuning = false;
    actualSeconds = totalSeconds;
    isCrescentTimer = false;
    await _persistence.clearSession();
    notifyListeners();
  }

  void recalculateTime() {
    if (startTime == null) return;

    final elapsed = getElapsedSeconds();

    if (elapsed < totalSeconds) {
      actualSeconds = totalSeconds - elapsed;
      isCrescentTimer = false;
    } else {
      isCrescentTimer = true;
      actualSeconds = elapsed - totalSeconds;
    }
    _maybeLogSessionMilestones(elapsed);
    notifyListeners();
  }
}
