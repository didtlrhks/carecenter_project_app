import 'package:flutter/material.dart';

import '../utils/labels.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  final String status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = candidateBadgeColors(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        candidateBadge(status),
        style: TextStyle(
          fontSize: large ? 15 : 12,
          fontWeight: FontWeight.w700,
          color: colors.$2,
        ),
      ),
    );
  }
}
