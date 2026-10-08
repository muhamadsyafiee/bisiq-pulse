import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/main.dart';
import 'package:gym_timer/l10n/app_strings.dart';
import 'package:gym_timer/l10n/messages.dart';
import 'package:gym_timer/services/language_controller.dart';
import 'package:gym_timer/data/workout_presets.dart';
import 'package:gym_timer/models/exercise.dart';
import 'package:gym_timer/models/workout_plan.dart';
import 'language_test_support.dart';
import 'workout_library_test.dart' show MemoryLibraryStorage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('pulse/video'),
          (call) async => null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('pulse/video'), null);
  });
  test('all language packs have every message and identical placeholders', () {
    final base = messages['ms']!;
    final placeholders = RegExp(r'\{\w+\}');
    for (final language in AppStrings.languages.keys) {
      final pack = messages[language]!;
      expect(pack.keys.toSet(), base.keys.toSet());
      expect(
        jsonDecode(File('lib/l10n/$language.json').readAsStringSync()),
        pack,
      );
      for (final key in base.keys) {
        expect(pack[key]!.trim(), isNotEmpty);
        expect(
          placeholders.allMatches(pack[key]!).map((m) => m[0]).toSet(),
          placeholders.allMatches(base[key]!).map((m) => m[0]).toSet(),
        );
      }
    }
    expect(
      const AppStrings('en').text('nextExercise', {'name': 'Custom {name}'}),
      'Next: Custom {name}',
    );
  });
  test(
    'fresh install defaults to Malay; selection persists and failed writes retain language',
    () async {
      final store = MemoryLanguageStorage();
      final controller = LanguageController(store);
      await controller.load();
      expect(controller.code, 'ms');
      expect(await controller.select('ar'), true);
      final reopened = LanguageController(store);
      await reopened.load();
      expect(reopened.code, 'ar');
      store.fail = true;
      expect(await reopened.select('en'), false);
      expect(reopened.code, 'ar');
      expect(await reopened.select('unsupported'), false);
      controller.dispose();
      reopened.dispose();
    },
  );
  test(
    'only exact legacy templates are tagged; custom text remains verbatim',
    () {
      final original = WorkoutPlan(
        id: 'legacy',
        name: 'Upper Body',
        exercises: defaultExercises,
      );
      expect(
        tagLegacyTemplate(original).displayName(const AppStrings('zh')),
        '上肢训练',
      );
      final custom = WorkoutPlan(
        id: 'custom',
        name: 'My workout',
        exercises: const [
          Exercise(
            name: 'Squat',
            workoutSeconds: 7,
            restSeconds: 0,
            description: 'My notes',
          ),
        ],
      );
      for (final code in AppStrings.languages.keys) {
        expect(custom.localized(AppStrings(code)).name, 'My workout');
        expect(
          custom.localized(AppStrings(code)).exercises.single.name,
          'Squat',
        );
      }
    },
  );
  for (final code in AppStrings.languages.keys) {
    testWidgets(
      '$code onboarding, settings and templates fully switch at narrow width',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final localeStore = MemoryLanguageStorage();
        await tester.pumpWidget(
          WorkoutTimerApp(
            storage: MemoryLibraryStorage(),
            languageStorage: localeStore,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(const AppStrings('ms').text('welcomeTitle')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('onboarding-language')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(Key('language-$code')));
        await tester.tap(find.byKey(Key('language-$code')));
        await tester.pumpAndSettle();
        final s = AppStrings(code);
        expect(find.text(s.text('settings')), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.text(s.text('settings')))),
          code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text(s.text('welcomeTitle')), findsOneWidget);
        await tester.ensureVisible(find.text(s.text('useTemplate')));
        await tester.tap(find.text(s.text('useTemplate')));
        await tester.pumpAndSettle();
        expect(find.text(s.text('upperBody')), findsOneWidget);
        await tester.tap(find.text(s.text('upperBody')));
        await tester.pumpAndSettle();
        expect(find.text(s.text('routineName')), findsOneWidget);
        expect(find.text(s.text('pushup')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('save-routine')));
        await tester.tap(find.byKey(const Key('save-routine')));
        await tester.pumpAndSettle();
        expect(find.text(s.text('myWorkouts')), findsOneWidget);
        expect(find.text(s.text('upperBody')), findsOneWidget);
        await tester.tap(find.byTooltip(s.text('settings')));
        await tester.pumpAndSettle();
        final nextCode = code == 'en' ? 'ms' : 'en';
        await tester.tap(find.byKey(Key('language-$nextCode')));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          find.text(AppStrings(nextCode).text('upperBody')),
          findsOneWidget,
        );
        expect(localeStore.value, nextCode);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
