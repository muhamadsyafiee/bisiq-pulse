import 'pro_screen.dart';
import '../services/pro_controller.dart';
import '../l10n/app_strings.dart';
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
    CameraDisplaySettings settings = CameraDisplaySettings();
    try {
      settings = await _displayStore.load();
    } catch (_) {
      if (mounted) {
        _notice(AppStrings.of(context).text('displayLoadError'));
      }
    }
    if (!mounted) return;
    // Permission errors can be retried later; retain the loaded settings.
    _preferredDisplay = settings;
    _session.setProAccess(ProScope.active(context));
    _loadedDisplay = settings;
    if (_session.status == CaptureStatus.ready) _session.setDisplay(settings);
    setState(() => _displayLoaded = true);
  }

  CameraDisplaySettings _preferredDisplay = const CameraDisplaySettings();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pro = ProScope.active(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _session.timer.hasStarted) return;
      _session.setProAccess(pro);
      if (_displayLoaded) _session.setDisplay(_preferredDisplay);
    });
  }

  CameraDisplaySettings? _loadedDisplay;
  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _saveDisplay() async {
    if (!ProScope.active(context)) return;
    try {
      await _displayStore.save(_session.display);
    } catch (_) {
      if (mounted) {
        _notice(AppStrings.of(context).text('displaySaveError'));
      }
    }
  }

  void _setDisplay(CameraDisplaySettings value) {
    _loadedDisplay = null;
    _preferredDisplay = value;
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
          title: Text(AppStrings.of(context).text('stopRecordingTitle')),
          content: Text(AppStrings.of(context).text('stopRecordingBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.of(context).text('keepRecording')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.of(context).text('stopSave')),
            ),
          ],
        ),
      );
      if (stop == true) await _session.stop();
    } else if (_session.hasPendingVideo) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.of(context).text('unsavedVideo')),
          content: Text(AppStrings.of(context).text('unsavedVideoBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.of(context).text('returnButton')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.of(context).text('leaveUnsaved')),
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
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: AppStrings.of(context).text('back'),
                          onPressed: () => Navigator.maybePop(context),
                          icon: Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            widget.plan.displayName(AppStrings.of(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (_session.isRecording)
                          Text(
                            AppStrings.of(context).text('recordingIndicator'),
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        IconButton(
                          tooltip: AppStrings.of(context).text('switchCamera'),
                          onPressed: editable && _session.capture.canSwitch
                              ? _session.switchCamera
                              : null,
                          icon: Icon(Icons.flip_camera_android_outlined),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _session.capture.front
                                ? AppStrings.of(context).text('frontCamera')
                                : AppStrings.of(context).text('backCamera'),
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          AppStrings.of(context).text('microphone'),
                          style: TextStyle(fontSize: 12),
                        ),
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
                        Text(
                          AppStrings.of(context).text('theme'),
                          style: TextStyle(fontSize: 12),
                        ),
                        ChoiceChip(
                          label: Text(AppStrings.of(context).text('standard')),
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
                          label: Text(
                            AppStrings.of(context).text('transparent'),
                          ),
                          selected: _session.display.transparent,
                          onSelected: editable
                              ? (_) {
                                  if (!ProScope.active(context)) {
                                    showPro(context);
                                    return;
                                  }
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
                          tooltip: AppStrings.of(context).text('resetDisplay'),
                          onPressed: editable
                              ? () {
                                  _setDisplay(CameraDisplaySettings());
                                  unawaited(_saveDisplay());
                                }
                              : null,
                          icon: Icon(Icons.restart_alt),
                        ),
                      ],
                    ),
                    if (editable && !ProScope.active(context))
                      TextButton.icon(
                        onPressed: () => showPro(context),
                        icon: const Icon(Icons.lock_outline),
                        label: Text(
                          AppStrings.of(context).text('proCameraUnlock'),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        _session.isRecording
                            ? AppStrings.of(context).text('displayLocked')
                            : AppStrings.of(context).text(
                                ProScope.active(context)
                                    ? 'dragHint'
                                    : 'proCameraHint',
                              ),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.white70),
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
                                if (_session.watermarked)
                                  const Positioned(
                                    top: 14,
                                    right: 14,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(6),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        child: Text(
                                          'PULSE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                DraggableCameraPanel(
                                  settings: _session.display,
                                  onChanged:
                                      editable && ProScope.active(context)
                                      ? _setDisplay
                                      : null,
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
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              AppStrings.of(context).text(_session.error!),
                              style: TextStyle(color: AppColors.orange),
                            ),
                            if (_session.hasPendingVideo)
                              FilledButton(
                                onPressed: _session.retrySave,
                                child: Text(
                                  AppStrings.of(context).text('retrySave'),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 12,
                                children: [
                                  TextButton(
                                    onPressed: _session.initialize,
                                    child: Text(
                                      AppStrings.of(context).text('retry'),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => DeviceRecordingArchive
                                        .channel
                                        .invokeMethod<void>('settings'),
                                    child: Text(
                                      AppStrings.of(
                                        context,
                                      ).text('systemSettings'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    SizedBox(height: 12),
                    if (_session.busy || !_displayLoaded) ...[
                      LinearProgressIndicator(),
                      Text(
                        _session.status == CaptureStatus.saving
                            ? AppStrings.of(context).text('savingRecording')
                            : AppStrings.of(context).text('preparingCamera'),
                      ),
                    ] else if (!_session.hasPendingVideo)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _session.isRecording
                              ? _session.stop
                              : _session.status == CaptureStatus.ready
                              ? () {
                                  _session.setProAccess(
                                    ProScope.active(context),
                                  );
                                  _session.setLanguage(
                                    AppStrings.of(context).code,
                                  );
                                  unawaited(_session.start());
                                }
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
                                ? AppStrings.of(context).text('stopSave')
                                : AppStrings.of(context).text('startRecord'),
                          ),
                        ),
                      ),
                    SizedBox(height: 8),
                    Text(
                      _session.isRecording
                          ? AppStrings.of(context).text('recordEndHint')
                          : AppStrings.of(context).text('displayVideoHint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
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
