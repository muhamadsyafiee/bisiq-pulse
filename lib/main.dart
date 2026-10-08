import 'dart:async';
import 'services/pro_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_strings.dart';
import 'screens/library_screen.dart';
import 'services/workout_library.dart';
import 'services/language_controller.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorkoutTimerApp());
}

class WorkoutTimerApp extends StatefulWidget {
  const WorkoutTimerApp({
    super.key,
    this.storage,
    this.languageStorage,
    this.proController,
  });
  final ProController? proController;
  final LibraryStorage? storage;
  final LanguageStorage? languageStorage;
  @override
  State<WorkoutTimerApp> createState() => _WorkoutTimerAppState();
}

class _WorkoutTimerAppState extends State<WorkoutTimerApp>
    with WidgetsBindingObserver {
  late final ProController _pro;
  late final LanguageController _language;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pro = widget.proController ?? ProController.device();
    unawaited(_pro.initialize());
    _language = LanguageController(
      widget.languageStorage ?? DeviceLanguageStorage(),
    );
    _language.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.proController == null) _pro.dispose();
    _language.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_pro.restore());
  }

  @override
  Widget build(BuildContext context) => ProScope(
    controller: _pro,
    child: LanguageScope(
      controller: _language,
      child: ListenableBuilder(
        listenable: _language,
        builder: (_, _) => MaterialApp(
          title: 'PULSE',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          locale: Locale(_language.code),
          supportedLocales: AppStrings.languages.keys.map(Locale.new).toList(),
          localizationsDelegates: const [
            AppStrings.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: _language.loaded
              ? LibraryScreen(storage: widget.storage)
              : Scaffold(
                  body: Center(
                    child: _language.loadFailed
                        ? Builder(
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppStrings.of(
                                    context,
                                  ).text('languageLoadError'),
                                ),
                                TextButton(
                                  onPressed: _language.load,
                                  child: Text(
                                    AppStrings.of(context).text('retry'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
        ),
      ),
    ),
  );
}
