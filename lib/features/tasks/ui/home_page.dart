import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tuskflow/core/navigation/home_visit_refresh.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/features/notifications/services/notification_banner_service.dart';
import 'package:tuskflow/features/notifications/ui/notification_disabled_banner.dart';
import 'package:tuskflow/features/onboarding/ui/first_timer_tips_bottom_sheet.dart';
import 'package:tuskflow/features/sessions/services/first_timer_tips_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/sessions/services/timer_persistence_service.dart';
import 'package:tuskflow/features/tasks/controllers/task_controller.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';
import 'package:tuskflow/features/tasks/ui/profile_page.dart';
import 'package:tuskflow/features/tasks/ui/task_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  Future<void> _checkActiveSession() async {
    final persistence = TimerPersistenceService();
    final sessionData = await persistence.getActiveSession();

    if (sessionData == null) return;

    TaskModel? task = await persistence.getCachedActiveTask();
    task ??= await context.read<FirestoreTaskService>().getTaskById(
      sessionData['taskId'] as String,
    );

    if (!mounted || task == null) return;
    Navigator.pushNamed(context, "/timer_page", arguments: task);
  }

  void _uploadFcmTokenIfNeeded() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(NotificationService.instance.uploadFcmToken(uid));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaskController>().invalidateTaskStream();
    });
    _checkActiveSession();
    _uploadFcmTokenIfNeeded();
    _maybeShowPostLoginPrompts();
    verBundleId();
  }

  void _maybeShowPostLoginPrompts() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await NotificationService.instance.requestSystemPermissionOnHomeIfNeeded();
      if (!mounted) return;
      final shouldShow = await FirstTimerTipsService().shouldShowTipsSheet();
      if (!mounted || !shouldShow) return;
      await showFirstTimerTipsBottomSheet(context);
    });
  }

  verBundleId() async {
    final info = await PackageInfo.fromPlatform();
    print(info.packageName);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          _selectedIndex == 0 ? 'TuskFlow' : 'Perfil',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
      ),
      body: Column(
        children: [
          if (_selectedIndex == 0)
            ValueListenableBuilder<int>(
              valueListenable: HomeVisitRefresh.instance.token,
              builder: (context, refreshToken, _) {
                return NotificationDisabledBanner(
                  placement: NotificationBannerPlacement.home,
                  refreshToken: refreshToken,
                );
              },
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: const [
                TaskList(),
                ProfilePage(embeddedInHome: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/create_task");
        },
        backgroundColor: colorScheme.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          clipBehavior: Clip.antiAlias,
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            currentIndex: _selectedIndex,
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Lista de tarefas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
