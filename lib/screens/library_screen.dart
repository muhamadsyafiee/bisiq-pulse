import 'pro_screen.dart';
import '../services/pro_controller.dart';
import 'settings_screen.dart';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../data/workout_presets.dart';
import '../models/workout_plan.dart';
import '../services/workout_library.dart';
import '../theme/app_theme.dart';
import 'template_picker_screen.dart';
import 'workout_editor_screen.dart';
import 'workout_screen.dart';
import 'camera_workout_screen.dart';
import 'recordings_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.storage});
  final LibraryStorage? storage;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final WorkoutLibrary _library;
  bool _loading = true;
  bool _loadFailed = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _library = WorkoutLibrary(
      widget.storage ?? DeviceLibraryStorage(),
      hasPro: () => ProScope.active(context),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      await _library.load();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit({WorkoutPlan? plan, bool fromTemplate = false}) async {
    if (_opening) return;
    _opening = true;
    try {
      if (plan == null && !_library.canCreate) {
        await showPro(context);
        if (!mounted || !_library.canCreate) return;
      }
      WorkoutTemplate? template;
      if (fromTemplate) {
        template = await Navigator.push<WorkoutTemplate>(
          context,
          MaterialPageRoute(builder: (_) => TemplatePickerScreen()),
        );
        if (template == null || !mounted) return;
      }
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutEditorScreen(
            library: _library,
            plan: plan?.localized(AppStrings.of(context)),
            initialName: template?.localized(AppStrings.of(context)).name ?? '',
            initialNameKey: template?.nameKey,
            initialExercises:
                template?.localized(AppStrings.of(context)).exercises ??
                const [],
          ),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  Future<void> _delete(WorkoutPlan plan) async {
    if (_opening) return;
    _opening = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.of(context).text('workoutDeleteTitle')),
          content: Text(
            AppStrings.of(context).text('workoutDeleteBody', {
              'name': plan.displayName(AppStrings.of(context)),
            }),
          ),
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
      if (confirmed != true || !mounted) return;
      await _library.delete(plan.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).text('workoutDeleteError')),
          ),
        );
      }
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _library.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          tooltip: AppStrings.of(context).text('settings'),
          icon: Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),

        IconButton(
          tooltip: AppStrings.of(context).text('myRecordings'),
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => RecordingsScreen()),
          ),
          icon: Icon(Icons.video_library_outlined),
        ),
        SizedBox(width: 12),
      ],
      titleSpacing: 24,
      title: Row(
        children: [
          Icon(Icons.bolt_rounded, color: AppColors.green, size: 29),
          SizedBox(width: 4),
          Text(
            'PULSE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontSize: 20,
            ),
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: _loading
          ? Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.orange,
                      size: 40,
                    ),
                    SizedBox(height: 16),
                    Text(
                      AppStrings.of(context).text('workoutLoadError'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppStrings.of(context).text('dataUnchanged'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    SizedBox(height: 24),
                    FilledButton(
                      onPressed: _load,
                      child: Text(AppStrings.of(context).text('retry')),
                    ),
                  ],
                ),
              ),
            )
          : ListenableBuilder(
              listenable: _library,
              builder: (_, _) =>
                  _library.onboarded ? _libraryView() : _welcome(),
            ),
    ),
  );

  Widget _welcome() => SingleChildScrollView(
    padding: EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              key: const Key('onboarding-language'),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: Icon(Icons.language),
              label: Text(
                '${AppStrings.of(context).text("language")}: ${AppStrings.languages[AppStrings.of(context).code]}',
              ),
            ),
            SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: AppColors.green,
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              AppStrings.of(context).text('welcomeTitle'),
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 16),
            Text(
              AppStrings.of(context).text('welcomeBody'),
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            SizedBox(height: 30),
            _choice(
              icon: Icons.layers_outlined,
              title: AppStrings.of(context).text('useTemplate'),
              subtitle: AppStrings.of(context).text('templateSubtitle'),
              onTap: () => _edit(fromTemplate: true),
            ),
            SizedBox(height: 16),
            _choice(
              icon: Icons.edit_note_rounded,
              title: AppStrings.of(context).text('createOwn'),
              subtitle: AppStrings.of(context).text('createOwnSubtitle'),
              onTap: () => _edit(),
            ),
            SizedBox(height: 26),
            Text(
              AppStrings.of(context).text('manyRoutines'),
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _choice({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.green, size: 27),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );

  Widget _libraryView() => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 640),
      child: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text(
            AppStrings.of(context).text('myWorkouts'),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppStrings.of(
              context,
            ).text('routinesSaved', {'count': _library.plans.length}),
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: Icon(Icons.add_rounded),
            label: Text(AppStrings.of(context).text('createWorkoutButton')),
          ),
          SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _edit(fromTemplate: true),
            icon: Icon(Icons.layers_outlined),
            label: Text(AppStrings.of(context).text('addTemplate')),
          ),
          SizedBox(height: 28),
          if (_library.plans.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 48,
                    color: AppColors.muted,
                  ),
                  SizedBox(height: 20),
                  Text(
                    AppStrings.of(context).text('noWorkouts'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppStrings.of(context).text('noWorkoutsHint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ..._library.plans.map(_planCard),
        ],
      ),
    ),
  );

  Widget _planCard(WorkoutPlan plan) => Container(
    key: Key('plan-${plan.id}'),
    padding: EdgeInsets.all(20),
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.displayName(AppStrings.of(context)),
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: AppStrings.of(context).text('manageWorkout', {
                'name': plan.displayName(AppStrings.of(context)),
              }),
              onSelected: (action) {
                if (action == 'edit') {
                  _edit(plan: plan);
                } else {
                  _delete(plan);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(AppStrings.of(context).text('editWorkout')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(AppStrings.of(context).text('deleteWorkout')),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          AppStrings.of(context).text('routineSummary', {
            'count': plan.exercises.length,
            'minutes': plan.totalSeconds ~/ 60,
            'seconds': plan.totalSeconds % 60,
          }),
          style: TextStyle(color: AppColors.green, fontSize: 13),
        ),
        SizedBox(height: 12),
        Text(
          plan.exercises
              .map((e) => e.displayName(AppStrings.of(context)))
              .join('  ·  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13),
        ),
        SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutScreen(
                exercises: plan.exercises,
                workoutName: plan.displayName(AppStrings.of(context)),
              ),
            ),
          ),
          icon: Icon(Icons.play_arrow_rounded),
          label: Text(AppStrings.of(context).text('openTimer')),
        ),
        SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => CameraWorkoutScreen(plan: plan)),
          ),
          icon: Icon(Icons.videocam_outlined),
          label: Text(AppStrings.of(context).text('recordWorkout')),
        ),
      ],
    ),
  );
}
