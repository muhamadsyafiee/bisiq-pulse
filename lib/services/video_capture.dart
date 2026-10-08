import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class VideoCapture {
  bool get ready;
  double get portraitAspectRatio;
  bool get front;
  bool get canSwitch;
  Future<void> initialize({required bool microphone});
  Future<void> switchCamera({required bool microphone});
  Future<void> start();
  Future<String> stop();
  Future<void> close();
  Widget preview();
}

class DeviceVideoCapture implements VideoCapture {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  CameraDescription? _selected;
  @override
  double get portraitAspectRatio =>
      ready ? 1 / _controller!.value.aspectRatio : 9 / 16;
  @override
  bool get ready => _controller?.value.isInitialized ?? false;
  @override
  bool get front => _selected?.lensDirection == CameraLensDirection.front;
  @override
  bool get canSwitch =>
      _cameras.any((c) => c.lensDirection != _selected?.lensDirection);

  @override
  Future<void> initialize({required bool microphone}) async {
    if (ready) return;
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('NoCamera', 'Tiada kamera tersedia.');
    }
    _selected ??= _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    final controller = CameraController(
      _selected!,
      ResolutionPreset.high,
      enableAudio: microphone,
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (_) {
      await close();
      rethrow;
    }
  }

  @override
  Future<void> switchCamera({required bool microphone}) async {
    if (!canSwitch) return;
    final next = _cameras.firstWhere(
      (c) => c.lensDirection != _selected!.lensDirection,
    );
    await close();
    _selected = next;
    await initialize(microphone: microphone);
  }

  @override
  Future<void> start() =>
      _controller!.startVideoRecording(enablePersistentRecording: false);
  @override
  Future<String> stop() async => (await _controller!.stopVideoRecording()).path;
  @override
  Future<void> close() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  Widget preview() => ready ? CameraPreview(_controller!) : const SizedBox();
}
