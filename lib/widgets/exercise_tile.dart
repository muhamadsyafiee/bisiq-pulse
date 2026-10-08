import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme/app_theme.dart';

class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exercise,
    required this.number,
    required this.active,
    required this.passed,
    required this.color,
    required this.isLast,
  });

  final Exercise exercise;
  final int number;
  final bool active;
  final bool passed;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: active ? color.withValues(alpha: 0.07) : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: active ? color.withValues(alpha: 0.45) : AppColors.surface,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active ? color : AppColors.border,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString().padLeft(2, '0'),
            style: TextStyle(
              color: active ? AppColors.background : AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: passed ? AppColors.muted : AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${exercise.workoutSeconds}s senaman${isLast ? ' • Penamat' : ' / ${exercise.restSeconds}s rehat'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (active)
          Icon(Icons.equalizer_rounded, color: color, size: 21)
        else if (passed)
          const Icon(Icons.remove_rounded, color: AppColors.muted, size: 19),
      ],
    ),
  );
}
