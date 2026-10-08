import 'package:gym_timer/models/camera_display_settings.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/exercise.dart';
import 'package:gym_timer/models/workout_plan.dart';
import 'package:gym_timer/services/recording_archive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late DeviceRecordingArchive archive;
  final plan = WorkoutPlan(
    id: 'test',
    name: 'Test recording',
    exercises: const [
      Exercise(name: 'Squat', workoutSeconds: 3, restSeconds: 0),
    ],
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('pulse-archive-test-');
    archive = DeviceRecordingArchive(
      directory: Directory('${root.path}/recordings'),
    );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceRecordingArchive.channel, null);
    await root.delete(recursive: true);
  });
  Future<String> source() async {
    final file = File('${root.path}/camera.mp4');
    await file.writeAsBytes([1, 2, 3, 4]);
    return file.path;
  }

  test(
    'raw video and routine metadata persist across archive instances',
    () async {
      final path = await source();
      final item = await archive.keep(
        path,
        plan,
        display: const CameraDisplaySettings(x: .1, y: .2, transparent: true),
      );
      expect(await File(path).exists(), false);
      final reopened = DeviceRecordingArchive(
        directory: Directory('${root.path}/recordings'),
      );
      final all = await reopened.list();
      expect(all.single.id, item.id);
      expect(all.single.plan.exercises.single.workoutSeconds, 3);
      expect(all.single.exported, false);
      expect(all.single.display!.toJson(), {
        'x': .1,
        'y': .2,
        'transparent': true,
      });
    },
  );
  test(
    'export failure preserves original; retry atomically publishes overlay',
    () async {
      final item = await archive.keep(
        await source(),
        plan,
        display: const CameraDisplaySettings(y: .15, transparent: true),
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        DeviceRecordingArchive.channel,
        (_) async => throw PlatformException(code: 'codec-error'),
      );
      await expectLater(
        archive.export(item),
        throwsA(isA<PlatformException>()),
      );
      expect((await archive.list()).single.exported, false);
      expect(
        await File('${root.path}/recordings/${item.id}-raw.mp4').exists(),
        true,
      );
      messenger.setMockMethodCallHandler(DeviceRecordingArchive.channel, (
        call,
      ) async {
        expect(call.method, 'export');
        final args = call.arguments as Map;
        expect((args['plan'] as Map)['name'], plan.name);
        expect(args['display'], item.display!.toJson());
        await File(args['source'] as String).copy(args['output'] as String);
        return null;
      });
      final exported = await archive.export(item);
      expect(exported.exported, true);
      expect(exported.display!.y, .15);
      expect((await archive.list()).single.display!.transparent, true);
      expect((await archive.list()).single.exported, true);
      expect(
        await File('${root.path}/recordings/${item.id}.mp4').exists(),
        true,
      );
      expect(
        await File('${root.path}/recordings/${item.id}-raw.mp4').exists(),
        false,
      );
      await archive.delete(exported);
      expect(await archive.list(), isEmpty);
    },
  );
  test(
    'malformed metadata does not hide valid recordings or delete files',
    () async {
      final item = await archive.keep(await source(), plan);
      final corrupt = File('${root.path}/recordings/broken.json');
      await corrupt.writeAsString('broken');
      expect((await archive.list()).single.id, item.id);
      expect(await corrupt.exists(), true);
    },
  );
}
