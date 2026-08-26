import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 스크린샷 하단 탭: 근무 / 일정 / 알림 / 마이
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    this.notificationBadge = 0,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int notificationBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _NavItem(
                selected: index == 0,
                icon: Icons.access_time_filled_rounded,
                outlineIcon: Icons.access_time_rounded,
                label: '근무',
                onTap: () => onChanged(0),
              ),
              _NavItem(
                selected: index == 1,
                icon: Icons.calendar_month_rounded,
                outlineIcon: Icons.calendar_month_outlined,
                label: '일정',
                onTap: () => onChanged(1),
              ),
              _NavItem(
                selected: index == 2,
                icon: Icons.notifications_rounded,
                outlineIcon: Icons.notifications_outlined,
                label: '알림',
                badge: notificationBadge,
                onTap: () => onChanged(2),
              ),
              _NavItem(
                selected: index == 3,
                icon: Icons.person_rounded,
                outlineIcon: Icons.person_outline_rounded,
                label: '마이',
                onTap: () => onChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.outlineIcon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final bool selected;
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.navInactive;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge', style: const TextStyle(fontSize: 10)),
              child: Icon(selected ? icon : outlineIcon, size: 24, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppType.navLabel.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
