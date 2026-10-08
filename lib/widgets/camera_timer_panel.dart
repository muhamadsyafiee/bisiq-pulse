import 'package:flutter/material.dart';
import '../models/camera_display_settings.dart';
import '../models/workout_plan.dart';
import '../services/workout_controller.dart';
import '../theme/app_theme.dart';

/// Uses the same proportions as the Android video overlay.
class CameraTimerPanel extends StatelessWidget {
  const CameraTimerPanel({
    super.key,
    required this.plan,
    required this.timer,
    required this.settings,
    required this.recording,
  });
  final WorkoutPlan plan;
  final WorkoutController timer;
  final CameraDisplaySettings settings;
  final bool recording;

  @override
  Widget build(BuildContext context) {
    final rest = timer.phase == WorkoutPhase.rest;
    final color = rest ? AppColors.orange : AppColors.green;
    Widget line(
      String value,
      double top,
      double size,
      Color color, {
      double left = 18,
      double width = 364,
    }) => Positioned(
      left: left,
      top: top,
      width: width,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: size,
          height: 1.1,
          color: color,
          fontWeight: FontWeight.w700,
          shadows: settings.transparent
              ? const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
    );
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        key: const Key('camera-panel-surface'),
        width: 400,
        height: 172,
        decoration: BoxDecoration(
          color: settings.transparent
              ? Colors.transparent
              : const Color(0xDA101412),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            line('PULSE  •  ${plan.name}', 13, 13, Colors.white70),
            line(
              '${recording ? (rest ? 'REHAT' : 'SENAMAN') : 'BERSEDIA'}  •  GERAKAN ${timer.index + 1}/${plan.exercises.length}',
              38,
              12,
              color,
            ),
            line(
              rest ? 'Tarik nafas seketika.' : timer.currentExercise.name,
              58,
              22,
              Colors.white,
            ),
            line(
              '${timer.remainingSeconds ~/ 60}:${(timer.remainingSeconds % 60).toString().padLeft(2, '0')}',
              86,
              50,
              color,
              width: 255,
            ),
            line('SAAT', 112, 13, Colors.white70, left: 284, width: 96),
            line(
              'Seterusnya: ${timer.nextExercise?.name ?? 'Selesai'}',
              146,
              12,
              Colors.white70,
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 3,
              child: LinearProgressIndicator(
                value: timer.progress,
                minHeight: 2,
                color: color,
                backgroundColor: Colors.white12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
