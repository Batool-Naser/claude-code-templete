import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/services/firebase_auth_service.dart';
import 'package:todo_app/features/ai_alarm_setup/screen/ai_alarm_setup_screen.dart';
import 'package:todo_app/features/ai_coach/screen/ai_coach_chat_screen.dart';
import 'package:todo_app/features/alarm/screen/create_alarm_screen.dart';
import 'package:todo_app/features/anti_snooze/screen/anti_snooze_screen.dart';
import 'package:todo_app/features/authentication/screen/login_screen.dart';
import 'package:todo_app/features/authentication/screen/register_screen.dart';
import 'package:todo_app/features/daily_routine/screen/daily_routine_screen.dart';
import 'package:todo_app/features/home/screen/home_screen.dart';
import 'package:todo_app/features/onboarding/screen/onboarding_screen.dart';
import 'package:todo_app/features/progress/screen/progress_screen.dart';
import 'package:todo_app/features/profile/screen/profile_screen.dart';
import 'package:todo_app/features/sleep_analysis/screen/sleep_analysis_screen.dart';
import 'package:todo_app/features/smart_planner/screen/smart_planner_screen.dart';
import 'package:todo_app/features/splash/screen/splash_screen.dart';
import 'package:todo_app/features/wake_up/screen/wake_up_screen.dart';
import 'package:todo_app/features/alarm/screen/alarm_management_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const alarms = '/alarms';
  static const sleepAnalysis = '/sleep';
  static const progress = '/progress';
  static const profile = '/profile';
  static const createAlarm = '/alarm/create';
  static const aiAlarmSetup = '/alarm/ai-setup';
  static const wakeUp = '/wake-up';
  static const antiSnooze = '/anti-snooze';
  static const aiCoach = '/ai-coach';
  static const smartPlanner = '/smart-planner';
  static const dailyRoutine = '/daily-routine';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final isLoggedIn = authState.value != null;
      final location = state.matchedLocation;

      if (location == AppRoutes.splash) return null;

      if (!isLoggedIn) {
        if (location == AppRoutes.login || location == AppRoutes.register) {
          return null;
        }
        return AppRoutes.login;
      }

      // Check onboarding
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;
      if (!onboarded && location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      if (location == AppRoutes.login || location == AppRoutes.register) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.alarms,
                builder: (context, state) => const AlarmManagementScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sleepAnalysis,
                builder: (context, state) => const SleepAnalysisScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.createAlarm,
        builder: (context, state) => const CreateAlarmScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAlarmSetup,
        builder: (_, state) => AIAlarmSetupScreen(
          alarmId: state.uri.queryParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.wakeUp,
        builder: (_, state) => WakeUpScreen(
          alarmId: state.uri.queryParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.antiSnooze,
        builder: (_, state) => AntiSnoozeScreen(
          challengeType: state.uri.queryParameters['type'] ?? 'math',
        ),
      ),
      GoRoute(
        path: AppRoutes.aiCoach,
        builder: (context, state) => const AICoachChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.smartPlanner,
        builder: (context, state) => const SmartPlannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyRoutine,
        builder: (context, state) => const DailyRoutineScreen(),
      ),
    ],
  );
});

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm_rounded), label: 'Alarms'),
          BottomNavigationBarItem(icon: Icon(Icons.bedtime_rounded), label: 'Sleep'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
