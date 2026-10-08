import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/pro_controller.dart';
import '../theme/app_theme.dart';

Future<void> showPro(BuildContext context) => Navigator.push<void>(
  context,
  MaterialPageRoute(builder: (_) => const ProScreen()),
);

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pro = ProScope.maybeOf(context);
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('PULSE PRO')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              size: 60,
              color: AppColors.green,
            ),
            const SizedBox(height: 20),
            Text(
              s.text(pro?.isPro == true ? 'proActive' : 'proTitle'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(s.text('proSubtitle')),
            const SizedBox(height: 24),
            for (final key in [
              'proRoutines',
              'proNoWatermark',
              'proPanel',
              'proThemes',
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.green,
                ),
                title: Text(s.text(key)),
              ),
            const SizedBox(height: 16),
            Text(s.text('proFreeFeatures')),
            const SizedBox(height: 20),
            if (pro?.isPro != true)
              FilledButton(
                key: const Key('buy-pro'),
                onPressed: pro?.canBuy == true ? pro!.buy : null,
                child: Text(
                  pro?.product == null
                      ? s.text('proBuy')
                      : s.text('proBuyPrice', {'price': pro!.product!.price}),
                ),
              ),
            OutlinedButton(
              key: const Key('restore-pro'),
              onPressed: pro?.enabled == true && pro?.busy == false
                  ? pro!.restore
                  : null,
              child: Text(s.text('proRestore')),
            ),
            if (pro?.busy == true)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (pro?.message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  s.text(pro!.message!),
                  key: const Key('pro-message'),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              s.text('proOffline'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
