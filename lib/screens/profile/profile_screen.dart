import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api_error.dart';
import '../../models/caregiver_profile.dart';
import '../../state/auth_controller.dart';
import '../../state/profile_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/labels.dart';
import '../../utils/regions.dart';
import 'availability_screen.dart';
import 'service_areas_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profileCtrl = context.watch<ProfileController>();
    final me = auth.user;
    final profile = profileCtrl.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('내정보')),
      body: RefreshIndicator(
        onRefresh: profileCtrl.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        _initials(me?.name),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(me?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(me?.phone ?? '', style: const TextStyle(color: AppColors.body)),
                          Text(me?.caregiverCenterName ?? '', style: const TextStyle(color: AppColors.body)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('콜 수락', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('끄면 해당 유형 콜이 오지 않습니다.', style: TextStyle(color: AppColors.body, fontSize: 13)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('대타 수락', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('BACKUP 콜'),
                    value: profile?.acceptsBackup ?? false,
                    activeThumbColor: AppColors.primary,
                    onChanged: profile == null
                        ? null
                        : (v) => _safe(context, () => profileCtrl.setAccepts(backup: v)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('신규 수락', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('NEW 콜'),
                    value: profile?.acceptsNew ?? false,
                    activeThumbColor: AppColors.primary,
                    onChanged: profile == null
                        ? null
                        : (v) => _safe(context, () => profileCtrl.setAccepts(neu: v)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('차량 있음', style: TextStyle(fontWeight: FontWeight.w700)),
                    value: profile?.hasVehicle ?? false,
                    activeThumbColor: AppColors.primary,
                    onChanged: profile == null
                        ? null
                        : (v) => _safe(context, () => profileCtrl.setHasVehicle(v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('가능 시간', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(_availabilitySummary(profile?.availabilities ?? const [])),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AvailabilityScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('활동 지역', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      (profile?.serviceAreas ?? const [])
                          .map((a) => regionLabel(a.regionCode))
                          .join(', ')
                          .ifEmpty('등록된 지역 없음'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ServiceAreasScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('성별', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(genderLabel(profile?.gender)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: profile == null ? null : () => _pickGender(context, profileCtrl, profile.gender),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('로그아웃할까요?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('로그아웃')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) await auth.logout();
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1);
  }

  String _availabilitySummary(List<Availability> items) {
    if (items.isEmpty) return '등록된 가능 시간 없음';
    return items.map((a) => '${dowLabels[a.dayOfWeek]} ${a.startTime}–${a.endTime}').join(' · ');
  }

  Future<void> _pickGender(BuildContext context, ProfileController ctrl, String? current) async {
    const options = ['FEMALE', 'MALE', 'OTHER', 'UNDISCLOSED'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final g in options)
                ListTile(
                  title: Text(genderLabel(g)),
                  trailing: current == g ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () => Navigator.pop(ctx, g),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    await ctrl.setGender(selected);
  }

  Future<void> _safe(BuildContext context, Future<void> Function() fn) async {
    try {
      await fn();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
