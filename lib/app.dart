import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/services/auth_service.dart';
import 'package:tuskflow/core/services/user_service.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';
import 'package:tuskflow/features/analytics/widgets/app_lifecycle_analytics.dart';
import 'package:tuskflow/core/navigation/home_visit_navigator_observer.dart';
import 'package:tuskflow/core/navigation/home_visit_refresh.dart';
import 'package:tuskflow/features/auth/auth_wrapper.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_controller.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_setup_controller.dart';
import 'package:tuskflow/features/sessions/controller/timer_controller.dart';
import 'package:tuskflow/features/sessions/services/firestore_session_service.dart';
import 'package:tuskflow/features/sessions/ui/session_end_page.dart';
import 'package:tuskflow/features/tasks/controllers/task_controller.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';
import 'package:tuskflow/features/tasks/ui/create_task_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuskflow/features/sessions/ui/timer_page.dart';
import 'package:tuskflow/features/sessions/ui/timer_route_args.dart';


class App extends StatelessWidget {
  const App({super.key});

  static final HomeVisitNavigatorObserver homeVisitNavigatorObserver =
      HomeVisitNavigatorObserver(
    onHomeVisitRecorded: HomeVisitRefresh.instance.notifyVisitRecorded,
  );

  static const primaryBlue = Color(0xFF13B9FD);  // azul principal (Dart vibe)
  static const secondaryBlue = Color(0xFF0175C2);// azul claro vibrante
  static const darkBlue = Color(0xFF02569B); // azul mais profundo
  static const pinkColor = Color(0xFFd799ff);

  static const background = Colors.white; // fundo leve
  static const surface = Color(0xFFF5F7FA); // cards
  static const border = Color(0xFFE0E0E0); // bordas leves

  static const danger = Color(0xFFE53935); // urgente
  static const warning = Color(0xFFFFB300); // atenção
  static const success = Color(0xFF43A047); // concluído

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static ThemeData _appTheme() {
    final primaryColor = Colors.blue;
    return ThemeData(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryBlue,
        onSecondary: Colors.white,
        error: danger,
        onError: Colors.white,
        surface: surface,
        onSurface: Colors.black87,
      ),
      progressIndicatorTheme: _isAndroid
          ? const ProgressIndicatorThemeData(color: primaryBlue)
          : null,
    );
  }

  static Widget _androidLoaderOverlay(dynamic _) {
    return const Center(
      child: CircularProgressIndicator(color: primaryBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => UserService()),
        Provider(create: (context) => AuthService(context.read<UserService>())),
        Provider(create: (context)=>FirestoreTaskService()),
        Provider(create: (context) => FirestoreSessionService()),
        Provider(create: (context) => OnboardingController()),
        ChangeNotifierProvider(create: (_) => OnboardingSetupController()),
        Provider(create: (context) => AnalyticsService()),
        ChangeNotifierProvider(
          create: (context) => TimerController(context.read<AnalyticsService>()),
        ),

        ChangeNotifierProvider(create: (context) => TaskController(context.read<FirestoreTaskService>()))
      ],
      builder: (context,child) {
        return GlobalLoaderOverlay(
          overlayWidgetBuilder:
              _isAndroid ? _androidLoaderOverlay : null,
          child: AppLifecycleAnalytics(
            child: MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorObservers: [App.homeVisitNavigatorObserver],
            theme: _appTheme(),
            onGenerateRoute: (settings){
              if (settings.name == '/timer_page') {
                final TimerRouteArgs args = settings.arguments is TimerRouteArgs
                    ? settings.arguments as TimerRouteArgs
                    : TimerRouteArgs(
                        task: settings.arguments as TaskModel,
                        autoStart: false,
                      );
                return MaterialPageRoute(
                  builder: (context) => TimerPage(
                    task: args.task,
                    autoStart: args.autoStart,
                  ),
                );
              }
              return null;
            },
            routes: {
              "/": (context) => AuthWrapper(),
              "/create_task": (context) => CreateTask(),
              "/succes_page": (context) => SessionEndPage(),
              },
            ),
          ),
        );
      }
    );
  }
}
