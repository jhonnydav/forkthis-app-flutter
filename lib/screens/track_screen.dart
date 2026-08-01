import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_toast.dart';
import '../widgets/product_sheet.dart';

/// Ported from `TrackScreen`/`QuickLogDrawer` in `../app/src/screens/NotBuilt.tsx`
/// (S-25–S-29).
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  void _openQuickLog(BuildContext context) {
    final state = context.read<AppState>();
    showProductSheet(
      context,
      title: 'Quick log',
      description: 'Add the small things without breaking your flow.',
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          children: [
            _QuickLogRow(
              icon: Icons.water_drop_rounded,
              iconBg: AppColors.mint,
              title: 'Water',
              subtitle: 'Add one 8 oz cup',
              onTap: () {
                state.addWater();
                Navigator.of(context).pop();
                showAppToast(context, 'Added one cup of water');
              },
            ),
            const SizedBox(height: 12),
            _QuickLogRow(
              icon: Icons.favorite_rounded,
              iconBg: AppColors.warmSurface,
              title: 'Movement',
              subtitle: 'Add a 10-minute session',
              onTap: () {
                state.addMovement(10);
                Navigator.of(context).pop();
                showAppToast(context, 'Added 10 minutes of movement');
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/eat-out');
                },
                child: const Text('Browse meals to log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final totalCalories = state.logs.fold<int>(0, (sum, l) => sum + l.calories);
    final totalProtein = state.logs.fold<int>(0, (sum, l) => sum + l.protein);
    final percent = ((totalCalories / 1850) * 100).clamp(0, 100).round();

    return AppShell(
      child: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY',
                          style: AppText.eyebrow(color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text('Your day has room', style: AppText.h1()),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            'A useful snapshot, not a scorecard. Log what helps and leave the rest.',
                            style: AppText.bodySm(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      onPressed: () => _openQuickLog(context),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: Color(0x1A0F3A27)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY ENERGY',
                              style: AppText.eyebrow(color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalCalories',
                              style: const TextStyle(
                                fontSize: 44,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('of 1,850 calories', style: AppText.caption()),
                          ],
                        ),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: CircularProgressIndicator(
                              value: percent / 100,
                              strokeWidth: 9,
                              backgroundColor: AppColors.secondary,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$percent%', style: AppText.h2()),
                              Text(
                                'TODAY',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCell(
                            icon: Icons.local_fire_department_rounded,
                            color: AppColors.coral,
                            value: '${totalProtein}g',
                            label: 'Protein',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: _StatCell(
                              icon: Icons.water_drop_rounded,
                              color: AppColors.primary,
                              value: '${state.waterCups} cups',
                              label: 'Water',
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: _StatCell(
                              icon: Icons.favorite_rounded,
                              color: AppColors.success,
                              value: '${state.movementMinutes} min',
                              label: 'Movement',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SO FAR',
                          style: AppText.eyebrow(color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text('What you logged', style: AppText.h2()),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openQuickLog(context),
                    child: Text(
                      'Add item',
                      style: AppText.label(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            if (state.logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nothing logged yet', style: AppText.h3()),
                      const SizedBox(height: 4),
                      Text(
                        'Start with water, movement, or a meal when you are ready.',
                        style: AppText.bodySm(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final item in state.logs)
                Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          item.image,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppText.h3(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.calories} cal · ${item.protein}g protein',
                              style: AppText.caption(),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          context.read<AppState>().removeLog(item.id);
                          showAppToast(context, 'Removed from today');
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatCell({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 8),
        Text(value, style: AppText.label()),
        Text(label, style: AppText.caption()),
      ],
    );
  }
}

class _QuickLogRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickLogRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3()),
                  Text(subtitle, style: AppText.caption()),
                ],
              ),
            ),
            const Icon(Icons.add_rounded),
          ],
        ),
      ),
    );
  }
}
