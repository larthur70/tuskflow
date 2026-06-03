import 'package:flutter/foundation.dart';

class HomeVisitRefresh {
  HomeVisitRefresh._();
  static final HomeVisitRefresh instance = HomeVisitRefresh._();

  final ValueNotifier<int> token = ValueNotifier(0);

  void notifyVisitRecorded() {
    token.value++;
  }
}
