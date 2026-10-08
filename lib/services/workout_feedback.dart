import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'workout_controller.dart';

abstract class WorkoutFeedback {
  Future<void> play(WorkoutCue cue);
  Future<void> setAwake(bool enabled);
  Future<void> stop();
  Future<void> dispose();
}

class DeviceWorkoutFeedback implements WorkoutFeedback {
  final AudioPlayer _player = AudioPlayer();
  Future<void> _audioQueue = Future.value();
  Future<void> _wakeQueue = Future.value();
  bool _disposed = false;

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      // An unavailable audio output must not interrupt the workout clock.
      debugPrint('Workout feedback unavailable: $error');
    }
  }

  @override
  Future<void> play(WorkoutCue cue) {
    _audioQueue = _audioQueue.then(
      (_) => _guard(() async {
        if (_disposed) return;
        await _player.stop();
        await _player.play(AssetSource('audio/${cue.name}.wav'));
      }),
    );
    return _audioQueue;
  }

  @override
  Future<void> stop() {
    _audioQueue = _audioQueue.then((_) => _guard(_player.stop));
    return _audioQueue;
  }

  @override
  Future<void> setAwake(bool enabled) {
    // Serialize platform writes so a late enable cannot override a pause.
    _wakeQueue = _wakeQueue.then(
      (_) => _guard(() => WakelockPlus.toggle(enable: enabled)),
    );
    return _wakeQueue;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _audioQueue;
    await _guard(_player.dispose);
    await setAwake(false);
  }
}
