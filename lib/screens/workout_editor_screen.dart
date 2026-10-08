import 'pro_screen.dart';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../services/workout_library.dart';
import '../theme/app_theme.dart';

class WorkoutEditorScreen extends StatefulWidget {
  const WorkoutEditorScreen({
    super.key,
    required this.library,
    this.plan,
    this.initialName = '',
    this.initialNameKey,
    this.initialExercises = const [],
  });
  final WorkoutLibrary library;
  final WorkoutPlan? plan;
  final String initialName;
  final String? initialNameKey;
  final List<Exercise> initialExercises;

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final String _id;
  final _drafts = <_ExerciseDraft>[];
  final _allDrafts = <_ExerciseDraft>[];
  bool _saving = false;
  bool _saveFailed = false;
  bool _dirty = false;
  bool _askingToLeave = false;

  @override
  void initState() {
    super.initState();
    _id = widget.plan?.id ?? Uuid().v4();
    _name = TextEditingController(text: widget.plan?.name ?? widget.initialName)
      ..addListener(_changed);
    final exercises = widget.plan?.exercises ?? widget.initialExercises;
    if (exercises.isEmpty) {
      _addDraft();
    } else {
      for (final e in exercises) {
        _addDraft(e);
      }
    }
  }

  void _changed() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _addDraft([Exercise? exercise]) {
    final draft = _ExerciseDraft(exercise);
    for (final field in draft.controllers) {
      field.addListener(_changed);
    }
    _drafts.add(draft);
    _allDrafts.add(draft);
  }

  Future<void> _discard() async {
    if (_askingToLeave) return;
    _askingToLeave = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).text('discardTitle')),
        content: Text(AppStrings.of(context).text('discardBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.of(context).text('keepEditing')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.of(context).text('discard')),
          ),
        ],
      ),
    );
    _askingToLeave = false;
    if (leave == true && mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving) return;
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        duration: Duration(milliseconds: 250),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final plan = WorkoutPlan(
      id: _id,
      name: _name.text.trim(),
      nameKey: _name.text.trim() == (widget.plan?.name ?? widget.initialName)
          ? (widget.plan?.nameKey ?? widget.initialNameKey)
          : null,
      exercises: _drafts
          .map(
            (d) => Exercise(
              name: d.name.text.trim(),
              workoutSeconds: int.parse(d.work.text),
              restSeconds: int.parse(d.rest.text),
              description: d.description.text.trim(),
              assetPath: d.assetPath,
              nameKey: d.name.text.trim() == d.original?.name
                  ? d.original?.nameKey
                  : null,
              descriptionKey:
                  d.description.text.trim() == d.original?.description
                  ? d.original?.descriptionKey
                  : null,
            ),
          )
          .toList(),
    );
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.library.save(plan);
      if (mounted) Navigator.pop(context, true);
    } on RoutineLimitReached {
      if (mounted) {
        setState(() => _saving = false);
        await showPro(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
    }
  }

  void _move(int index, int delta) {
    FocusScope.of(context).unfocus();
    setState(() {
      final draft = _drafts.removeAt(index);
      _drafts.insert(index + delta, draft);
      _dirty = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    for (final draft in _allDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && !_dirty,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_saving) _discard();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plan == null
              ? AppStrings.of(context).text('createWorkout')
              : AppStrings.of(context).text('editWorkout'),
        ),
        leading: BackButton(
          onPressed: _saving ? null : () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _saving,
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.of(context).text('editorTitle'),
                        style: TextStyle(
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        AppStrings.of(context).text('editorHint'),
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                      SizedBox(height: 24),
                      TextFormField(
                        key: Key('routine-name'),
                        controller: _name,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: AppStrings.of(context).text('routineName'),
                          hintText: AppStrings.of(context).text('routineHint'),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? AppStrings.of(context).text('routineRequired')
                            : null,
                      ),
                      SizedBox(height: 12),
                      ..._drafts.asMap().entries.map(
                        (entry) => _exerciseCard(entry.key, entry.value),
                      ),
                      OutlinedButton.icon(
                        key: Key('add-exercise'),
                        onPressed: () => setState(() {
                          _addDraft();
                          _dirty = true;
                        }),
                        icon: Icon(Icons.add_rounded),
                        label: Text(AppStrings.of(context).text('addExercise')),
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppStrings.of(context).text('restHint'),
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24),
                      if (_saveFailed)
                        Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            AppStrings.of(context).text('workoutSaveError'),
                            style: TextStyle(
                              color: AppColors.orange,
                              height: 1.5,
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        key: Key('save-routine'),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.check_rounded),
                        label: Text(
                          _saving
                              ? AppStrings.of(context).text('saving')
                              : AppStrings.of(context).text('saveWorkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _exerciseCard(int index, _ExerciseDraft draft) => Container(
    key: draft.key,
    margin: EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.of(context).text('exerciseNumber', {
                  'number': (index + 1).toString().padLeft(2, '0'),
                }),
                style: TextStyle(
                  color: AppColors.green,
                  letterSpacing: 1,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: AppStrings.of(
                context,
              ).text('moveUpExercise', {'number': index + 1}),
              onPressed: index > 0 ? () => _move(index, -1) : null,
              icon: Icon(Icons.arrow_upward_rounded, size: 19),
            ),
            IconButton(
              tooltip: AppStrings.of(
                context,
              ).text('moveDownExercise', {'number': index + 1}),
              onPressed: index < _drafts.length - 1
                  ? () => _move(index, 1)
                  : null,
              icon: Icon(Icons.arrow_downward_rounded, size: 19),
            ),
            IconButton(
              tooltip: AppStrings.of(
                context,
              ).text('removeExercise', {'number': index + 1}),
              onPressed: _drafts.length > 1
                  ? () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _drafts.removeAt(index);
                        _dirty = true;
                      });
                    }
                  : null,
              icon: Icon(Icons.delete_outline_rounded, size: 19),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          key: Key('exercise-name-$index'),
          controller: draft.name,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: AppStrings.of(context).text('exerciseName'),
            hintText: AppStrings.of(context).text('exerciseHint'),
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? AppStrings.of(context).text('exerciseRequired')
              : null,
        ),
        SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _durationField(
                draft.work,
                AppStrings.of(context).text('workSeconds'),
                'work-$index',
                1,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _durationField(
                draft.rest,
                AppStrings.of(context).text('restSeconds'),
                'rest-$index',
                0,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextFormField(
          key: Key('exercise-notes-$index'),
          controller: draft.description,
          maxLength: 240,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: AppStrings.of(context).text('exerciseNotes'),
            hintText: AppStrings.of(context).text('notesHint'),
          ),
        ),
      ],
    ),
  );

  Widget _durationField(
    TextEditingController controller,
    String label,
    String fieldKey,
    int minimum,
  ) => TextFormField(
    key: Key(fieldKey),
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ],
    decoration: InputDecoration(
      labelText: label,
      helperText: AppStrings.of(
        context,
      ).text('secondsRange', {'minimum': minimum}),
    ),
    validator: (value) {
      final seconds = int.tryParse(value ?? '');
      return seconds == null || seconds < minimum || seconds > 3600
          ? AppStrings.of(context).text('secondsRange', {'minimum': minimum})
          : null;
    },
  );
}

class _ExerciseDraft {
  _ExerciseDraft(Exercise? exercise)
    : original = exercise,
      name = TextEditingController(text: exercise?.name ?? ''),
      work = TextEditingController(text: '${exercise?.workoutSeconds ?? 20}'),
      rest = TextEditingController(text: '${exercise?.restSeconds ?? 10}'),
      description = TextEditingController(text: exercise?.description ?? ''),
      assetPath = exercise?.assetPath;
  final Exercise? original;
  final Key key = UniqueKey();
  final TextEditingController name, work, rest, description;
  final String? assetPath;
  List<TextEditingController> get controllers => [
    name,
    work,
    rest,
    description,
  ];
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}
