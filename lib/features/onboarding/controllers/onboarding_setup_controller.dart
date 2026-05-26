import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tuskflow/features/onboarding/services/onboarding_setup_service.dart';

class OnboardingSetupController extends ChangeNotifier {
  final OnboardingSetupService _service = OnboardingSetupService();

  bool _complete = false;
  bool _initialized = false;
  bool _isResolving = false;

  bool get isComplete => _complete;
  bool get isInitialized => _initialized;
  bool get isResolving => _isResolving;

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
      if (!_complete && FirebaseAuth.instance.currentUser != null) {
        debugPrint(
          'Onboarding setup incomplete — signing out to restart onboarding.',
        );
        await FirebaseAuth.instance.signOut();
        await _service.clearSetupComplete();
        _complete = false;
      }
      _initialized = true;
      _isResolving = false;
      notifyListeners();
    }
  }

  Future<void> markComplete() async {
    await _service.markSetupComplete();
    _complete = true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> reset() async {
    await _service.clearSetupComplete();
    _complete = false;
    notifyListeners();
  }
}
