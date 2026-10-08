import '../data/workout_presets.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_plan.dart';

abstract class LibraryStorage {
  Future<String?> read();
  Future<void> write(String document);
}

class DeviceLibraryStorage implements LibraryStorage {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const key = 'pulse.workout_library.v1';

  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String document) => _preferences.setString(key, document);
}

class WorkoutLibrary extends ChangeNotifier {
  WorkoutLibrary(this.storage, {bool Function()? hasPro})
    : _hasPro = hasPro ?? (() => false);
  final bool Function() _hasPro;
  bool get canCreate => _hasPro() || _plans.length < 3;
  final LibraryStorage storage;
  List<WorkoutPlan> _plans = const [];
  bool _onboarded = false;
  bool _loaded = false;
  bool _saving = false;
  bool _disposed = false;

  List<WorkoutPlan> get plans => _plans;
  bool get onboarded => _onboarded;
  bool get loaded => _loaded;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final raw = await storage.read();
    if (raw != null) {
      final json = jsonDecode(raw);
      if (json is! Map ||
          json['version'] != 1 ||
          json['onboarded'] is! bool ||
          json['plans'] is! List) {
        throw const FormatException('Unsupported workout library');
      }
      final plans = (json['plans'] as List)
          .map(
            (p) => tagLegacyTemplate(
              WorkoutPlan.fromJson(Map<String, dynamic>.from(p as Map)),
            ),
          )
          .toList();
      if (plans.map((p) => p.id).toSet().length != plans.length ||
          (plans.isNotEmpty && json['onboarded'] != true)) {
        throw const FormatException('Invalid workout library');
      }
      _plans = List.unmodifiable(plans);
      _onboarded = json['onboarded'] as bool;
    }
    _loaded = true;
    _notify();
  }

  Future<void> save(WorkoutPlan plan) async {
    final updated = [..._plans];
    final index = updated.indexWhere((p) => p.id == plan.id);
    if (index < 0) {
      if (!canCreate) throw RoutineLimitReached();
      updated.add(plan);
    } else {
      updated[index] = plan;
    }
    await _persist(updated);
  }

  Future<void> delete(String id) =>
      _persist(_plans.where((p) => p.id != id).toList());

  Future<void> _persist(List<WorkoutPlan> plans) async {
    if (!_loaded || _saving) throw StateError('Library is not ready');
    _saving = true;
    try {
      // Onboarding and routines share one record; never mark setup complete
      // before its first routine is successfully stored.
      await storage.write(
        jsonEncode({
          'version': 1,
          'onboarded': true,
          'plans': plans.map((p) => p.toJson()).toList(),
        }),
      );
      _plans = List.unmodifiable(plans);
      _onboarded = true;
      _notify();
    } finally {
      _saving = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class RoutineLimitReached implements Exception {}
