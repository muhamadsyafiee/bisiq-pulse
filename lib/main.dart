import 'package:flutter/material.dart';

import 'screens/library_screen.dart';
import 'services/workout_library.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorkoutTimerApp());
}

class WorkoutTimerApp extends StatelessWidget {
  const WorkoutTimerApp({super.key, this.storage});
  final LibraryStorage? storage;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PULSE • Workout Timer',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: LibraryScreen(storage: storage),
  );
}
