import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 스크린샷의 물결 하단 스탬프 + X 일러스트 (근무 빈 상태).
class EmptyDutyIllustration extends StatelessWidget {
  const EmptyDutyIllustration({
    super.key,
    this.size = 72,
    this.color = AppColors.primaryMid,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DutyStampPainter(color: color),
    );
  }
}

class _DutyStampPainter extends CustomPainter {
  _DutyStampPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.16;
    final waveAmp = h * 0.09;
    final bodyH = h * 0.78;

    final path = Path()..moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, bodyH);

    const steps = 48;
    for (var i = steps; i >= 0; i--) {
      final t = i / steps;
      final x = t * w;
      final y = bodyH + math.sin(t * math.pi * 5) * waveAmp + waveAmp * 0.15;
      path.lineTo(x, y);
    }

    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    final xPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round;

    final cx = w * 0.5;
    final cy = h * 0.36;
    final arm = w * 0.155;
    canvas.drawLine(Offset(cx - arm, cy - arm), Offset(cx + arm, cy + arm), xPaint);
    canvas.drawLine(Offset(cx + arm, cy - arm), Offset(cx - arm, cy + arm), xPaint);

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.32, h * 0.54), Offset(w * 0.68, h * 0.54), linePaint);
  }

  @override
  bool shouldRepaint(covariant _DutyStampPainter oldDelegate) => oldDelegate.color != color;
}
