import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/workout_recording.dart';
import '../services/recording_archive.dart';
import '../theme/app_theme.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({
    super.key,
    this.archive,
    this.autoExportId,
    this.interrupted = false,
  });
  final RecordingArchive? archive;
  final String? autoExportId;
  final bool interrupted;
  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  late final RecordingArchive _archive;
  List<WorkoutRecording> _items = [];
  bool _loading = true;
  bool _working = false;
  String? _error;
  String? _workingId;
  @override
  void initState() {
    super.initState();
    _archive = widget.archive ?? DeviceRecordingArchive();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _archive.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
      if (widget.autoExportId != null) {
        final matches = items.where(
          (i) => i.id == widget.autoExportId && !i.exported,
        );
        if (matches.isNotEmpty) await _process(matches.first, gallery: false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = AppStrings.of(context).text('recordingsLoadError');
        });
      }
    }
  }

  Future<void> _process(WorkoutRecording item, {required bool gallery}) async {
    if (_working) return;
    setState(() {
      _working = true;
      _workingId = item.id;
      _error = null;
    });
    try {
      await _awake(true);
      var result = item.exported ? item : await _archive.export(item);
      if (gallery) result = await _archive.saveToGallery(result);
      if (mounted) {
        setState(() {
          _items = _items.map((i) => i.id == result.id ? result : i).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = gallery
              ? AppStrings.of(context).text('gallerySaveError')
              : AppStrings.of(context).text('exportError'),
        );
      }
    } finally {
      await _awake(false);
      if (mounted) {
        setState(() {
          _working = false;
          _workingId = null;
        });
      }
    }
  }

  Future<void> _awake(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (error) {
      debugPrint('Export screen lock unavailable: $error');
    }
  }

  Future<void> _delete(WorkoutRecording item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).text('deleteRecordingTitle')),
        content: Text(AppStrings.of(context).text('deleteRecordingBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.of(context).text('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.of(context).text('delete')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _working = true);
    try {
      await _archive.delete(item);
      if (mounted) setState(() => _items.removeWhere((i) => i.id == item.id));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppStrings.of(context).text('recordingDeleteError'),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openGallery() async {
    try {
      await Gal.open();
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppStrings.of(context).text('openGalleryHint'));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_working,
    child: Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).text('myRecordings')),
        actions: [
          IconButton(
            tooltip: AppStrings.of(context).text('openGallery'),
            onPressed: _working ? null : _openGallery,
            icon: Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(24),
                children: [
                  Text(
                    AppStrings.of(context).text('recordingsTitle'),
                    style: TextStyle(
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.interrupted
                        ? AppStrings.of(context).text('recordingInterrupted')
                        : AppStrings.of(context).text('recordingsHint'),
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.orange, height: 1.5),
                      ),
                    ),
                  if (_items.isEmpty) ...[
                    SizedBox(height: 30),
                    Icon(
                      Icons.video_library_outlined,
                      size: 60,
                      color: AppColors.muted,
                    ),
                    SizedBox(height: 16),
                    Text(
                      AppStrings.of(context).text('noRecordings'),
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null)
                      TextButton(
                        onPressed: _load,
                        child: Text(AppStrings.of(context).text('retry')),
                      ),
                  ],
                  ..._items.map(
                    (item) => Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.movie_outlined,
                                color: AppColors.green,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.plan.displayName(AppStrings.of(context)),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: AppStrings.of(
                                  context,
                                ).text('deleteRecording'),
                                onPressed: _working
                                    ? null
                                    : () => _delete(item),
                                icon: Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${DateFormat.yMd(AppStrings.of(context).code).add_Hm().format(item.createdAt.toLocal())} • ${item.exported ? AppStrings.of(context).text('videoReady') : AppStrings.of(context).text('rawSaved')}',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 20),
                          if (_workingId == item.id) ...[
                            LinearProgressIndicator(),
                            SizedBox(height: 14),
                            Text(
                              AppStrings.of(context).text('preparingVideo'),
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ] else
                            FilledButton.icon(
                              onPressed: _working || item.gallerySaved
                                  ? null
                                  : () =>
                                        _process(item, gallery: item.exported),
                              icon: Icon(
                                item.gallerySaved
                                    ? Icons.check
                                    : item.exported
                                    ? Icons.save_alt
                                    : Icons.auto_awesome,
                              ),
                              label: Text(
                                item.gallerySaved
                                    ? AppStrings.of(
                                        context,
                                      ).text('savedGallery')
                                    : item.exported
                                    ? AppStrings.of(context).text('saveGallery')
                                    : AppStrings.of(
                                        context,
                                      ).text('prepareVideo'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
