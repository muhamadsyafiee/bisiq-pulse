import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/workout_plan.dart';
import '../models/workout_recording.dart';
import 'recording_archive.dart';
import 'video_capture.dart';
import 'workout_controller.dart';
import 'workout_feedback.dart';

enum CaptureStatus {
  loading,
  ready,
  starting,
  recording,
  saving,
  finished,
  error,
}

/// Serializes camera operations, including lifecycle events arriving while the
/// camera is opening or starting. The timer never starts before the recorder.
class CameraWorkoutSession extends ChangeNotifier {
  CameraWorkoutSession({
    required this.plan,
    required this.capture,
    required this.archive,
    required this.feedback,
    Duration Function()? elapsed,
    bool automaticTicks = true,
  }) {
    timer = WorkoutController(
      exercises: plan.exercises,
      elapsed: elapsed,
      automaticTicks: automaticTicks,
      onCue: (cue) {
        if (_foreground) unawaited(feedback.play(cue));
      },
    );
    timer.addListener(_tick);
  }
  final WorkoutPlan plan;
  final VideoCapture capture;
  final RecordingArchive archive;
  final WorkoutFeedback feedback;
  late final WorkoutController timer;
  CaptureStatus status = CaptureStatus.loading;
  WorkoutRecording? recording;
  String? error;
  String? _pendingPath;
  bool microphone = false;
  bool interrupted = false;
  bool _foreground = true;
  bool _closed = false;
  Future<void> _queue = Future.value();
  Future<void>? _feedbackCleanup;

  Future<void> _disposeFeedback() => _feedbackCleanup ??= feedback.dispose();
  bool get isRecording => status == CaptureStatus.recording;
  bool get busy => [
    CaptureStatus.loading,
    CaptureStatus.starting,
    CaptureStatus.saving,
  ].contains(status);

  void _notify() {
    if (!_closed) notifyListeners();
  }

  Future<void> _serial(Future<void> Function() action) {
    final next = _queue.then((_) async {
      if (!_closed) await action();
    });
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> initialize() => _serial(() async {
    if (!_foreground ||
        recording != null ||
        _pendingPath != null ||
        isRecording ||
        _closed) {
      return;
    }
    status = CaptureStatus.loading;
    error = null;
    _notify();
    try {
      await capture.initialize(microphone: microphone);
      status = CaptureStatus.ready;
    } catch (_) {
      status = CaptureStatus.error;
      error =
          'Kamera tidak dapat dibuka. Benarkan akses kamera dalam Tetapan, kemudian cuba lagi. Jika mikrofon ditolak, matikannya untuk rakaman senyap.';
    }
    _notify();
  });
  Future<void> switchCamera() => _serial(() async {
    if (status != CaptureStatus.ready || !capture.canSwitch) return;
    status = CaptureStatus.loading;
    _notify();
    try {
      await capture.switchCamera(microphone: microphone);
      status = CaptureStatus.ready;
    } catch (_) {
      status = CaptureStatus.error;
      error = 'Kamera ini tidak dapat dibuka. Cuba lagi.';
    }
    _notify();
  });
  Future<void> setMicrophone(bool enabled) => _serial(() async {
    if (isRecording || busy || recording != null) return;
    microphone = enabled;
    error = null;
    status = CaptureStatus.loading;
    _notify();
    try {
      await capture.close();
      await capture.initialize(microphone: microphone);
      status = CaptureStatus.ready;
    } catch (_) {
      status = CaptureStatus.error;
      error =
          'Akses kamera atau mikrofon tidak tersedia. Matikan mikrofon atau semak izin dalam Tetapan.';
    }
    _notify();
  });
  Future<void> start() => _serial(() async {
    if (status != CaptureStatus.ready || !_foreground) return;
    status = CaptureStatus.starting;
    error = null;
    _notify();
    try {
      await capture.start();
      status = CaptureStatus.recording;
      timer.startOrResume();
      await feedback.setAwake(true);
    } catch (_) {
      status = CaptureStatus.ready;
      error = 'Rakaman gagal dimulakan. Cuba lagi.';
    }
    _notify();
  });
  void _tick() {
    _notify();
    if (timer.isFinished && isRecording) unawaited(stop());
  }

  Future<void> stop() => _serial(_stop);
  Future<void> _stop() async {
    if (!isRecording) return;
    status = CaptureStatus.saving;
    timer.pause();
    await feedback.setAwake(false);
    await feedback.stop();
    _notify();
    try {
      _pendingPath = await capture.stop();
      recording = await archive.keep(_pendingPath!, plan);
      _pendingPath = null;
      status = CaptureStatus.finished;
    } catch (_) {
      status = CaptureStatus.error;
      error = _pendingPath != null
          ? 'Video belum dapat disimpan. Cuba simpan semula sebelum keluar.'
          : 'Rakaman tidak dapat diselesaikan. Rakaman yang terlalu singkat mungkin tidak menghasilkan video.';
    }
    await capture.close();
    // Release this screen's platform resources before the export screen takes
    // ownership of the screen lock. Route disposal happens after its animation.
    if (recording != null) await _disposeFeedback();
    _notify();
  }

  Future<void> retrySave() => _serial(() async {
    if (_pendingPath == null) return;
    status = CaptureStatus.saving;
    _notify();
    try {
      recording = await archive.keep(_pendingPath!, plan);
      _pendingPath = null;
      error = null;
      status = CaptureStatus.finished;
      await _disposeFeedback();
    } catch (_) {
      status = CaptureStatus.error;
      error = 'Simpanan gagal. Semak ruang telefon dan cuba lagi.';
    }
    _notify();
  });
  bool get hasPendingVideo => _pendingPath != null;
  Future<void> suspend() {
    _foreground = false;
    return _serial(() async {
      if (isRecording) {
        interrupted = true;
        await _stop();
      }
      await capture.close();
    });
  }

  Future<void> resume() {
    _foreground = true;
    return initialize();
  }

  @override
  void dispose() {
    _closed = true;
    timer.removeListener(_tick);
    timer.dispose();
    // Widget navigation is blocked during capture/finalization. This is also a
    // best-effort cleanup if the owning route is removed unexpectedly.
    unawaited(
      _queue.whenComplete(() async {
        await capture.close();
        await _disposeFeedback();
      }),
    );
    super.dispose();
  }
}
