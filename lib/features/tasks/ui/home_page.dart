import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/features/notifications/ui/notification_disabled_banner.dart';
import 'package:tuskflow/features/notifications/ui/notification_permission_bottom_sheet.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_setup_controller.dart';
import 'package:tuskflow/features/onboarding/ui/first_timer_tips_bottom_sheet.dart';
import 'package:tuskflow/features/tasks/ui/start_five_minutes_page.dart';
import 'package:tuskflow/features/sessions/services/first_timer_tips_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';
import 'package:tuskflow/features/pro_analitcs/analitcs_page.dart';
import 'package:tuskflow/features/sessions/services/timer_persistence_service.dart';
import 'package:tuskflow/features/tasks/controllers/task_controller.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';
import 'package:tuskflow/features/tasks/ui/task_list.dart';





class HomePage extends StatefulWidget {
  
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  OnboardingSetupController? _setupController;
  bool _startFiveMinutesPromptShown = false;
  bool _isResolvingStartFiveMinutesPrompt = false;

  int _selectedIndex = 0;
  bool _analyticsMounted = false;
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
    _setupController = context.read<OnboardingSetupController>()
      ..addListener(_onSetupControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaskController>().invalidateTaskStream();
    });
    _checkActiveSession();
    _maybeShowStartFiveMinutesPrompt();
    _uploadFcmTokenIfNeeded();
    _maybeShowNotificationPermissionSheet();
    _maybeShowFirstTimerTipsSheet();
    verBundleId();
  }

  @override
  void dispose() {
    _setupController?.removeListener(_onSetupControllerChanged);
    super.dispose();
  }

  void _onSetupControllerChanged() {
    _maybeShowStartFiveMinutesPrompt();
  }

  Future<void> _maybeShowStartFiveMinutesPrompt() async {
    if (!mounted ||
        _startFiveMinutesPromptShown ||
        _isResolvingStartFiveMinutesPrompt) {
      return;
    }
    _isResolvingStartFiveMinutesPrompt = true;
    try {
      final taskId = await context
          .read<OnboardingSetupController>()
          .consumePendingStartFiveMinutesTaskId();
      if (!mounted || taskId == null) return;

      final task =
          await context.read<FirestoreTaskService>().getTaskById(taskId);
      if (!mounted || task == null) return;

      _startFiveMinutesPromptShown = true;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StartFiveMinutesPage(task: task),
        ),
      );
    } finally {
      _isResolvingStartFiveMinutesPrompt = false;
    }
  }

  void _maybeShowFirstTimerTipsSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shouldShow = await FirstTimerTipsService().shouldShowTipsSheet();
      if (!mounted || !shouldShow) return;
      await showFirstTimerTipsBottomSheet(context);
    });
  }

  void _maybeShowNotificationPermissionSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shouldShow =
          await NotificationService.instance.shouldShowNotificationPrompt();
      if (!mounted || !shouldShow) return;
      await showNotificationPermissionBottomSheet(context);
    });
  }

  verBundleId()async{
     final info = await PackageInfo.fromPlatform();
    print(info.packageName);
  }

  @override
  Widget build(BuildContext context) {

    final colorScheme = ColorScheme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 16),
        actions: [
          SizedBox(
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: (){
                Navigator.pushNamed(context, "/profile_page");
              },
              child: Icon(Icons.person_outline_rounded,size: 35,),
            ),
          )
        ],
        centerTitle: false,
        title: Text("TuskFlow",style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 28
        ),),
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
      ),

      body: Column(
        children: [
          if (_selectedIndex == 0) const NotificationDisabledBanner(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 1) _analyticsMounted = true;
                });
                if (index == 1) {
                  unawaited(context.read<AnalyticsService>().logProgressScreenOpened());
                }
              },
              children: [
                const TaskList(),
                if (_analyticsMounted)
                  const AnaliticsPage()
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(onPressed: (){
        Navigator.pushNamed(context, "/create_task");
      },backgroundColor: colorScheme.primary,shape: CircleBorder(),child: Icon(Icons.add),),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          onTap: (index){
            _pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
          items: [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt),label: 'Lista de tarefas'),
          BottomNavigationBarItem(icon: Icon(Icons.insights),label: 'Progresso')
        ]),
      ),
    );
  }
}