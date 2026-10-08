import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/language_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final controller = LanguageScope.maybeOf(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.text('settings'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              s.text('chooseLanguage'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(s.text('languageHint')),
            const SizedBox(height: 16),
            for (final entry in AppStrings.languages.entries)
              ListTile(
                key: Key('language-${entry.key}'),
                title: Text(
                  entry.value,
                  textDirection: entry.key == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
                trailing: controller.code == entry.key
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.circle_outlined),
                enabled: !controller.busy,
                onTap: () async {
                  final saved = await controller.select(entry.key);
                  if (!context.mounted || saved) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.of(context).text('languageSaveError'),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            Text(s.text('customTextHint')),
          ],
        ),
      ),
    );
  }
}
