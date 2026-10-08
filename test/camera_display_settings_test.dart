import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/camera_display_settings.dart';
import 'package:gym_timer/models/workout_recording.dart';

void main() {
  test('saved positions remain finite and inside the video', () {
    final invalid = CameraDisplaySettings.fromJson({
      'x': -3,
      'y': 5,
      'transparent': true,
    });
    expect(invalid.x, 0);
    expect(invalid.y, 1);
    expect(invalid.copyWith(x: 2, y: -1).toJson(), {
      'x': 1.0,
      'y': 0.0,
      'transparent': true,
    });
    final fallback = CameraDisplaySettings.fromJson({
      'x': double.nan,
      'y': double.infinity,
    });
    expect(fallback.x, .5);
    expect(fallback.y, .92);
  });
  test(
    'v1.2 recording metadata retains legacy overlay when no display exists',
    () {
      final item = WorkoutRecording.fromJson({
        'id': 'legacy',
        'createdAt': '2026-10-08T12:00:00.000',
        'plan': {
          'id': 'p',
          'name': 'Old routine',
          'exercises': [
            {'name': 'Squat', 'workoutSeconds': 20, 'restSeconds': 10},
          ],
        },
        'exported': false,
        'gallerySaved': false,
      });
      expect(item.display, isNull);
      expect(item.toJson().containsKey('display'), false);
    },
  );
}
