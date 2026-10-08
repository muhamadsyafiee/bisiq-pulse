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
          _error = 'Rakaman tidak dapat dimuatkan. Cuba lagi.';
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
              ? 'Video belum disimpan ke galeri. Semak izin dan ruang telefon, kemudian cuba lagi. Salinan aplikasi masih ada.'
              : 'Video belum dapat diproses. Rakaman asal masih disimpan; cuba “Sediakan video” semula.',
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
        title: const Text('Padam salinan aplikasi?'),
        content: const Text(
          'Rakaman ini akan dipadam daripada aplikasi. Salinan yang telah disimpan ke galeri tidak dipadam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('PADAM'),
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
        setState(() => _error = 'Rakaman tidak dapat dipadam. Cuba lagi.');
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
        setState(
          () => _error =
              'Buka aplikasi Galeri pada telefon untuk melihat video anda.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_working,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Rakaman Saya'),
        actions: [
          IconButton(
            tooltip: 'Buka galeri',
            onPressed: _working ? null : _openGallery,
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Usaha anda,\ndirakam.',
                    style: TextStyle(
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.interrupted
                        ? 'Rakaman dihentikan apabila aplikasi terganggu. Video yang berjaya dirakam disimpan di sini.'
                        : 'Video disimpan dalam aplikasi. Sediakan video dengan pemasa, kemudian simpan ke galeri.',
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.orange,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (_items.isEmpty) ...[
                    const SizedBox(height: 30),
                    const Icon(
                      Icons.video_library_outlined,
                      size: 60,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada rakaman',
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null)
                      TextButton(
                        onPressed: _load,
                        child: const Text('CUBA LAGI'),
                      ),
                  ],
                  ..._items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.movie_outlined,
                                color: AppColors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.plan.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Padam rakaman',
                                onPressed: _working
                                    ? null
                                    : () => _delete(item),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.createdAt.toLocal().toString().substring(0, 16)} • ${item.exported ? 'Video dengan pemasa' : 'Rakaman asal disimpan'}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_workingId == item.id) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 14),
                            const Text(
                              'Menyediakan video… Kekalkan aplikasi terbuka.',
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
                                    ? 'DISIMPAN KE GALERI'
                                    : item.exported
                                    ? 'SIMPAN KE GALERI'
                                    : 'SEDIAKAN VIDEO',
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
