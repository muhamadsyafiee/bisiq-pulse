import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/exercise.dart';
import 'package:gym_timer/services/workout_controller.dart';

void main() {
  late Duration elapsed;
  late List<WorkoutCue> cues;
  late WorkoutController timer;
  const exercises = [
    Exercise(name: 'First', workoutSeconds: 5, restSeconds: 2),
    Exercise(name: 'Second', workoutSeconds: 4, restSeconds: 8),
  ];

  setUp(() {
    elapsed = Duration.zero;
    cues = [];
    timer = WorkoutController(
      exercises: exercises,
      elapsed: () => elapsed,
      onCue: cues.add,
      automaticTicks: false,
    );
  });
  tearDown(() => timer.dispose());

  void advance(int milliseconds) {
    elapsed += Duration(milliseconds: milliseconds);
    timer.tick();
  }

  test('starts ready and excludes final rest from session duration', () {
    expect(timer.remainingSeconds, 5);
    expect(timer.progress, 1);
    expect(timer.totalSeconds, 11);
    expect(timer.isRunning, false);
    timer.skip();
    expect(timer.index, 0);
  });

  test('workout to rest to next workout to finished, no final rest', () {
    timer.startOrResume();
    advance(5000);
    expect(timer.phase, WorkoutPhase.rest);
    expect(timer.remainingSeconds, 2);
    expect(timer.completedCount, 1);
    advance(2000);
    expect(timer.index, 1);
    expect(timer.phase, WorkoutPhase.workout);
    expect(timer.remainingSeconds, 4);
    advance(4000);
    expect(timer.isFinished, true);
    expect(timer.isRunning, false);
    expect(timer.progress, 0);
    expect(timer.completedCount, 2);
    expect(cues, [
      WorkoutCue.start,
      WorkoutCue.rest,
      WorkoutCue.start,
      WorkoutCue.finished,
    ]);
  });

  test('one beep per 3, 2, 1; no duplicate subsecond beeps', () {
    timer.startOrResume();
    advance(2000);
    advance(50);
    advance(950);
    advance(1000);
    expect(cues.where((c) => c == WorkoutCue.countdown).length, 3);
  });

  test('pause freezes partial seconds and resume preserves them', () {
    timer.startOrResume();
    advance(1250);
    timer.pause();
    final progress = timer.progress;
    advance(60000);
    expect(timer.progress, progress);
    expect(timer.remainingSeconds, 4);
    timer.startOrResume();
    advance(3749);
    expect(timer.phase, WorkoutPhase.workout);
    advance(1);
    expect(timer.phase, WorkoutPhase.rest);
  });

  test(
    'background gap crosses all expired phases without drift or stale cues',
    () {
      timer.startOrResume();
      advance(8250);
      expect(timer.index, 1);
      expect(timer.phase, WorkoutPhase.workout);
      expect(timer.remainingSeconds, 3);
      expect(timer.progress, closeTo(2.75 / 4, .0001));
      expect(cues, [WorkoutCue.start, WorkoutCue.start]);
      advance(100000);
      expect(timer.isFinished, true);
      expect(timer.completedCount, 2);
    },
  );

  test(
    'skip skips workout and rest, preserves pause and counts accurately',
    () {
      timer.startOrResume();
      timer.pause();
      timer.skip();
      expect(timer.index, 1);
      expect(timer.remainingSeconds, 4);
      expect(timer.isRunning, false);
      expect(timer.skippedCount, 1);
      timer.startOrResume();
      timer.skip();
      expect(timer.isFinished, true);
      expect(timer.completedCount, 0);
      expect(timer.skippedCount, 2);
    },
  );

  test('skipping rest does not mark an exercise skipped', () {
    timer.startOrResume();
    advance(5000);
    timer.skip();
    expect(timer.index, 1);
    expect(timer.phase, WorkoutPhase.workout);
    expect(timer.isRunning, true);
    expect(timer.completedCount, 1);
    expect(timer.skippedCount, 0);
    advance(4000);
    expect(timer.isFinished, true);
  });

  test('reset cancels a running session and supports a fresh start', () {
    timer.startOrResume();
    advance(6000);
    timer.reset();
    advance(50000);
    expect(timer.hasStarted, false);
    expect(timer.phase, WorkoutPhase.workout);
    expect(timer.index, 0);
    expect(timer.remainingSeconds, 5);
    expect(timer.completedCount, 0);
    timer.startOrResume();
    advance(5000);
    expect(timer.phase, WorkoutPhase.rest);
  });

  test('zero rest advances directly and single exercise finishes', () {
    final zeroRest = WorkoutController(
      exercises: const [
        Exercise(name: 'A', workoutSeconds: 1, restSeconds: 0),
        Exercise(name: 'B', workoutSeconds: 1, restSeconds: 0),
      ],
      elapsed: () => elapsed,
      automaticTicks: false,
    );
    addTearDown(zeroRest.dispose);
    zeroRest.startOrResume();
    elapsed = const Duration(seconds: 1);
    zeroRest.tick();
    expect(zeroRest.index, 1);
    expect(zeroRest.phase, WorkoutPhase.workout);
    elapsed = const Duration(seconds: 2);
    zeroRest.tick();
    expect(zeroRest.isFinished, true);
    final single = WorkoutController(
      exercises: const [
        Exercise(name: 'A', workoutSeconds: 1, restSeconds: 10),
      ],
      elapsed: () => elapsed,
      automaticTicks: false,
    );
    addTearDown(single.dispose);
    single.startOrResume();
    elapsed += const Duration(seconds: 1);
    single.tick();
    expect(single.isFinished, true);
    expect(single.totalSeconds, 1);
  });

  test('rejects empty workout plans', () {
    expect(() => WorkoutController(exercises: []), throwsArgumentError);
  });
}
