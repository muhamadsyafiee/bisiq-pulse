import 'package:flutter/services.dart';
import 'language_test_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/main.dart';
import 'package:gym_timer/screens/workout_editor_screen.dart';
import 'package:gym_timer/services/workout_library.dart';
import 'package:gym_timer/theme/app_theme.dart';

import 'workout_library_test.dart' show MemoryLibraryStorage, plan;

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String key, String text) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

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
  testWidgets(
    'first-time template import is editable and persists on restart',
    (tester) async {
      final storage = MemoryLibraryStorage();
      await tester.pumpWidget(
        WorkoutTimerApp(
          storage: storage,
          languageStorage: MemoryLanguageStorage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bermula dengan\nrentak anda.'), findsOneWidget);
      await tapVisible(tester, find.text('Guna template'));
      await tapVisible(tester, find.text('Bahagian Atas Badan'));
      await fill(tester, 'routine-name', 'Dada pagi');
      await fill(tester, 'work-0', '35');
      await tapVisible(tester, find.byKey(const Key('save-routine')));
      expect(find.text('Latihan Saya'), findsOneWidget);
      expect(find.text('Dada pagi'), findsOneWidget);
      final loaded = WorkoutLibrary(storage);
      addTearDown(loaded.dispose);
      await loaded.load();
      expect(loaded.plans.single.exercises.first.workoutSeconds, 35);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        WorkoutTimerApp(
          storage: storage,
          languageStorage: MemoryLanguageStorage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Latihan Saya'), findsOneWidget);
      expect(find.text('Guna template'), findsNothing);
      await tapVisible(tester, find.text('BUKA PEMASA'));
      expect(find.text('Dada pagi'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
    },
  );

  testWidgets(
    'custom routine validates, reorders exercises, and saves many plans',
    (tester) async {
      final storage = MemoryLibraryStorage();
      await tester.pumpWidget(
        WorkoutTimerApp(
          storage: storage,
          languageStorage: MemoryLanguageStorage(),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Cipta latihan sendiri'));
      await tapVisible(tester, find.byKey(const Key('save-routine')));
      expect(find.text('Masukkan nama latihan'), findsOneWidget);
      expect(storage.document, isNull);
      await fill(tester, 'routine-name', 'Latihan sendiri');
      await fill(tester, 'exercise-name-0', 'Squat');
      await fill(tester, 'work-0', '0');
      await tapVisible(tester, find.byKey(const Key('save-routine')));
      expect(storage.document, isNull);
      await fill(tester, 'work-0', '45');
      await fill(tester, 'rest-0', '0');
      await tapVisible(tester, find.byKey(const Key('add-exercise')));
      await fill(tester, 'exercise-name-1', 'Plank');
      await fill(tester, 'work-1', '60');
      await tapVisible(tester, find.byTooltip('Naikkan gerakan 2'));
      await tapVisible(tester, find.byKey(const Key('save-routine')));
      expect(find.text('Latihan sendiri'), findsOneWidget);
      await tapVisible(tester, find.text('CIPTA LATIHAN'));
      await fill(tester, 'routine-name', 'Latihan petang');
      await fill(tester, 'exercise-name-0', 'Lunges');
      await tapVisible(tester, find.byKey(const Key('save-routine')));
      final loaded = WorkoutLibrary(storage);
      addTearDown(loaded.dispose);
      await loaded.load();
      expect(loaded.plans.length, 2);
      expect(loaded.plans.first.exercises.map((e) => e.name), [
        'Plank',
        'Squat',
      ]);
      expect(loaded.plans.first.exercises.last.restSeconds, 0);
      expect(loaded.plans.last.name, 'Latihan petang');
    },
  );

  testWidgets('edit and delete a saved routine, keeping library when empty', (
    tester,
  ) async {
    final storage = MemoryLibraryStorage();
    final library = WorkoutLibrary(storage);
    addTearDown(library.dispose);
    await library.load();
    await library.save(plan('one'));
    await tester.pumpWidget(
      WorkoutTimerApp(
        storage: storage,
        languageStorage: MemoryLanguageStorage(),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip('Urus Morning'));
    await tapVisible(tester, find.text('Edit latihan'));
    await fill(tester, 'routine-name', 'Evening');
    await tapVisible(tester, find.byTooltip('Buang gerakan 2'));
    await tapVisible(tester, find.byKey(const Key('save-routine')));
    await tapVisible(tester, find.byTooltip('Urus Evening'));
    await tapVisible(tester, find.text('Padam latihan'));
    await tapVisible(tester, find.text('BATAL'));
    expect(find.text('Evening'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Urus Evening'));
    await tapVisible(tester, find.text('Padam latihan'));
    await tapVisible(tester, find.text('PADAM'));
    expect(find.text('Belum ada latihan'), findsOneWidget);
    expect(find.text('Latihan Saya'), findsOneWidget);
  });

  testWidgets(
    'cancelled setup remains first-run; unsaved edits ask before discard',
    (tester) async {
      final storage = MemoryLibraryStorage();
      await tester.pumpWidget(
        WorkoutTimerApp(
          storage: storage,
          languageStorage: MemoryLanguageStorage(),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Cipta latihan sendiri'));
      await fill(tester, 'routine-name', 'Unsaved');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Buang perubahan?'), findsOneWidget);
      await tapVisible(tester, find.text('TERUS EDIT'));
      expect(find.text('Unsaved'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('BUANG'));
      expect(find.text('Cipta latihan sendiri'), findsOneWidget);
      expect(storage.document, isNull);
    },
  );

  testWidgets('save failure retains editor inputs and retry succeeds', (
    tester,
  ) async {
    final storage = MemoryLibraryStorage()..failWrite = true;
    await tester.pumpWidget(
      WorkoutTimerApp(
        storage: storage,
        languageStorage: MemoryLanguageStorage(),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Cipta latihan sendiri'));
    await fill(tester, 'routine-name', 'Keep me');
    await fill(tester, 'exercise-name-0', 'Squat');
    await tapVisible(tester, find.byKey(const Key('save-routine')));
    expect(find.byType(WorkoutEditorScreen), findsOneWidget);
    expect(find.textContaining('tidak dapat disimpan'), findsOneWidget);
    expect(storage.document, isNull);
    storage.failWrite = false;
    await tapVisible(tester, find.byKey(const Key('save-routine')));
    expect(find.text('Latihan Saya'), findsOneWidget);
    expect(find.text('Keep me'), findsOneWidget);
  });

  testWidgets(
    'corrupt storage shows retry without silently resetting user data',
    (tester) async {
      final storage = MemoryLibraryStorage()..document = 'invalid';
      await tester.pumpWidget(
        WorkoutTimerApp(
          storage: storage,
          languageStorage: MemoryLanguageStorage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Latihan tidak dapat dimuatkan.'), findsOneWidget);
      expect(storage.document, 'invalid');
      storage.document = null;
      await tapVisible(tester, find.text('CUBA LAGI'));
      expect(find.text('Guna template'), findsOneWidget);
    },
  );

  testWidgets('editor fits narrow screen with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final library = WorkoutLibrary(MemoryLibraryStorage());
    addTearDown(library.dispose);
    await library.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: WorkoutEditorScreen(library: library),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
