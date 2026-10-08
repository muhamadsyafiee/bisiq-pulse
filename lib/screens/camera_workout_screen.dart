import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_plan.dart';
import '../services/camera_workout_session.dart';
import '../services/recording_archive.dart';
import '../services/video_capture.dart';
import '../services/workout_controller.dart';
import '../services/workout_feedback.dart';
import '../theme/app_theme.dart';
import 'recordings_screen.dart';

class CameraWorkoutScreen extends StatefulWidget {
  const CameraWorkoutScreen({super.key, required this.plan, this.session});
  final WorkoutPlan plan;
  final CameraWorkoutSession? session;
  @override
  State<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends State<CameraWorkoutScreen>
    with WidgetsBindingObserver {
  late final CameraWorkoutSession _session;
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
    unawaited(_session.initialize());
  }

  void _changed() {
    if (!mounted) return;
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

  Widget _scrollControls(Widget child) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(child: child),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final timer = _session.timer;
    final rest = timer.phase == WorkoutPhase.rest;
    final color = rest ? AppColors.orange : AppColors.green;
    return PopScope(
      canPop:
          !_session.busy && !_session.isRecording && !_session.hasPendingVideo,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: _session.capture.preview()),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent, Colors.black87],
                  stops: [0, .4, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _scrollControls(
                  Column(
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (_session.isRecording)
                            const Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.redAccent,
                                  size: 10,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'REC',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          if (!_session.isRecording)
                            IconButton(
                              tooltip: 'Tukar kamera',
                              onPressed:
                                  _session.status == CaptureStatus.ready &&
                                      _session.capture.canSwitch
                                  ? _session.switchCamera
                                  : null,
                              icon: const Icon(
                                Icons.flip_camera_android_outlined,
                              ),
                            ),
                        ],
                      ),
                      if (!_session.isRecording &&
                          !_session.busy &&
                          !_session.hasPendingVideo)
                        Row(
                          children: [
                            Icon(
                              _session.capture.front
                                  ? Icons.person_outline
                                  : Icons.landscape_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _session.capture.front
                                    ? 'Kamera depan'
                                    : 'Kamera belakang',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Text(
                              'Mikrofon',
                              style: TextStyle(fontSize: 12),
                            ),
                            Switch(
                              value: _session.microphone,
                              onChanged: _session.setMicrophone,
                            ),
                          ],
                        ),
                      const Spacer(),
                      if (_session.error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _session.error!,
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                      if (_session.error == null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .68),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: color.withValues(alpha: .6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${_session.isRecording ? (rest ? 'REHAT' : 'SENAMAN') : 'BERSEDIA'}  •  GERAKAN ${timer.index + 1}/${widget.plan.exercises.length}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rest
                                          ? 'Tarik nafas seketika.'
                                          : timer.currentExercise.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      Text(
                                        '${timer.remainingSeconds}',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      const Text(
                                        'SAAT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: timer.progress,
                                color: color,
                                backgroundColor: Colors.white12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Seterusnya: ${timer.nextExercise?.name ?? 'Selesai'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_session.busy) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          _session.status == CaptureStatus.saving
                              ? 'Menyimpan rakaman…'
                              : 'Menyediakan kamera…',
                        ),
                      ] else if (!_session.hasPendingVideo)
                        FilledButton.icon(
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
                      const SizedBox(height: 12),
                      Text(
                        _session.isRecording
                            ? 'Rakaman tamat secara automatik selepas gerakan terakhir.'
                            : 'Pemasa dan gerakan turut dimasukkan dalam video.\n${_session.microphone ? 'Mikrofon dihidupkan.' : 'Rakaman senyap • Hidupkan mikrofon untuk audio.'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
