import 'package:shared_preferences/shared_preferences.dart';

class FirstTimerTipsService {
  static const String _pendingSheetKey = 'first_timer_tips_pending';
  static const String _sheetShownKey = 'first_timer_tips_shown';

  Future<bool> shouldShowTipsSheet() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_sheetShownKey) ?? false) return false;
    return prefs.getBool(_pendingSheetKey) ?? false;
  }

  Future<void> markFirstTimerCompletedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_sheetShownKey) ?? false) return;
    await prefs.setBool(_pendingSheetKey, true);
  }

  Future<void> markTipsSheetShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sheetShownKey, true);
    await prefs.setBool(_pendingSheetKey, false);
  }
}
