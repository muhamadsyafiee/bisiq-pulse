import 'package:flutter/material.dart';

import 'screens/workout_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorkoutTimerApp());
}

class WorkoutTimerApp extends StatelessWidget {
  const WorkoutTimerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PULSE • Workout Timer',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: const WorkoutScreen(),
  );
}
