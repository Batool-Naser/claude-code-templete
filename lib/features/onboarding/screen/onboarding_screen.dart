import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/services/firebase_auth_service.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';
import 'package:todo_app/core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<String> _selectedGoals = [];
  int _wakeHour = 7;
  int _wakeMinute = 0;
  int _sleepHours = 8;
  String _personality = 'Motivational';

  final _goals = [
    'Better sleep quality',
    'Consistent schedule',
    'More energy',
    'Productivity boost',
    'Stress reduction',
    'Exercise routine',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    await prefs.setStringList(AppConstants.prefUserGoals, _selectedGoals);
    await prefs.setInt(AppConstants.prefWakeHour, _wakeHour);
    await prefs.setInt(AppConstants.prefWakeMinute, _wakeMinute);
    await prefs.setInt(AppConstants.prefSleepHours, _sleepHours);
    await prefs.setString(AppConstants.prefAiPersonality, _personality);

    // Update profile in Firestore
    final auth = ref.read(firebaseAuthServiceProvider);
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      final profile = UserProfileModel(
        id: uid,
        email: auth.currentUser?.email ?? '',
        displayName: auth.currentUser?.displayName,
        goals: _selectedGoals,
        wakeTimeHour: _wakeHour,
        wakeTimeMinute: _wakeMinute,
        targetSleepHours: _sleepHours,
        aiPersonality: _personality,
        onboardingComplete: true,
        createdAt: DateTime.now(),
      );
      await auth.updateUserProfile(profile);
    }

    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(currentPage: _currentPage),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GoalsPage(
                    goals: _goals,
                    selected: _selectedGoals,
                    onToggle: (g) => setState(
                      () => _selectedGoals.contains(g)
                          ? _selectedGoals.remove(g)
                          : _selectedGoals.add(g),
                    ),
                  ),
                  _WakeTimePage(
                    hour: _wakeHour,
                    minute: _wakeMinute,
                    sleepHours: _sleepHours,
                    onHourChanged: (h) => setState(() => _wakeHour = h),
                    onMinuteChanged: (m) => setState(() => _wakeMinute = m),
                    onSleepHoursChanged: (h) => setState(() => _sleepHours = h),
                  ),
                  _PersonalityPage(
                    selected: _personality,
                    onSelect: (p) => setState(() => _personality = p),
                  ),
                  const _ReadyPage(),
                ],
              ),
            ),
            _BottomActions(
              currentPage: _currentPage,
              onNext: _nextPage,
              canProceed: _currentPage != 0 || _selectedGoals.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentPage});
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= currentPage ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({required this.goals, required this.selected, required this.onToggle});
  final List<String> goals;
  final List<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What are your goals?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Select all that apply',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: goals.map((g) {
              final isSelected = selected.contains(g);
              return GestureDetector(
                onTap: () => onToggle(g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceVariant,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _WakeTimePage extends StatelessWidget {
  const _WakeTimePage({
    required this.hour,
    required this.minute,
    required this.sleepHours,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onSleepHoursChanged,
  });
  final int hour, minute, sleepHours;
  final void Function(int) onHourChanged, onMinuteChanged, onSleepHoursChanged;

  @override
  Widget build(BuildContext context) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set your wake time',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('AI will optimize around this time',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 40),
          Center(
            child: Text('$h:$m $period',
                style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(height: 24),
          const Text('Hour', style: TextStyle(color: AppColors.textSecondary)),
          Slider(
            value: hour.toDouble(),
            min: 4,
            max: 11,
            divisions: 7,
            label: '$h $period',
            onChanged: (v) => onHourChanged(v.round()),
          ),
          const Text('Minute', style: TextStyle(color: AppColors.textSecondary)),
          Slider(
            value: minute.toDouble(),
            min: 0,
            max: 45,
            divisions: 3,
            label: m,
            onChanged: (v) => onMinuteChanged(v.round()),
          ),
          const SizedBox(height: 16),
          const Text('Target sleep duration', style: TextStyle(color: AppColors.textSecondary)),
          Slider(
            value: sleepHours.toDouble(),
            min: 6,
            max: 10,
            divisions: 4,
            label: '${sleepHours}h',
            onChanged: (v) => onSleepHoursChanged(v.round()),
          ),
          Center(
            child: Text('${sleepHours}h per night',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _PersonalityPage extends StatelessWidget {
  const _PersonalityPage({required this.selected, required this.onSelect});
  final String selected;
  final void Function(String) onSelect;

  static const _options = [
    {'name': 'Energetic', 'icon': Icons.bolt, 'desc': 'High energy, pump-up style'},
    {'name': 'Calm', 'icon': Icons.spa, 'desc': 'Gentle, mindful approach'},
    {'name': 'Motivational', 'icon': Icons.emoji_events, 'desc': 'Goal-focused coaching'},
    {'name': 'Gentle', 'icon': Icons.favorite, 'desc': 'Soft, caring guidance'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose AI personality',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('How should your AI coach communicate?',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          ..._options.map((opt) {
            final name = opt['name'] as String;
            final icon = opt['icon'] as IconData;
            final desc = opt['desc'] as String;
            final isSelected = selected == name;
            return GestureDetector(
              onTap: () => onSelect(name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                      Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                    if (isSelected) ...[
                      const Spacer(),
                      const Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, size: 64, color: Colors.white),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          const Text('You\'re all set!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          const Text(
            'Your AI coach is ready.\nWake up smarter every morning.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.currentPage,
    required this.onNext,
    required this.canProceed,
  });
  final int currentPage;
  final VoidCallback onNext;
  final bool canProceed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: canProceed ? onNext : null,
          child: Text(
            currentPage < 3 ? 'Continue' : 'Get Started',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
