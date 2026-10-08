import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/exercise.dart';
import 'package:gym_timer/models/workout_plan.dart';
import 'package:gym_timer/services/workout_library.dart';

class MemoryLibraryStorage implements LibraryStorage {
  String? document;
  bool failWrite = false;
  @override
  Future<String?> read() async => document;
  @override
  Future<void> write(String document) async {
    if (failWrite) throw StateError('storage unavailable');
    this.document = document;
  }
}

WorkoutPlan plan(String id, {String name = 'Morning'}) => WorkoutPlan(
  id: id,
  name: name,
  exercises: const [
    Exercise(
      name: 'Squat',
      workoutSeconds: 45,
      restSeconds: 15,
      description: 'Slowly',
    ),
    Exercise(name: 'Plank', workoutSeconds: 60, restSeconds: 90),
  ],
);

void main() {
  test('fresh install is empty and onboarding is not complete', () async {
    final library = WorkoutLibrary(MemoryLibraryStorage());
    addTearDown(library.dispose);
    await library.load();
    expect(library.loaded, true);
    expect(library.onboarded, false);
    expect(library.plans, isEmpty);
  });

  test(
    'multiple routines and onboarding survive a new library instance',
    () async {
      final storage = MemoryLibraryStorage();
      final first = WorkoutLibrary(storage);
      addTearDown(first.dispose);
      await first.load();
      await first.save(plan('one'));
      await first.save(plan('two', name: 'Evening'));
      final reopened = WorkoutLibrary(storage);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.onboarded, true);
      expect(reopened.plans.map((p) => p.name), ['Morning', 'Evening']);
      expect(reopened.plans.first.exercises.first.description, 'Slowly');
      expect(reopened.plans.first.totalSeconds, 120);
      expect(() => reopened.plans.clear(), throwsUnsupportedError);
    },
  );

  test(
    'editing replaces the same id; deleting all does not reset onboarding',
    () async {
      final storage = MemoryLibraryStorage();
      final library = WorkoutLibrary(storage);
      addTearDown(library.dispose);
      await library.load();
      await library.save(plan('one'));
      await library.save(plan('two'));
      await library.save(plan('one', name: 'Updated'));
      expect(library.plans.length, 2);
      expect(library.plans.first.name, 'Updated');
      await library.delete('one');
      expect(library.plans.single.id, 'two');
      await library.delete('two');
      final reopened = WorkoutLibrary(storage);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.plans, isEmpty);
      expect(reopened.onboarded, true);
    },
  );

  test(
    'failed save does not complete onboarding or lose existing routines',
    () async {
      final storage = MemoryLibraryStorage()..failWrite = true;
      final library = WorkoutLibrary(storage);
      addTearDown(library.dispose);
      await library.load();
      await expectLater(library.save(plan('one')), throwsStateError);
      expect(library.onboarded, false);
      expect(library.plans, isEmpty);
      storage.failWrite = false;
      await library.save(plan('one'));
      final previous = storage.document;
      storage.failWrite = true;
      await expectLater(
        library.save(plan('one', name: 'Not saved')),
        throwsStateError,
      );
      await expectLater(library.delete('one'), throwsStateError);
      expect(library.plans.single.name, 'Morning');
      expect(storage.document, previous);
    },
  );

  test(
    'malformed or unsupported data is preserved and cannot be overwritten',
    () async {
      for (final raw in [
        'broken json',
        '{"version":99,"onboarded":true,"plans":[]}',
        jsonEncode({
          'version': 1,
          'onboarded': true,
          'plans': [plan('one').toJson(), plan('one').toJson()],
        }),
      ]) {
        final storage = MemoryLibraryStorage()..document = raw;
        final library = WorkoutLibrary(storage);
        addTearDown(library.dispose);
        await expectLater(library.load(), throwsFormatException);
        await expectLater(library.save(plan('new')), throwsStateError);
        expect(storage.document, raw);
      }
    },
  );

  test(
    'free cap preserves all existing routines; Pro can create more',
    () async {
      final storage = MemoryLibraryStorage();
      var pro = false;
      final library = WorkoutLibrary(storage, hasPro: () => pro);
      addTearDown(library.dispose);
      await library.load();
      for (var i = 0; i < 3; i++) {
        await library.save(plan('$i'));
      }
      await expectLater(
        library.save(plan('four')),
        throwsA(isA<RoutineLimitReached>()),
      );
      expect(library.plans.length, 3);
      pro = true;
      await library.save(plan('four'));
      pro = false;
      await library.save(plan('four', name: 'Still editable'));
      final reopened = WorkoutLibrary(storage);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.plans.length, 4);
      expect(reopened.plans.last.name, 'Still editable');
      await expectLater(
        reopened.save(plan('five')),
        throwsA(isA<RoutineLimitReached>()),
      );
      await reopened.delete('four');
      await expectLater(
        reopened.save(plan('five')),
        throwsA(isA<RoutineLimitReached>()),
      );
      await reopened.delete('2');
      await reopened.save(plan('five'));
      expect(reopened.plans.length, 3);
    },
  );
  test('exercise decoding rejects invalid saved times and blank names', () {
    final json = const Exercise(
      name: 'Plank',
      workoutSeconds: 20,
      restSeconds: 0,
    ).toJson();
    expect(Exercise.fromJson(json).restSeconds, 0);
    expect(
      () => Exercise.fromJson({...json, 'workoutSeconds': 0}),
      throwsFormatException,
    );
    expect(
      () => Exercise.fromJson({...json, 'restSeconds': -1}),
      throwsFormatException,
    );
    expect(
      () => Exercise.fromJson({...json, 'name': '  '}),
      throwsFormatException,
    );
  });
}
