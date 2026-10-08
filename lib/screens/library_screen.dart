import 'package:flutter/material.dart';

import '../data/workout_presets.dart';
import '../models/workout_plan.dart';
import '../services/workout_library.dart';
import '../theme/app_theme.dart';
import 'template_picker_screen.dart';
import 'workout_editor_screen.dart';
import 'workout_screen.dart';

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
    _library = WorkoutLibrary(widget.storage ?? DeviceLibraryStorage());
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
      WorkoutTemplate? template;
      if (fromTemplate) {
        template = await Navigator.push<WorkoutTemplate>(
          context,
          MaterialPageRoute(builder: (_) => const TemplatePickerScreen()),
        );
        if (template == null || !mounted) return;
      }
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutEditorScreen(
            library: _library,
            plan: plan,
            initialName: template?.name ?? '',
            initialExercises: template?.exercises ?? const [],
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
          title: const Text('Padam latihan?'),
          content: Text('“${plan.name}” akan dipadam daripada Latihan Saya.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('PADAM'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _library.delete(plan.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Latihan tidak dapat dipadam. Cuba lagi.'),
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
      titleSpacing: 24,
      title: const Row(
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
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.orange,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Latihan tidak dapat dimuatkan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Data sedia ada tidak diubah. Cuba muatkan semula.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('CUBA LAGI'),
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
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.green,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Bermula dengan\nrentak anda.',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selamat datang ke PULSE. Pilih template sedia ada atau bina latihan yang sesuai dengan anda.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 30),
            _choice(
              icon: Icons.layers_outlined,
              title: 'Guna template',
              subtitle: 'Pilih rutin siap dan ubah mengikut keperluan.',
              onTap: () => _edit(fromTemplate: true),
            ),
            const SizedBox(height: 16),
            _choice(
              icon: Icons.edit_note_rounded,
              title: 'Cipta latihan sendiri',
              subtitle: 'Tentukan gerakan, masa senaman dan rehat anda.',
              onTap: () => _edit(),
            ),
            const SizedBox(height: 26),
            const Text(
              'Simpan banyak rutin. Pilih satu setiap kali anda bersedia untuk bergerak.',
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
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.green, size: 27),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _libraryView() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Latihan Saya',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_library.plans.length} rutin disimpan • Sedia apabila anda bersedia.',
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('CIPTA LATIHAN'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _edit(fromTemplate: true),
            icon: const Icon(Icons.layers_outlined),
            label: const Text('TAMBAH DARI TEMPLATE'),
          ),
          const SizedBox(height: 28),
          if (_library.plans.isEmpty)
            const Padding(
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
                    'Belum ada latihan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cipta rutin baharu atau pilih template untuk bermula.',
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
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 16),
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
                plan.name,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Urus ${plan.name}',
              onSelected: (action) {
                if (action == 'edit') {
                  _edit(plan: plan);
                } else {
                  _delete(plan);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit latihan')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Padam latihan'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${plan.exercises.length} gerakan • ${plan.totalSeconds ~/ 60}m ${plan.totalSeconds % 60}s',
          style: const TextStyle(color: AppColors.green, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Text(
          plan.exercises.map((e) => e.name).join('  ·  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            height: 1.5,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutScreen(
                exercises: plan.exercises,
                workoutName: plan.name,
              ),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('BUKA PEMASA'),
        ),
      ],
    ),
  );
}
