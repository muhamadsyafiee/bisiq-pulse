import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

abstract class LanguageStorage {
  Future<String?> read();
  Future<void> write(String code);
}

class DeviceLanguageStorage implements LanguageStorage {
  late final _prefs = SharedPreferencesAsync();
  static const key = 'pulse.language.v1';
  @override
  Future<String?> read() => _prefs.getString(key);
  @override
  Future<void> write(String code) => _prefs.setString(key, code);
}

class LanguageController extends ChangeNotifier {
  LanguageController(this.storage);
  final LanguageStorage storage;
  String code = 'ms';
  bool loaded = false, busy = false, loadFailed = false;
  Future<void> load() async {
    try {
      final saved = await storage.read();
      code = AppStrings.languages.containsKey(saved) ? saved! : 'ms';
      loadFailed = false;
      loaded = true;
      await _platformLocale();
    } catch (_) {
      loadFailed = true;
    }
    notifyListeners();
  }

  Future<bool> select(String value) async {
    if (busy || !AppStrings.languages.containsKey(value)) return false;
    busy = true;
    notifyListeners();
    try {
      await storage.write(value);
      code = value;
      await _platformLocale();
      return true;
    } catch (_) {
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _platformLocale() async {
    try {
      await const MethodChannel(
        'pulse/video',
      ).invokeMethod<void>('locale', {'code': code});
    } on PlatformException {
      /* App UI still uses its selected language. */
    } on MissingPluginException {
      /* Widget tests and non-Android hosts. */
    }
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);
  static LanguageController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.notifier;
}
