import '../l10n/app_strings.dart';
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
    this.workoutName,
  });
  final List<Exercise> exercises;
  final WorkoutFeedback? feedback;
  final String? workoutName;

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
      icon: Icon(Icons.emoji_events_rounded, color: AppColors.green, size: 44),
      title: Text(AppStrings.of(context).text('finishedTitle')),
      content: Text(
        AppStrings.of(context).text('finishedBody', {
          'completed': _controller.completedCount,
          'total': _controller.exercises.length,
          'skipped': _controller.skippedCount,
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(AppStrings.of(context).text('close')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _reset();
          },
          child: Text(AppStrings.of(context).text('newSession')),
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
        ? AppStrings.of(context).text('finished')
        : paused
        ? AppStrings.of(context).text('paused')
        : rest
        ? AppStrings.of(context).text('rest')
        : controller.hasStarted
        ? AppStrings.of(context).text('workout')
        : AppStrings.of(context).text('ready');
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Row(
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
            tooltip: _soundEnabled
                ? AppStrings.of(context).text('mute')
                : AppStrings.of(context).text('unmute'),
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
          SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.of(context).text('todaysWorkout'),
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
                        AppStrings.of(context).text('interval'),
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.workoutName ??
                        AppStrings.of(context).text('upperBody'),
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.1,
                    ),
                  ),
                  SizedBox(height: 14),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      _Meta(
                        icon: Icons.fitness_center_rounded,
                        text: AppStrings.of(context).text('exerciseCount', {
                          'count': controller.exercises.length,
                        }),
                      ),
                      _Meta(
                        icon: Icons.timer_outlined,
                        text: AppStrings.of(context).text('duration', {
                          'minutes': controller.totalSeconds ~/ 60,
                          'seconds': controller.totalSeconds % 60,
                        }),
                      ),
                      _Meta(
                        icon: Icons.layers_outlined,
                        text: AppStrings.of(context).text('oneRound'),
                      ),
                    ],
                  ),
                  SizedBox(height: 22),
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
                  SizedBox(height: 22),
                  Text(
                    controller.isFinished
                        ? AppStrings.of(context).text('sessionEnded')
                        : AppStrings.of(context).text('exerciseProgress', {
                            'current': (controller.index + 1)
                                .toString()
                                .padLeft(2, '0'),
                            'total': controller.exercises.length
                                .toString()
                                .padLeft(2, '0'),
                          }),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    controller.isFinished
                        ? AppStrings.of(context).text('wellDone')
                        : rest
                        ? AppStrings.of(context).text('breathe')
                        : controller.currentExercise.displayName(
                            AppStrings.of(context),
                          ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: TimerRing(
                      progress: controller.progress,
                      seconds: controller.remainingSeconds,
                      label: label,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (controller.currentExercise.assetPath
                      case final String path) ...[
                    SizedBox(
                      height: 120,
                      child: Image.asset(
                        path,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.muted,
                          size: 40,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                  Text(
                    controller.isFinished
                        ? AppStrings.of(context).text('strongerToday')
                        : rest
                        ? AppStrings.of(context).text('restAdvice')
                        : controller.currentExercise.displayDescription(
                            AppStrings.of(context),
                          ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 22),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.of(context).text('next'),
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 9,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                controller.isFinished
                                    ? AppStrings.of(context).text('newEnergy')
                                    : controller.nextExercise?.displayName(
                                            AppStrings.of(context),
                                          ) ??
                                          AppStrings.of(
                                            context,
                                          ).text('finishLine'),
                                style: TextStyle(
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
                            AppStrings.of(context).text('secondsShort', {
                              'seconds':
                                  controller.nextExercise!.workoutSeconds,
                            }),
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  FilledButton.icon(
                    key: Key('primary-control'),
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
                          ? AppStrings.of(context).text('newSession')
                          : controller.isRunning
                          ? AppStrings.of(context).text('pause')
                          : controller.hasStarted
                          ? AppStrings.of(context).text('resume')
                          : AppStrings.of(context).text('startWorkout'),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.hasStarted ? _reset : null,
                          icon: Icon(Icons.restart_alt_rounded, size: 19),
                          label: Text(
                            AppStrings.of(context).text('reset'),
                            style: TextStyle(fontSize: 11, letterSpacing: 1),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              controller.hasStarted && !controller.isFinished
                              ? controller.skip
                              : null,
                          icon: Icon(Icons.skip_next_rounded, size: 19),
                          label: Text(
                            rest
                                ? AppStrings.of(context).text('skipRest')
                                : AppStrings.of(context).text('skip'),
                            style: TextStyle(fontSize: 11, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.of(context).text('workoutPlan'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppStrings.of(context).text('oneSet'),
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
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
                  SizedBox(height: 14),
                  Row(
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
                          AppStrings.of(context).text('screenAwake'),
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
      SizedBox(width: 6),
      Text(text, style: TextStyle(color: AppColors.muted, fontSize: 11)),
    ],
  );
}
