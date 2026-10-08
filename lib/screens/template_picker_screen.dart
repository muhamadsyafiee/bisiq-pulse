import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import '../data/workout_presets.dart';
import '../theme/app_theme.dart';

class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppStrings.of(context).text('pickTemplate'))),
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text(
            AppStrings.of(context).text('templateTitle'),
            style: TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            AppStrings.of(context).text('templateHint'),
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          SizedBox(height: 24),
          ...workoutTemplates.map(
            (template) => Card(
              margin: EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context, template),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppStrings.of(context).text(template.nameKey),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppStrings.of(context).text(template.descriptionKey),
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                      SizedBox(height: 12),
                      Text(
                        AppStrings.of(context).text('templateSummary', {
                          'count': template.exercises.length,
                          'work': template.exercises.first.workoutSeconds,
                          'rest': template.exercises.first.restSeconds,
                        }),
                        style: TextStyle(color: AppColors.green, fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      Text(
                        template.exercises
                            .map((e) => e.displayName(AppStrings.of(context)))
                            .join('  ·  '),
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.of(context).text('useTemplateButton'),
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
