import 'package:flutter/material.dart';

import 'models/report.dart';
import 'screens/technician_jobs_screen.dart';
import 'services/auth_service.dart';
import 'services/report_store.dart';
import 'theme/app_theme.dart';

void main() {
  final store = ReportStore.instance;
  final tomorrow = DateTime.now().add(const Duration(days: 1));

  String createReport(String room, String description) {
    store.resetDraft();
    store.draft.room = room;
    store.draft.equipmentId = 'AC-D$room-101';
    store.draft.description = description;

    final report = store.submit(
      email: 'demo@tarc.edu.my',
      impact: 'The air conditioner needs inspection.',
      urgency: Urgency.values.first,
      hasPhoto: false,
    );

    store.saveReview(
      report.id,
      priority: report.urgency,
      estimatedMinutes: 30,
    );

    return report.id;
  }

  void assignJobs(String technicianId, Set<String> reportIds) {
    final plan = store.previewAssignments(
      technicianId: technicianId,
      reportIds: reportIds,
      fromDate: tomorrow,
    );
    store.confirmAssignments(plan);
  }

  AuthService.signIn('management@tarc.edu.my');

  assignJobs('TECH-001', {
    createReport('203H', 'The air conditioner blows warm air.'),
    createReport('205H', 'The air conditioner makes a rattling noise.'),
  });

  assignJobs('TECH-002', {
    createReport('208H', 'Water drips from the air conditioner.'),
  });

  AuthService.signIn('aina@tarc.edu.my');

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const TechnicianPreview(),
    ),
  );
}

class TechnicianPreview extends StatefulWidget {
  const TechnicianPreview({super.key});

  @override
  State<TechnicianPreview> createState() => _TechnicianPreviewState();
}

class _TechnicianPreviewState extends State<TechnicianPreview> {
  String _technicianId = 'TECH-001';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text('Demo technician'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _technicianId,
                    items: const [
                      DropdownMenuItem(
                        value: 'TECH-001',
                        child: Text('Aina'),
                      ),
                      DropdownMenuItem(
                        value: 'TECH-002',
                        child: Text('Daniel'),
                      ),
                    ],
                    onChanged: (id) {
                      if (id == null) return;
                      final technician = ReportStore.instance.technicianById(id);
                      if (technician == null) return;

                      AuthService.signIn(technician.email);
                      setState(() => _technicianId = id);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TechnicianJobsScreen(
              technicianId: _technicianId,
            ),
          ),
        ],
      ),
    );
  }
}