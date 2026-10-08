import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/exercise.dart';
import 'package:gym_timer/screens/workout_screen.dart';
import 'package:gym_timer/services/workout_controller.dart';
import 'package:gym_timer/services/workout_feedback.dart';
import 'package:gym_timer/theme/app_theme.dart';

class FakeFeedback implements WorkoutFeedback {
  final cues = <WorkoutCue>[];
  bool awake = false;
  @override
  Future<void> play(WorkoutCue cue) async {
    cues.add(cue);
  }

  @override
  Future<void> setAwake(bool enabled) async {
    awake = enabled;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {
    awake = false;
  }
}

void main() {
  testWidgets('start, pause, resume, reset and mute work on a phone layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final feedback = FakeFeedback();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WorkoutScreen(feedback: feedback),
      ),
    );
    expect(find.text('PULSE'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('primary-control')));
    await tester.tap(find.text('MULA LATIHAN'));
    await tester.pump();
    expect(feedback.awake, true);
    expect(feedback.cues, [WorkoutCue.start]);
    await tester.tap(find.text('JEDA'));
    await tester.pump();
    expect(find.text('SAMBUNG'), findsOneWidget);
    expect(feedback.awake, false);
    await tester.tap(find.text('SAMBUNG'));
    await tester.pump();
    expect(feedback.awake, true);
    await tester.ensureVisible(find.text('SEMULA'));
    await tester.tap(find.text('SEMULA'));
    await tester.pump();
    expect(find.text('MULA LATIHAN'), findsOneWidget);
    expect(feedback.awake, false);
    await tester.tap(find.byTooltip('Matikan bunyi'));
    await tester.pump();
    expect(find.byTooltip('Hidupkan bunyi'), findsOneWidget);
    await tester.tap(find.text('MULA LATIHAN'));
    await tester.pump();
    expect(feedback.cues.length, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(feedback.awake, false);
  });

  testWidgets('last skip shows completion dialog and new session resets', (
    tester,
  ) async {
    final feedback = FakeFeedback();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WorkoutScreen(
          feedback: feedback,
          exercises: const [
            Exercise(name: 'Test workout', workoutSeconds: 20, restSeconds: 10),
          ],
        ),
      ),
    );
    await tester.ensureVisible(find.text('MULA LATIHAN'));
    await tester.tap(find.text('MULA LATIHAN'));
    await tester.pump();
    await tester.ensureVisible(find.text('LANGKAU'));
    await tester.tap(find.text('LANGKAU'));
    await tester.pumpAndSettle();
    expect(find.text('Workout Finished'), findsOneWidget);
    expect(find.textContaining('1 gerakan dilangkau'), findsOneWidget);
    expect(feedback.awake, false);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('SESI BAHARU'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MULA LATIHAN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screens and enlarged text do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: WorkoutScreen(feedback: FakeFeedback()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
