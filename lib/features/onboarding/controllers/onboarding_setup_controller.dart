import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/features/onboarding/services/onboarding_setup_service.dart';

class OnboardingSetupController extends ChangeNotifier {
  final OnboardingSetupService _service = OnboardingSetupService();

  bool _complete = false;
  bool _initialized = false;
  bool _isResolving = false;
  String? _pendingStartFiveMinutesTaskId;
  bool _isExitingOnboarding = false;

  bool get isComplete => _complete;
  bool get isInitialized => _initialized;
  bool get isResolving => _isResolving;
  bool get isExitingOnboarding => _isExitingOnboarding;

  void beginOnboardingExit() {
    _isExitingOnboarding = true;
  }

  void endOnboardingExit() {
    _isExitingOnboarding = false;
    notifyListeners();
  }

  /// Checks setup flag / Firestore migration, then recovers or signs out — never hangs.
  Future<void> loadAndRecoverIfNeeded() async {
    if (_isResolving) return;

    _isResolving = true;
    _initialized = false;
    notifyListeners();

    try {
      _complete = await _service.isSetupComplete();
      if (_complete) return;

      final bool ensured = await _service.ensureMinimalUserProfile();
      if (ensured) {
        _complete = true;
        return;
      }
    } catch (e, st) {
      debugPrint('OnboardingSetupController.loadAndRecoverIfNeeded: $e\n$st');
    } finally {
      if (!_complete) {
        // Another flow (e.g. social login) may have marked setup done while we ran.
        _complete = await _service.isSetupComplete();
      }
      if (!_complete &&
          !_isExitingOnboarding &&
          FirebaseAuth.instance.currentUser != null) {
        debugPrint(
          'Onboarding setup incomplete — signing out to restart onboarding.',
        );
        await NotificationService.instance.removeCurrentDeviceToken();
        await FirebaseAuth.instance.signOut();
        await _service.clearSetupComplete();
        _complete = false;
      }
      _initialized = true;
      _isResolving = false;
      notifyListeners();
    }
  }

  Future<String?> consumePendingStartFiveMinutesTaskId() async {
    final memoryId = _pendingStartFiveMinutesTaskId;
    _pendingStartFiveMinutesTaskId = null;
    final prefsId = await _service.takePendingStartFiveMinutesTaskId();
    return memoryId ?? prefsId;
  }

  Future<void> markComplete({String? createdTaskId}) async {
    if (createdTaskId != null) {
      _pendingStartFiveMinutesTaskId = createdTaskId;
      await _service.setPendingStartFiveMinutesTaskId(createdTaskId);
    }
    await _service.markSetupComplete();
    _complete = true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> reset() async {
    await _service.clearSetupComplete();
    _complete = false;
    _pendingStartFiveMinutesTaskId = null;
    _isExitingOnboarding = false;
    notifyListeners();
  }
}
