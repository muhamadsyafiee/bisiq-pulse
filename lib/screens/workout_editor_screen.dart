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
    this.initialExercises = const [],
  });
  final WorkoutLibrary library;
  final WorkoutPlan? plan;
  final String initialName;
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
    _id = widget.plan?.id ?? const Uuid().v4();
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
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan latihan ini belum disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('TERUS EDIT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BUANG'),
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
        duration: const Duration(milliseconds: 250),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final plan = WorkoutPlan(
      id: _id,
      name: _name.text.trim(),
      exercises: _drafts
          .map(
            (d) => Exercise(
              name: d.name.text.trim(),
              workoutSeconds: int.parse(d.work.text),
              restSeconds: int.parse(d.rest.text),
              description: d.description.text.trim(),
              assetPath: d.assetPath,
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
        title: Text(widget.plan == null ? 'Cipta latihan' : 'Edit latihan'),
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
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Rutin anda.\nRentak anda.',
                        style: TextStyle(
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Susun gerakan dan tentukan masa untuk setiap satu. Semua tempoh dalam saat.',
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('routine-name'),
                        controller: _name,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nama latihan',
                          hintText: 'Contoh: Latihan pagi',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Masukkan nama latihan'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      ..._drafts.asMap().entries.map(
                        (entry) => _exerciseCard(entry.key, entry.value),
                      ),
                      OutlinedButton.icon(
                        key: const Key('add-exercise'),
                        onPressed: () => setState(() {
                          _addDraft();
                          _dirty = true;
                        }),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('TAMBAH GERAKAN'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rehat berlaku antara gerakan sahaja. Gerakan terakhir terus menamatkan sesi.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_saveFailed)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Latihan tidak dapat disimpan. Cuba lagi; perubahan anda masih ada.',
                            style: TextStyle(
                              color: AppColors.orange,
                              height: 1.5,
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        key: const Key('save-routine'),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(_saving ? 'MENYIMPAN…' : 'SIMPAN LATIHAN'),
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
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
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
                'GERAKAN ${(index + 1).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppColors.green,
                  letterSpacing: 1,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Naikkan gerakan ${index + 1}',
              onPressed: index > 0 ? () => _move(index, -1) : null,
              icon: const Icon(Icons.arrow_upward_rounded, size: 19),
            ),
            IconButton(
              tooltip: 'Turunkan gerakan ${index + 1}',
              onPressed: index < _drafts.length - 1
                  ? () => _move(index, 1)
                  : null,
              icon: const Icon(Icons.arrow_downward_rounded, size: 19),
            ),
            IconButton(
              tooltip: 'Buang gerakan ${index + 1}',
              onPressed: _drafts.length > 1
                  ? () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _drafts.removeAt(index);
                        _dirty = true;
                      });
                    }
                  : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: Key('exercise-name-$index'),
          controller: draft.name,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nama gerakan',
            hintText: 'Contoh: Squat',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Masukkan nama gerakan' : null,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _durationField(
                draft.work,
                'Senaman (s)',
                'work-$index',
                1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _durationField(draft.rest, 'Rehat (s)', 'rest-$index', 0),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: Key('exercise-notes-$index'),
          controller: draft.description,
          maxLength: 240,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Nota gerakan (pilihan)',
            hintText: 'Contoh: Turun perlahan, badan tegak',
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
      helperText: '$minimum–3600 saat',
    ),
    validator: (value) {
      final seconds = int.tryParse(value ?? '');
      return seconds == null || seconds < minimum || seconds > 3600
          ? '$minimum–3600 saat'
          : null;
    },
  );
}

class _ExerciseDraft {
  _ExerciseDraft(Exercise? exercise)
    : name = TextEditingController(text: exercise?.name ?? ''),
      work = TextEditingController(text: '${exercise?.workoutSeconds ?? 20}'),
      rest = TextEditingController(text: '${exercise?.restSeconds ?? 10}'),
      description = TextEditingController(text: exercise?.description ?? ''),
      assetPath = exercise?.assetPath;
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
