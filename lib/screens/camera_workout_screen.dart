import 'dart:async';
import 'dart:math' as math;
import '../models/camera_display_settings.dart';
import '../services/camera_display_store.dart';
import '../widgets/camera_timer_panel.dart';
import '../widgets/draggable_camera_panel.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_plan.dart';
import '../services/camera_workout_session.dart';
import '../services/recording_archive.dart';
import '../services/video_capture.dart';
import '../services/workout_feedback.dart';
import '../theme/app_theme.dart';
import 'recordings_screen.dart';

class CameraWorkoutScreen extends StatefulWidget {
  const CameraWorkoutScreen({
    super.key,
    required this.plan,
    this.session,
    this.displayStore,
  });
  final WorkoutPlan plan;
  final CameraWorkoutSession? session;
  final CameraDisplayStore? displayStore;
  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen>
    with WidgetsBindingObserver {
  late final CameraWorkoutSession _session;
  late final CameraDisplayStore _displayStore;
  bool _displayLoaded = false;
  bool _leaving = false;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session =
        widget.session ??
        CameraWorkoutSession(
          plan: widget.plan,
          capture: DeviceVideoCapture(),
          archive: DeviceRecordingArchive(),
          feedback: DeviceWorkoutFeedback(),
        );
    _session.addListener(_changed);
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    _displayStore = widget.displayStore ?? CameraDisplayStore();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _session.initialize();
    CameraDisplaySettings settings = const CameraDisplaySettings();
    try {
      settings = await _displayStore.load();
    } catch (_) {
      if (mounted) {
        _notice(
          'Tetapan paparan tidak dapat dibaca. Menggunakan tetapan asal.',
        );
      }
    }
    if (!mounted) return;
    // Permission errors can be retried later; retain the loaded settings.
    _loadedDisplay = settings;
    if (_session.status == CaptureStatus.ready) _session.setDisplay(settings);
    setState(() => _displayLoaded = true);
  }

  CameraDisplaySettings? _loadedDisplay;
  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _saveDisplay() async {
    try {
      await _displayStore.save(_session.display);
    } catch (_) {
      if (mounted) {
        _notice(
          'Tetapan digunakan untuk sesi ini, tetapi belum disimpan. Cuba ubah tetapan semula.',
        );
      }
    }
  }

  void _setDisplay(CameraDisplaySettings value) {
    _loadedDisplay = null;
    _session.setDisplay(value);
  }

  void _changed() {
    if (!mounted) return;
    if (_displayLoaded &&
        _loadedDisplay != null &&
        _session.status == CaptureStatus.ready) {
      final settings = _loadedDisplay!;
      _loadedDisplay = null;
      _session.setDisplay(settings);
    }
    setState(() {});
    if (_session.recording != null && !_leaving) {
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (_) => RecordingsScreen(
              archive: _session.archive,
              autoExportId: _session.recording!.id,
              interrupted: _session.interrupted,
            ),
          ),
        );
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_session.resume());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        (state == AppLifecycleState.inactive && _session.isRecording)) {
      unawaited(_session.suspend());
    }
  }

  Future<void> _requestExit() async {
    if (_session.busy || _confirming) return;
    _confirming = true;
    if (_session.isRecording) {
      final stop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hentikan rakaman?'),
          content: const Text(
            'Video yang telah dirakam akan disimpan. Sesi latihan ini akan ditamatkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('TERUS RAKAM'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('HENTI & SIMPAN'),
            ),
          ],
        ),
      );
      if (stop == true) await _session.stop();
    } else if (_session.hasPendingVideo) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Video belum disimpan'),
          content: const Text(
            'Cuba simpan semula dahulu. Keluar sekarang boleh menyebabkan rakaman ini hilang.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('KEMBALI'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('KELUAR TANPA SIMPAN'),
            ),
          ],
        ),
      );
      if (leave == true && mounted) Navigator.pop(context);
    }
    _confirming = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_changed);
    _session.dispose();
    unawaited(SystemChrome.setPreferredOrientations([]));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editable =
        _displayLoaded &&
        _session.status == CaptureStatus.ready &&
        !_session.timer.hasStarted;
    return PopScope(
      canPop:
          !_session.busy && !_session.isRecording && !_session.hasPendingVideo,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Kembali',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            widget.plan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (_session.isRecording)
                          const Text(
                            '● REC',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Tukar kamera',
                          onPressed: editable && _session.capture.canSwitch
                              ? _session.switchCamera
                              : null,
                          icon: const Icon(Icons.flip_camera_android_outlined),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _session.capture.front
                                ? 'Kamera depan'
                                : 'Kamera belakang',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const Text('Mikrofon', style: TextStyle(fontSize: 12)),
                        Switch(
                          value: _session.microphone,
                          onChanged:
                              !_session.busy &&
                                  !_session.isRecording &&
                                  !_session.hasPendingVideo
                              ? _session.setMicrophone
                              : null,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Tema', style: TextStyle(fontSize: 12)),
                        ChoiceChip(
                          label: const Text('Standard'),
                          selected: !_session.display.transparent,
                          onSelected: editable
                              ? (_) {
                                  _setDisplay(
                                    _session.display.copyWith(
                                      transparent: false,
                                    ),
                                  );
                                  unawaited(_saveDisplay());
                                }
                              : null,
                        ),
                        ChoiceChip(
                          label: const Text('Transparent'),
                          selected: _session.display.transparent,
                          onSelected: editable
                              ? (_) {
                                  _setDisplay(
                                    _session.display.copyWith(
                                      transparent: true,
                                    ),
                                  );
                                  unawaited(_saveDisplay());
                                }
                              : null,
                        ),
                        IconButton(
                          tooltip: 'Reset paparan',
                          onPressed: editable
                              ? () {
                                  _setDisplay(const CameraDisplaySettings());
                                  unawaited(_saveDisplay());
                                }
                              : null,
                          icon: const Icon(Icons.restart_alt),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _session.isRecording
                            ? 'Kedudukan dan tema dikunci semasa rakaman.'
                            : 'Seret panel untuk ubah kedudukan sebelum mula.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: math.max(240, constraints.maxHeight - 310),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _session.capture.portraitAspectRatio,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _session.capture.preview(),
                                DraggableCameraPanel(
                                  settings: _session.display,
                                  onChanged: editable ? _setDisplay : null,
                                  onChangeEnd: () => unawaited(_saveDisplay()),
                                  child: CameraTimerPanel(
                                    plan: widget.plan,
                                    timer: _session.timer,
                                    settings: _session.display,
                                    recording: _session.isRecording,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_session.error != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              _session.error!,
                              style: const TextStyle(color: AppColors.orange),
                            ),
                            if (_session.hasPendingVideo)
                              FilledButton(
                                onPressed: _session.retrySave,
                                child: const Text('CUBA SIMPAN SEMULA'),
                              )
                            else
                              Wrap(
                                spacing: 12,
                                children: [
                                  TextButton(
                                    onPressed: _session.initialize,
                                    child: const Text('CUBA LAGI'),
                                  ),
                                  TextButton(
                                    onPressed: () => DeviceRecordingArchive
                                        .channel
                                        .invokeMethod<void>('settings'),
                                    child: const Text('TETAPAN'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_session.busy || !_displayLoaded) ...[
                      const LinearProgressIndicator(),
                      Text(
                        _session.status == CaptureStatus.saving
                            ? 'Menyimpan rakaman…'
                            : 'Menyediakan kamera…',
                      ),
                    ] else if (!_session.hasPendingVideo)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _session.isRecording
                              ? _session.stop
                              : _session.status == CaptureStatus.ready
                              ? _session.start
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _session.isRecording
                                ? AppColors.orange
                                : AppColors.green,
                          ),
                          icon: Icon(
                            _session.isRecording
                                ? Icons.stop_rounded
                                : Icons.fiber_manual_record,
                          ),
                          label: Text(
                            _session.isRecording
                                ? 'HENTI & SIMPAN'
                                : 'MULA & RAKAM',
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _session.isRecording
                          ? 'Rakaman tamat selepas gerakan terakhir.'
                          : 'Kedudukan dan tema ini turut digunakan dalam video.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
