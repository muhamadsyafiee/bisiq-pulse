import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera_display_settings.dart';

class CameraDisplayStore {
  late final _preferences = SharedPreferencesAsync();
  static const key = 'pulse.camera_display.v1';
  Future<void> _writes = Future.value();
  Future<CameraDisplaySettings> load() async {
    final raw = await _preferences.getString(key);
    if (raw == null) return const CameraDisplaySettings();
    return CameraDisplaySettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> save(CameraDisplaySettings settings) {
    final next = _writes.then(
      (_) => _preferences.setString(key, jsonEncode(settings.toJson())),
    );
    _writes = next.catchError((Object _) {});
    return next;
  }
}
