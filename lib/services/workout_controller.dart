import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/exercise.dart';

enum WorkoutPhase { workout, rest, finished }

enum WorkoutCue { countdown, start, rest, finished }

/// Uses elapsed time rather than counting timer callbacks, so delayed frames or
/// a suspended UI do not introduce drift. The clock is injectable for tests.
class WorkoutController extends ChangeNotifier {
  WorkoutController({
    required List<Exercise> exercises,
    Duration Function()? elapsed,
    this.onCue,
    this.automaticTicks = true,
  }) : exercises = List.unmodifiable(exercises) {
    if (exercises.isEmpty ||
        exercises.any((e) => e.workoutSeconds <= 0 || e.restSeconds < 0)) {
      throw ArgumentError('Provide exercises with positive workout durations.');
    }
    _stopwatch.start();
    _elapsed = elapsed ?? (() => _stopwatch.elapsed);
    _remaining = Duration(seconds: currentExercise.workoutSeconds);
  }

  final List<Exercise> exercises;
  final void Function(WorkoutCue cue)? onCue;
  final bool automaticTicks;
  final Stopwatch _stopwatch = Stopwatch();
  late final Duration Function() _elapsed;
  Timer? _ticker;
  late Duration _remaining;
  Duration? _deadline;
  int _index = 0;
  int _completedCount = 0;
  int _skippedCount = 0;
  WorkoutPhase _phase = WorkoutPhase.workout;
  bool _running = false;
  bool _started = false;

  int get index => _index;
  int get completedCount => _completedCount;
  int get skippedCount => _skippedCount;
  WorkoutPhase get phase => _phase;
  bool get isRunning => _running;
  bool get hasStarted => _started;
  bool get isFinished => _phase == WorkoutPhase.finished;
  Exercise get currentExercise => exercises[_index];
  Exercise? get nextExercise =>
      _index + 1 < exercises.length ? exercises[_index + 1] : null;
  int get remainingSeconds => (_remaining.inMilliseconds / 1000).ceil();
  int get phaseSeconds => _phase == WorkoutPhase.rest
      ? currentExercise.restSeconds
      : currentExercise.workoutSeconds;
  double get progress => isFinished
      ? 0
      : (_remaining.inMicroseconds / (phaseSeconds * 1000000)).clamp(0, 1);
  int get totalSeconds => exercises.asMap().entries.fold(
    0,
    (sum, entry) =>
        sum +
        entry.value.workoutSeconds +
        (entry.key == exercises.length - 1 ? 0 : entry.value.restSeconds),
  );

  void startOrResume() {
    if (_running || isFinished) return;
    final firstStart = !_started;
    _started = true;
    _running = true;
    _deadline = _elapsed() + _remaining;
    if (automaticTicks) {
      _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => tick());
    }
    if (firstStart) onCue?.call(WorkoutCue.start);
    notifyListeners();
  }

  void pause() {
    if (!_running) return;
    tick();
    if (isFinished) return;
    _running = false;
    _deadline = null;
    _ticker?.cancel();
    notifyListeners();
  }

  /// Advances through ALL expired intervals, including after a background gap.
  /// Only the current cue plays; stale beeps are never replayed in a burst.
  void tick({bool emitCue = true}) {
    if (!_running) return;
    final now = _elapsed();
    final previousSeconds = remainingSeconds;
    var transitioned = false;
    while (_running && now >= _deadline!) {
      final boundary = _deadline!;
      _advance();
      transitioned = true;
      if (!isFinished) _deadline = boundary + _remaining;
    }
    if (_running) _remaining = _deadline! - now;
    if (emitCue) {
      if (transitioned) {
        onCue?.call(_cueForPhase);
      } else if (remainingSeconds != previousSeconds &&
          remainingSeconds >= 1 &&
          remainingSeconds <= 3) {
        onCue?.call(WorkoutCue.countdown);
      }
    }
    notifyListeners();
  }

  WorkoutCue get _cueForPhase => switch (_phase) {
    WorkoutPhase.workout => WorkoutCue.start,
    WorkoutPhase.rest => WorkoutCue.rest,
    WorkoutPhase.finished => WorkoutCue.finished,
  };

  void _advance() {
    if (_phase == WorkoutPhase.workout) {
      _completedCount++;
      if (_index == exercises.length - 1) {
        _finish();
        return;
      }
      if (currentExercise.restSeconds > 0) {
        _phase = WorkoutPhase.rest;
        _remaining = Duration(seconds: currentExercise.restSeconds);
        return;
      }
    }
    _index++;
    _phase = WorkoutPhase.workout;
    _remaining = Duration(seconds: currentExercise.workoutSeconds);
  }

  /// During workout, skips that exercise and its rest. During rest, skips only
  /// the rest. A paused session stays paused after skipping.
  void skip() {
    if (!_started || isFinished) return;
    tick();
    if (isFinished) return;
    if (_phase == WorkoutPhase.workout) _skippedCount++;
    if (_index == exercises.length - 1) {
      _finish();
    } else {
      _index++;
      _phase = WorkoutPhase.workout;
      _remaining = Duration(seconds: currentExercise.workoutSeconds);
      _deadline = _running ? _elapsed() + _remaining : null;
    }
    if (_running || isFinished) onCue?.call(_cueForPhase);
    notifyListeners();
  }

  void _finish() {
    _phase = WorkoutPhase.finished;
    _remaining = Duration.zero;
    _running = false;
    _deadline = null;
    _ticker?.cancel();
  }

  void reset() {
    _ticker?.cancel();
    _index = 0;
    _completedCount = 0;
    _skippedCount = 0;
    _phase = WorkoutPhase.workout;
    _started = false;
    _running = false;
    _deadline = null;
    _remaining = Duration(seconds: currentExercise.workoutSeconds);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
