import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('CampusFix', style: TextStyle(fontSize: 14)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const ScreenTitle('Settings'),
          const SectionTitle('Photo storage'),
          const AppCard(
            child: Row(children: [
              IconBadge(Icons.cloud_done_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Uploaded photos',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        'Uploaded photos and submitted reports stay in your CampusFix account.',
                        style: TextStyle(
                            fontSize: 12, color: TarumtColors.muted)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  IconBadge(Icons.phone_android_rounded,
                      color: TarumtColors.accent,
                      background: TarumtColors.accentTint),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cached photos',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Text('Remove temporary photos from this device.',
                            style: TextStyle(
                                fontSize: 12, color: TarumtColors.muted)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cached photos cleared')),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Clear Cached Photos'),
                ),
              ],
            ),
          ),
          if (AuthService.current != null) ...[
            const SectionTitle('Account'),
            AppCard(
              padding: EdgeInsets.zero,
              child: MenuRow(
                Icons.logout_rounded,
                'Sign out',
                onTap: () {
                  AuthService.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.signIn, (route) => false);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
