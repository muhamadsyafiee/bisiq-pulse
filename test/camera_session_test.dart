import 'package:gym_timer/models/camera_display_settings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/exercise.dart';
import 'package:gym_timer/models/workout_plan.dart';
import 'package:gym_timer/models/workout_recording.dart';
import 'package:gym_timer/services/camera_workout_session.dart';
import 'package:gym_timer/services/recording_archive.dart';
import 'package:gym_timer/services/video_capture.dart';

import 'widget_test.dart' show FakeFeedback;

class FakeCapture implements VideoCapture {
  @override
  bool ready = false;
  @override
  double get portraitAspectRatio => 9 / 16;
  @override
  bool front = true;
  @override
  bool canSwitch = true;
  bool failInitialize = false, failStart = false;
  int starts = 0, stops = 0, flips = 0;
  Completer<void>? startGate;
  @override
  Future<void> initialize({required bool microphone}) async {
    if (failInitialize) throw StateError('permission denied');
    ready = true;
  }

  @override
  Future<void> switchCamera({required bool microphone}) async {
    front = !front;
    flips++;
  }

  @override
  Future<void> start() async {
    starts++;
    if (failStart) throw StateError('recorder failed');
    await startGate?.future;
  }

  @override
  Future<String> stop() async {
    stops++;
    return '/camera/temp.mp4';
  }

  @override
  Future<void> close() async {
    ready = false;
  }

  @override
  Widget preview() => const ColoredBox(color: Colors.blueGrey);
}

class FakeArchive implements RecordingArchive {
  bool failKeep = false;
  final items = <WorkoutRecording>[];
  @override
  Future<WorkoutRecording> keep(
    String source,
    WorkoutPlan plan, {
    CameraDisplaySettings? display,
  }) async {
    if (failKeep) throw StateError('disk full');
    final item = WorkoutRecording(
      id: 'recording',
      plan: plan,
      display: display,
      createdAt: DateTime(2026),
    );
    items.add(item);
    return item;
  }

  @override
  Future<List<WorkoutRecording>> list() async => items;
  @override
  Future<WorkoutRecording> export(WorkoutRecording recording) async =>
      recording.copyWith(exported: true);
  @override
  Future<WorkoutRecording> saveToGallery(WorkoutRecording recording) async =>
      recording.copyWith(gallerySaved: true);
  @override
  Future<void> delete(WorkoutRecording recording) async =>
      items.remove(recording);
}

void main() {
  late FakeCapture capture;
  late FakeArchive archive;
  late FakeFeedback feedback;
  late CameraWorkoutSession session;
  late Duration elapsed;
  setUp(() {
    elapsed = Duration.zero;
    capture = FakeCapture();
    archive = FakeArchive();
    feedback = FakeFeedback();
    session = CameraWorkoutSession(
      plan: WorkoutPlan(
        id: 'plan',
        name: 'Camera workout',
        exercises: const [
          Exercise(name: 'Squat', workoutSeconds: 3, restSeconds: 2),
          Exercise(name: 'Plank', workoutSeconds: 2, restSeconds: 0),
        ],
      ),
      capture: capture,
      archive: archive,
      feedback: feedback,
      elapsed: () => elapsed,
      automaticTicks: false,
    );
  });
  tearDown(() => session.dispose());

  test('permission denial never starts workout and can be retried', () async {
    capture.failInitialize = true;
    await session.initialize();
    expect(session.status, CaptureStatus.error);
    await session.start();
    expect(capture.starts, 0);
    expect(session.timer.hasStarted, false);
    capture.failInitialize = false;
    await session.initialize();
    expect(session.status, CaptureStatus.ready);
  });
  test(
    'timer waits for recorder; repeated start and stop are idempotent',
    () async {
      await session.initialize();
      capture.startGate = Completer<void>();
      final start = session.start();
      await Future<void>.delayed(Duration.zero);
      expect(session.status, CaptureStatus.starting);
      expect(session.timer.isRunning, false);
      final duplicate = session.start();
      capture.startGate!.complete();
      await start;
      await duplicate;
      expect(capture.starts, 1);
      expect(session.timer.isRunning, true);
      expect(feedback.awake, true);
      await Future.wait([session.stop(), session.stop()]);
      expect(capture.stops, 1);
      expect(archive.items.length, 1);
      expect(feedback.awake, false);
      // Cleanup must finish before the next route acquires its screen lock.
      expect(feedback.disposeCalls, 1);
    },
  );
  test('start failure leaves timer ready', () async {
    await session.initialize();
    capture.failStart = true;
    await session.start();
    expect(session.timer.hasStarted, false);
    expect(session.status, CaptureStatus.ready);
    expect(session.error, isNotNull);
  });
  test(
    'camera switches before start and stays fixed while recording',
    () async {
      await session.initialize();
      await session.switchCamera();
      expect(capture.front, false);
      await session.setMicrophone(true);
      expect(session.microphone, true);
      await session.start();
      await session.switchCamera();
      await session.setMicrophone(false);
      expect(capture.flips, 1);
      expect(session.microphone, true);
      await session.stop();
    },
  );
  test(
    'automatic finish records the full workout and preserves video once',
    () async {
      await session.initialize();
      await session.start();
      elapsed = const Duration(seconds: 3);
      session.timer.tick();
      expect(session.isRecording, true);
      elapsed = const Duration(seconds: 7);
      session.timer.tick();
      await session.stop();
      expect(session.timer.isFinished, true);
      expect(session.recording!.plan.name, 'Camera workout');
      expect(capture.stops, 1);
      expect(session.status, CaptureStatus.finished);
    },
  );
  test(
    'background during start serializes stop, saves, and does not restart',
    () async {
      await session.initialize();
      capture.startGate = Completer<void>();
      final start = session.start();
      await Future<void>.delayed(Duration.zero);
      final background = session.suspend();
      capture.startGate!.complete();
      await start;
      await background;
      await session.resume();
      expect(session.interrupted, true);
      expect(capture.stops, 1);
      expect(capture.starts, 1);
      expect(capture.ready, false);
      expect(session.timer.isRunning, false);
      expect(session.recording, isNotNull);
    },
  );
  test('recording snapshots display and rejects changes after start', () async {
    await session.initialize();
    session.setDisplay(
      const CameraDisplaySettings(x: .2, y: .1, transparent: true),
    );
    await session.start();
    session.setDisplay(const CameraDisplaySettings());
    archive.failKeep = true;
    await session.stop();
    session.setDisplay(const CameraDisplaySettings());
    archive.failKeep = false;
    await session.retrySave();
    expect(archive.items.single.display!.toJson(), {
      'x': .2,
      'y': .1,
      'transparent': true,
    });
  });
  test('failed storage keeps stopped file available for retry', () async {
    await session.initialize();
    await session.start();
    archive.failKeep = true;
    await session.stop();
    expect(session.hasPendingVideo, true);
    expect(session.status, CaptureStatus.error);
    expect(feedback.awake, false);
    await session.resume();
    expect(capture.ready, false);
    archive.failKeep = false;
    await session.retrySave();
    expect(session.recording, isNotNull);
    expect(session.hasPendingVideo, false);
    expect(capture.stops, 1);
  });
}
