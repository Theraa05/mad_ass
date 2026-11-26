import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';
import 'reporter_report_details.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  void _showDetails(BuildContext context, Report r) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReporterReportDetailsScreen(reportId: r.id),
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
