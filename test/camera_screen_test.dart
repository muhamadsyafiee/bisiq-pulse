import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/exercise.dart';
import 'package:gym_timer/models/workout_plan.dart';
import 'package:gym_timer/screens/camera_workout_screen.dart';
import 'package:gym_timer/services/camera_workout_session.dart';
import 'package:gym_timer/theme/app_theme.dart';

import 'camera_session_test.dart' show FakeCapture, FakeArchive;
import 'widget_test.dart' show FakeFeedback;

void main() {
  testWidgets(
    'camera preview shows selected routine and controls on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final plan = WorkoutPlan(
        id: 'test',
        name: 'Latihan pagi yang panjang',
        exercises: const [
          Exercise(
            name: 'Mountain Climbers',
            workoutSeconds: 45,
            restSeconds: 10,
          ),
        ],
      );
      final session = CameraWorkoutSession(
        plan: plan,
        capture: FakeCapture(),
        archive: FakeArchive(),
        feedback: FakeFeedback(),
        automaticTicks: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: CameraWorkoutScreen(plan: plan, session: session),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MULA & RAKAM'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Tukar kamera'));
      await tester.pumpAndSettle();
      expect(find.text('Kamera belakang'), findsOneWidget);
      await tester.ensureVisible(find.text('MULA & RAKAM'));
      await tester.tap(find.text('MULA & RAKAM'));
      await tester.pumpAndSettle();
      expect(find.text('REC'), findsOneWidget);
      expect(find.text('HENTI & SIMPAN'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
