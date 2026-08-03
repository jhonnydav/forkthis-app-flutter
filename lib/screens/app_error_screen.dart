import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import '../widgets/app_shell.dart';

class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tabBar: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'That page is not available',
                style: AppText.h1(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The link may be outdated. Your saved information is still on this device.',
                style: AppText.body(color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Return home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
