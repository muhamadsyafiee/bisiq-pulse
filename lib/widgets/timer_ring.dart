import '../l10n/app_strings.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.progress,
    required this.seconds,
    required this.label,
    required this.color,
  });

  final double progress;
  final int seconds;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final time = seconds >= 60
        ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
        : seconds.toString().padLeft(2, '0');
    return Semantics(
      label: AppStrings.of(
        context,
      ).text('remaining', {'label': label, 'seconds': seconds}),
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 260,
          child: CustomPaint(
            painter: _RingPainter(progress: progress, color: color),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 34),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 84,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.of(context).text('seconds'),
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint..color = AppColors.border);
    for (var i = 0; i < 60; i++) {
      final angle = i / 60 * math.pi * 2 - math.pi / 2;
      final inner = radius - (i % 5 == 0 ? 21 : 18);
      final outer = radius - 14;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 1.5,
      );
    }
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint..color = color,
    );
    final angle = 2 * math.pi * progress - math.pi / 2;
    final tip = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(tip, 6, Paint()..color = color);
    canvas.drawCircle(tip, 2.5, Paint()..color = AppColors.background);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
