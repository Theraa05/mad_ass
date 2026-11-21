import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/scanner_frame.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Report an Issue', style: TextStyle(fontSize: 14)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenTitle('Scan equipment'),
              const SizedBox(height: 4),
              const Text('Align the equipment label inside the guide.',
                  style: TextStyle(color: TarumtColors.muted)),
              const SizedBox(height: 16),
              const ScannerFrame(),
              const SizedBox(height: 16),
              const AppCard(
                child: Row(children: [
                  IconBadge(Icons.check_circle_rounded,
                      color: TarumtColors.success,
                      background: TarumtColors.successTint),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Equipment found',
                            style: TextStyle(
                                fontSize: 11,
                                color: TarumtColors.success,
                                fontWeight: FontWeight.w700)),
                        Text('AC-D203H-101',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('Air Conditioning · Block D Room 203H',
                            style: TextStyle(
                                fontSize: 12, color: TarumtColors.muted)),
                      ],
                    ),
                  ),
                ]),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  final d = ReportStore.instance.draft;
                  d.category = 'Air Conditioning';
                  d.building = 'Block D';
                  d.room = '203H';
                  d.equipmentId = 'AC-D203H-101';
                  Navigator.pushNamed(context, AppRoutes.details);
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Use Equipment Details'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  ReportStore.instance.resetDraft();
                  Navigator.pushNamed(context, AppRoutes.details);
                },
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('Enter Manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
