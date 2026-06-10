import 'package:shared_preferences/shared_preferences.dart';

class FirstTimerTipsService {
  FirstTimerTipsService._();
  static final FirstTimerTipsService instance = FirstTimerTipsService._();
  factory FirstTimerTipsService() => instance;

  static const String _pendingSheetKey = 'first_timer_tips_pending';
  static const String _sheetShownKey = 'first_timer_tips_shown';

  bool _postLoginPromptHandled = false;

  bool get hasHandledPostLoginPrompt => _postLoginPromptHandled;

  Future<bool> shouldShowTipsSheet() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_sheetShownKey) ?? false) return false;
    return prefs.getBool(_pendingSheetKey) ?? false;
  }

  /// Schedules the tips sheet for the next home visit after onboarding/login.
  Future<void> markPendingTipsSheetAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_sheetShownKey) ?? false) return;
    _postLoginPromptHandled = false;
    await prefs.setBool(_pendingSheetKey, true);
  }

  void markPostLoginPromptHandled() {
    _postLoginPromptHandled = true;
  }

  Future<void> markTipsSheetShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sheetShownKey, true);
    await prefs.setBool(_pendingSheetKey, false);
    _postLoginPromptHandled = true;
  }
}
