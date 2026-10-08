import 'package:flutter/material.dart';
import '../data/workout_presets.dart';
import '../theme/app_theme.dart';

class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pilih template')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Satu permulaan\nyang baik.',
            style: TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pilih rutin, kemudian ubah gerakan dan masa mengikut keselesaan anda sebelum menyimpan.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          ...workoutTemplates.map(
            (template) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context, template),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        template.description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${template.exercises.length} gerakan • ${template.exercises.first.workoutSeconds}s senaman / ${template.exercises.first.restSeconds}s rehat',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        template.exercises.map((e) => e.name).join('  ·  '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'GUNAKAN TEMPLATE',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
