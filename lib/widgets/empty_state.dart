import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 재사용 빈 상태. [illustration]이 있으면 아이콘 대신 사용.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    this.subtitle,
    this.iconSize = 48,
    this.illustrationSize = 72,
  }) : assert(icon != null || illustration != null);

  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String? subtitle;
  final double iconSize;
  final double illustrationSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              SizedBox(
                width: illustrationSize,
                height: illustrationSize,
                child: illustration,
              )
            else
              Icon(icon, size: iconSize, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: AppType.emptyTitle),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppType.emptySubtitle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
