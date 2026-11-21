import 'package:flutter/material.dart';

import '../models/report.dart';
import '../routes.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';

class SubmittedScreen extends StatelessWidget {
  const SubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The new report is passed in as a route argument.
    final report = (ModalRoute.of(context)?.settings.arguments as Report?) ??
        ReportStore.instance.all.first;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: TarumtColors.heroGradient,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: ScreenTitle('Issue submitted')),
            const SizedBox(height: 4),
            const Center(
              child: Text('Your report was sent to maintenance.',
                  style: TextStyle(color: TarumtColors.muted)),
            ),
            const SizedBox(height: 22),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(report.id,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      ReportStatusChip(report.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(report.icon, report.category),
                  _InfoLine(Icons.location_on_outlined, report.location),
                  _InfoLine(Icons.calendar_today_outlined, report.dateLabel),
                  const Divider(height: 28),
                  StatusTimeline(
                    steps: const [
                      'Submitted',
                      'Under review',
                      'Technician assigned',
                      'Resolved',
                    ],
                    done: report.status.progress,
                  ),
                  const Divider(height: 28),
                  const Row(children: [
                    Icon(Icons.mark_email_read_outlined,
                        size: 14, color: TarumtColors.muted),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          'We will email you when this issue is resolved.',
                          style: TextStyle(
                              fontSize: 11, color: TarumtColors.muted)),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (route) => false),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.myReports, (route) => route.isFirst),
              icon: const Icon(Icons.description_outlined),
              label: const Text('View My Reports'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: TarumtColors.muted),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ]),
      );
}
