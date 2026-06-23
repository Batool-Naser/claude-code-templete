import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/services/firebase_auth_service.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/profile/application/notifier/profile_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileHeader(profile: profile),
        const SizedBox(height: 24),
        _SettingsSection(
          title: 'AI Preferences',
          items: [
            _SettingsItem(
              icon: Icons.psychology_rounded,
              title: 'AI Personality',
              subtitle: profile.aiPersonality,
              onTap: () => _editPersonality(context, ref, profile),
            ),
            _SettingsItem(
              icon: Icons.bedtime_rounded,
              title: 'Wake Time',
              subtitle: profile.wakeTimeLabel,
              onTap: () => _editWakeTime(context, ref, profile),
            ),
            _SettingsItem(
              icon: Icons.nights_stay_rounded,
              title: 'Sleep Target',
              subtitle: '${profile.targetSleepHours} hours per night',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: 'Goals',
          items: profile.goals.isEmpty
              ? [_SettingsItem(icon: Icons.add_rounded, title: 'No goals set yet', onTap: () {})]
              : profile.goals.map((g) => _SettingsItem(
                    icon: Icons.check_circle_outline_rounded,
                    title: g,
                    onTap: () {},
                  )).toList(),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: 'Account',
          items: [
            _SettingsItem(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: profile.email,
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              subtitle: '1.0.0',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SignOutButton(onTap: () => _signOut(context, ref)),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _editPersonality(BuildContext context, WidgetRef ref, UserProfileModel profile) async {
    String selected = profile.aiPersonality;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('AI Personality'),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (v) { if (v != null) setState(() => selected = v); },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppConstants.personalities.map((p) => ListTile(
                title: Text(p),
                leading: Radio<String>(
                  value: p,
                  activeColor: AppColors.primary,
                ),
                onTap: () => setState(() => selected = p),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(profileNotifierProvider.notifier)
                    .updateProfile(profile.copyWith(aiPersonality: selected));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editWakeTime(BuildContext context, WidgetRef ref, UserProfileModel profile) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: profile.wakeTimeHour, minute: profile.wakeTimeMinute),
    );
    if (t != null) {
      await ref.read(profileNotifierProvider.notifier).updateProfile(
        profile.copyWith(wakeTimeHour: t.hour, wakeTimeMinute: t.minute),
      );
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(firebaseAuthServiceProvider).signOut();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile.displayName ?? profile.firstName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(profile.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(profile.subscriptionTier.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  item,
                  if (!isLast) const Divider(height: 1, indent: 52),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
      onTap: onTap,
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}
