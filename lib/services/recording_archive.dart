import '../models/camera_display_settings.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/workout_plan.dart';
import '../models/workout_recording.dart';

abstract class RecordingArchive {
  Future<WorkoutRecording> keep(
    String source,
    WorkoutPlan plan, {
    CameraDisplaySettings? display,
  });
  Future<List<WorkoutRecording>> list();
  Future<WorkoutRecording> export(WorkoutRecording recording);
  Future<WorkoutRecording> saveToGallery(WorkoutRecording recording);
  Future<void> delete(WorkoutRecording recording);
}

class DeviceRecordingArchive implements RecordingArchive {
  DeviceRecordingArchive({this.directory});
  final Directory? directory;
  static const channel = MethodChannel('pulse/video');
  Future<Directory> _directory() async =>
      (directory ??
              Directory(
                '${(await getApplicationDocumentsDirectory()).path}/recordings',
              ))
          .create(recursive: true);
  Future<File> _file(String id, String suffix) async =>
      File('${(await _directory()).path}/$id$suffix');
  Future<void> _write(WorkoutRecording item) async {
    final file = await _file(item.id, '.json');
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(item.toJson()), flush: true);
    await temporary.rename(file.path);
  }

  @override
  Future<WorkoutRecording> keep(
    String source,
    WorkoutPlan plan, {
    CameraDisplaySettings? display,
  }) async {
    final item = WorkoutRecording(
      id: const Uuid().v4(),
      plan: plan,
      display: display,
      createdAt: DateTime.now(),
    );
    final raw = await _file(item.id, '-raw.mp4');
    try {
      await File(source).copy(raw.path);
      await _write(item);
    } catch (_) {
      // Keep the camera source for retry without accumulating orphan copies.
      try {
        if (await raw.exists()) await raw.delete();
      } on FileSystemException {
        /* preserve the original failure */
      }
      rethrow;
    }
    // Only remove the camera's temporary file once a durable copy is indexed.
    try {
      await File(source).delete();
    } on FileSystemException {
      /* harmless cache duplicate */
    }
    return item;
  }

  @override
  Future<List<WorkoutRecording>> list() async {
    final result = <WorkoutRecording>[];
    await for (final file in (await _directory()).list()) {
      if (file is! File || !file.path.endsWith('.json')) continue;
      try {
        final item = WorkoutRecording.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        if (file.path == (await _file(item.id, '.json')).path) result.add(item);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      } on ArgumentError {
        continue;
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<WorkoutRecording> export(WorkoutRecording item) async {
    final output = await _file(item.id, '.mp4');
    if (item.exported && await output.exists()) return item;
    final raw = await _file(item.id, '-raw.mp4');
    final temporary = await _file(item.id, '-exporting.mp4');
    if (await temporary.exists()) await temporary.delete();
    await channel.invokeMethod<void>('export', {
      'source': raw.path,
      'output': temporary.path,
      'plan': item.plan.toJson(),
      if (item.display != null) 'display': item.display!.toJson(),
    });
    await temporary.rename(output.path);
    final updated = item.copyWith(exported: true);
    await _write(updated);
    // The finished, indexed overlay video now owns the recording.
    try {
      await raw.delete();
    } on FileSystemException {
      /* cleanup can be retried on deletion */
    }
    return updated;
  }

  @override
  Future<WorkoutRecording> saveToGallery(WorkoutRecording item) async {
    if (item.gallerySaved) return item;
    if (!item.exported) throw StateError('Export the overlay first');
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      throw StateError('Gallery permission denied');
    }
    await Gal.putVideo((await _file(item.id, '.mp4')).path);
    final updated = item.copyWith(gallerySaved: true);
    await _write(updated);
    return updated;
  }

  @override
  Future<void> delete(WorkoutRecording item) async {
    // The gallery copy, if any, belongs to the user and is left intact.
    for (final suffix in [
      '-raw.mp4',
      '.mp4',
      '-exporting.mp4',
      '.json.tmp',
      '.json',
    ]) {
      final file = await _file(item.id, suffix);
      if (await file.exists()) await file.delete();
    }
  }
}
