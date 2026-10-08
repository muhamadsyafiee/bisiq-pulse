import 'package:gym_timer/services/language_controller.dart';

class MemoryLanguageStorage implements LanguageStorage {
  MemoryLanguageStorage([this.value]);
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String code) async {
    if (fail) throw StateError('disk');
    value = code;
  }
}
