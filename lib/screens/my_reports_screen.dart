import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  void _showDetails(BuildContext context, Report r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.id,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  ReportStatusChip(r.status),
                ],
              ),
              const SizedBox(height: 6),
              Text('${r.category} · ${r.location}',
                  style: const TextStyle(color: TarumtColors.muted)),
              const SizedBox(height: 14),
              Text(r.description),
              if (r.managerNote != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TarumtColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16, color: TarumtColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Maintenance: ${r.managerNote}',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              StatusTimeline(
                steps: const [
                  'Submitted',
                  'Under review',
                  'Technician assigned',
                  'Resolved',
                ],
                done: r.status.progress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStore.instance;
    final email = AuthService.current?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('CampusFix', style: TextStyle(fontSize: 14)),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final mine = store.forReporter(email);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const ScreenTitle('My Reports'),
              const SizedBox(height: 14),
              if (mine.isEmpty)
                const AppCard(
                  child: Row(children: [
                    IconBadge(Icons.inbox_outlined),
                    SizedBox(width: 12),
                    Expanded(child: Text('You have not sent any reports yet.')),
                  ]),
                ),
              for (final r in mine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child:
                      ReportTile(report: r, onTap: () => _showDetails(context, r)),
                ),
            ],
          );
        },
      ),
    );
  }
}
