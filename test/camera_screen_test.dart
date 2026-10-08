import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gym_timer/l10n/app_strings.dart';
import 'package:gym_timer/models/camera_display_settings.dart';
import 'package:gym_timer/services/camera_display_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/exercise.dart';
import 'package:gym_timer/models/workout_plan.dart';
import 'package:gym_timer/screens/camera_workout_screen.dart';
import 'package:gym_timer/services/camera_workout_session.dart';
import 'package:gym_timer/theme/app_theme.dart';

import 'camera_session_test.dart' show FakeCapture, FakeArchive;
import 'widget_test.dart' show FakeFeedback;

class MemoryDisplayStore extends CameraDisplayStore {
  CameraDisplaySettings value = const CameraDisplaySettings();
  @override
  Future<CameraDisplaySettings> load() async => value;
  @override
  Future<void> save(CameraDisplaySettings settings) async {
    value = settings;
  }
}

void main() {
  for (final code in AppStrings.languages.keys) {
    final strings = AppStrings(code);
    testWidgets(
      '$code camera preview shows selected routine and controls on a small phone',
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
            locale: Locale(code),
            supportedLocales: AppStrings.languages.keys.map(
              (code) => Locale(code),
            ),
            localizationsDelegates: const [
              AppStrings.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: CameraWorkoutScreen(
              plan: plan,
              session: session,
              displayStore: MemoryDisplayStore(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.text('startRecord')), findsOneWidget);
        expect(find.text('0:45'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(strings.text('switchCamera')));
        await tester.pumpAndSettle();
        expect(find.text(strings.text('backCamera')), findsOneWidget);
        await tester.ensureVisible(find.text(strings.text('startRecord')));
        await tester.tap(find.text(strings.text('startRecord')));
        await tester.pumpAndSettle();
        expect(find.text(strings.text('recordingIndicator')), findsOneWidget);
        expect(find.text(strings.text('stopSave')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'drag clamps to video frame, theme persists and recording locks controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryDisplayStore();
      final plan = WorkoutPlan(
        id: 'drag',
        name: 'Drag workout',
        exercises: const [
          Exercise(name: 'Squat', workoutSeconds: 20, restSeconds: 0),
        ],
      );
      CameraWorkoutSession session() => CameraWorkoutSession(
        plan: plan,
        capture: FakeCapture(),
        archive: FakeArchive(),
        feedback: FakeFeedback(),
        automaticTicks: false,
      );
      final first = session();
      Future<void> show(CameraWorkoutSession active) => tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: CameraWorkoutScreen(
            plan: plan,
            session: active,
            displayStore: store,
          ),
        ),
      );
      await show(first);
      await tester.pumpAndSettle();
      final panel = find.byKey(const Key('draggable-camera-panel'));
      final before = tester.getTopLeft(panel);
      await tester.drag(panel, const Offset(-1000, -1000));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panel).dy, lessThan(before.dy));
      expect(first.display.x, 0);
      expect(first.display.y, 0);
      await tester.tap(find.text('Lutsinar'));
      await tester.pumpAndSettle();
      final surface = tester.widget<Container>(
        find.byKey(const Key('camera-panel-surface')),
      );
      expect((surface.decoration as BoxDecoration).color, Colors.transparent);
      expect(store.value.transparent, true);
      expect(store.value.y, 0);
      await tester.pumpWidget(const SizedBox());
      final reopened = session();
      await show(reopened);
      await tester.pumpAndSettle();
      expect(reopened.display.toJson(), store.value.toJson());
      await tester.tap(find.byTooltip('Reset paparan'));
      await tester.pumpAndSettle();
      expect(reopened.display.y, .92);
      expect(reopened.display.transparent, false);
      await tester.ensureVisible(find.text('MULA & RAKAM'));
      await tester.tap(find.text('MULA & RAKAM'));
      await tester.pumpAndSettle();
      await tester.drag(panel, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(reopened.display.y, .92);
      expect(
        tester.widget<ChoiceChip>(find.byType(ChoiceChip).last).onSelected,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
