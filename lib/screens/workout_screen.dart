import 'dart:async';

import 'package:flutter/material.dart';

import '../data/workout_presets.dart';
import '../models/exercise.dart';
import '../services/workout_controller.dart';
import '../services/workout_feedback.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/timer_ring.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    this.exercises = defaultExercises,
    this.feedback,
    this.workoutName = 'Upper body.\nStronger you.',
  });
  final List<Exercise> exercises;
  final WorkoutFeedback? feedback;
  final String workoutName;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  late final WorkoutFeedback _feedback;
  late final WorkoutController _controller;
  bool _soundEnabled = true;
  bool _foreground = true;
  bool _awake = false;
  bool _finishShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _feedback = widget.feedback ?? DeviceWorkoutFeedback();
    _controller = WorkoutController(
      exercises: widget.exercises,
      onCue: (cue) {
        if (_soundEnabled && _foreground) unawaited(_feedback.play(cue));
      },
    )..addListener(_onChanged);
  }

  void _onChanged() {
    final awake = _controller.isRunning && _foreground;
    if (_awake != awake) {
      _awake = awake;
      unawaited(_feedback.setAwake(awake));
    }
    if (_controller.isFinished && !_finishShown && _foreground) {
      _finishShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showFinished();
      });
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _controller.tick(emitCue: false);
      // The OS can clear a screen lock while the app is backgrounded.
      unawaited(_feedback.setAwake(_controller.isRunning));
    } else {
      unawaited(_feedback.stop());
    }
    _onChanged();
  }

  void _reset() {
    unawaited(_feedback.stop());
    _finishShown = false;
    _controller.reset();
  }

  Future<void> _showFinished() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(
        Icons.emoji_events_rounded,
        color: AppColors.green,
        size: 44,
      ),
      title: const Text('Workout Finished'),
      content: Text(
        '${_controller.completedCount} daripada ${_controller.exercises.length} gerakan selesai.\n${_controller.skippedCount > 0 ? '${_controller.skippedCount} gerakan dilangkau.\n' : ''}\nTarik nafas. Anda sudah melakukannya.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('TUTUP'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _reset();
          },
          child: const Text('SESI BAHARU'),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    unawaited(_feedback.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final rest = controller.phase == WorkoutPhase.rest;
    final color = rest ? AppColors.orange : AppColors.green;
    final paused =
        controller.hasStarted &&
        !controller.isRunning &&
        !controller.isFinished;
    final label = controller.isFinished
        ? 'SELESAI'
        : paused
        ? 'DIJEDA'
        : rest
        ? 'REHAT'
        : controller.hasStarted
        ? 'SENAMAN'
        : 'BERSEDIA';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.green, size: 29),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'PULSE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _soundEnabled ? 'Matikan bunyi' : 'Hidupkan bunyi',
            onPressed: () {
              setState(() => _soundEnabled = !_soundEnabled);
              if (!_soundEnabled) unawaited(_feedback.stop());
            },
            icon: Icon(
              _soundEnabled
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LATIHAN HARI INI',
                          style: TextStyle(
                            color: AppColors.muted,
                            letterSpacing: 2,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.circle, color: AppColors.green, size: 6),
                      SizedBox(width: 6),
                      Text(
                        'INTERVAL',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.workoutName,
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      _Meta(
                        icon: Icons.fitness_center_rounded,
                        text: '${controller.exercises.length} gerakan',
                      ),
                      _Meta(
                        icon: Icons.timer_outlined,
                        text:
                            '${controller.totalSeconds ~/ 60}m ${controller.totalSeconds % 60}s',
                      ),
                      const _Meta(
                        icon: Icons.layers_outlined,
                        text: '1 pusingan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: List.generate(
                      controller.exercises.length,
                      (i) => Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(
                            right: i == controller.exercises.length - 1 ? 0 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: controller.isFinished || i < controller.index
                                ? AppColors.green
                                : i == controller.index
                                ? color
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    controller.isFinished
                        ? 'SESI TAMAT'
                        : 'GERAKAN ${(controller.index + 1).toString().padLeft(2, '0')} / ${controller.exercises.length.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    controller.isFinished
                        ? 'Syabas. Terus konsisten.'
                        : rest
                        ? 'Tarik nafas seketika.'
                        : controller.currentExercise.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TimerRing(
                      progress: controller.progress,
                      seconds: controller.remainingSeconds,
                      label: label,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (controller.currentExercise.assetPath
                      case final String path) ...[
                    SizedBox(
                      height: 120,
                      child: Image.asset(
                        path,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.muted,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    controller.isFinished
                        ? 'Satu langkah lebih kuat hari ini.'
                        : rest
                        ? 'Rehatkan otot. Bersedia untuk gerakan seterusnya.'
                        : controller.currentExercise.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.nextExercise == null
                              ? Icons.flag_outlined
                              : Icons.subdirectory_arrow_right_rounded,
                          color: color,
                          size: 24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SETERUSNYA',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 9,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                controller.isFinished
                                    ? 'Sesi baharu, semangat baharu'
                                    : controller.nextExercise?.name ??
                                          'Garisan penamat',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (controller.nextExercise != null &&
                            !controller.isFinished)
                          Text(
                            '${controller.nextExercise!.workoutSeconds}s',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('primary-control'),
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: () {
                      if (controller.isFinished) {
                        _reset();
                      } else if (controller.isRunning) {
                        controller.pause();
                        unawaited(_feedback.stop());
                      } else {
                        controller.startOrResume();
                      }
                    },
                    icon: Icon(
                      controller.isFinished
                          ? Icons.replay_rounded
                          : controller.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 24,
                    ),
                    label: Text(
                      controller.isFinished
                          ? 'SESI BAHARU'
                          : controller.isRunning
                          ? 'JEDA'
                          : controller.hasStarted
                          ? 'SAMBUNG'
                          : 'MULA LATIHAN',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.hasStarted ? _reset : null,
                          icon: const Icon(Icons.restart_alt_rounded, size: 19),
                          label: const Text(
                            'SEMULA',
                            style: TextStyle(fontSize: 11, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              controller.hasStarted && !controller.isFinished
                              ? controller.skip
                              : null,
                          icon: const Icon(Icons.skip_next_rounded, size: 19),
                          label: Text(
                            rest ? 'LANGKAU REHAT' : 'LANGKAU',
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pelan latihan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '01 SET',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...controller.exercises.asMap().entries.map(
                    (entry) => ExerciseTile(
                      exercise: entry.value,
                      number: entry.key + 1,
                      active:
                          !controller.isFinished &&
                          entry.key == controller.index,
                      passed:
                          controller.isFinished || entry.key < controller.index,
                      color: color,
                      isLast: entry.key == controller.exercises.length - 1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        color: AppColors.muted,
                        size: 13,
                      ),
                      SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Skrin kekal aktif semasa latihan berjalan',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.muted),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
    ],
  );
}
