import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 동일 너비 필 세그먼트. 스크린샷 「진행중 공고 / 지원 내역」 패턴.
///
/// - 선택: soft purple 배경 + primary 텍스트
/// - 비선택: 밝은 중립 배경 + muted 텍스트
class SegmentedPills extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 40,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Pill(
              label: labels[i],
              selected: i == index,
              height: height,
              onTap: () => onChanged(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primarySoft : const Color(0xFFF7F8FA);
    final style = selected
        ? AppType.tabSelected
        : AppType.tabUnselected;

    return Material(
      color: bg,
      borderRadius: AppRadii.pillAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillAll,
        child: SizedBox(
          height: height,
          child: Center(child: Text(label, style: style)),
        ),
      ),
    );
  }
}
