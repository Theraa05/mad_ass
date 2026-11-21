import 'package:flutter/foundation.dart';

import '../models/report.dart';

/// The report being filled in across the two "Report an Issue" steps.
class ReportDraft {
  String category = 'Air Conditioning';
  String building = 'Block D';
  String room = '203H';
  String equipmentId = '';
  String description = '';
}

/// In-memory data for the prototype. Both dashboards read from here, so a
/// report submitted by a student shows up for management in the same app.
/// Data is lost when the app restarts.
///
/// TODO (real app): replace with Firestore / your API so reports are shared
/// between phones.
class ReportStore extends ChangeNotifier {
  ReportStore._() {
    _seed();
  }
  static final ReportStore instance = ReportStore._();

  final List<Report> _reports = [];
  int _next = 6;
  ReportDraft draft = ReportDraft();

  void resetDraft() => draft = ReportDraft();

  List<Report> get all {
    final list = [..._reports];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Report> forReporter(String email) =>
      all.where((r) => r.reporterEmail == email.toLowerCase()).toList();

  Report? byId(String id) {
    for (final r in _reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  Report submit({
    required String email,
    required String impact,
    required Urgency urgency,
    required bool hasPhoto,
  }) {
    final d = draft;
    final number = _next.toString().padLeft(3, '0');
    _next++;
    final report = Report(
      id: 'RPT-$number',
      category: d.category,
      equipmentId: d.equipmentId,
      building: d.building,
      room: d.room,
      description: d.description,
      impact: impact,
      urgency: urgency,
      hasPhoto: hasPhoto,
      reporterEmail: email.toLowerCase(),
      createdAt: DateTime.now(),
    );
    _reports.add(report);
    draft = ReportDraft();
    notifyListeners();
    return report;
  }

  void updateStatus(String id, ReportStatus status, {String? note}) {
    final r = byId(id);
    if (r == null) return;
    r.status = status;
    r.updatedAt = DateTime.now();
    if (note != null && note.isNotEmpty) r.managerNote = note;
    notifyListeners();
  }

  void markNotified(String id) {
    final r = byId(id);
    if (r == null) return;
    r.notifiedAt = DateTime.now();
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();
    _reports.addAll([
      Report(
        id: 'RPT-001',
        category: 'Air Conditioning',
        equipmentId: 'AC-D203H-101',
        building: 'Block D',
        room: '203H',
        description: 'Air conditioner keeps blowing warm air.',
        impact: 'Room becomes hot during classes.',
        urgency: Urgency.medium,
        hasPhoto: true,
        reporterEmail: 'student@student.tarc.edu.my',
        createdAt: now.subtract(const Duration(days: 3)),
        status: ReportStatus.needsInfo,
        managerNote: 'Please confirm which AC unit is affected.',
      ),
      Report(
        id: 'RPT-002',
        category: 'Electrical',
        equipmentId: 'SOCKET-C305-04',
        building: 'Block C',
        room: '305',
        description: 'Power sockets near the window are not working.',
        impact: 'Students cannot charge laptops during lectures.',
        urgency: Urgency.high,
        hasPhoto: false,
        reporterEmail: 'amir@student.tarc.edu.my',
        createdAt: now.subtract(const Duration(days: 2)),
        status: ReportStatus.underReview,
      ),
      Report(
        id: 'RPT-003',
        category: 'Plumbing',
        equipmentId: 'TAP-B112-02',
        building: 'Block B',
        room: '112',
        description: 'Tap in the pantry is leaking.',
        impact: 'Water pooling on the floor.',
        urgency: Urgency.medium,
        hasPhoto: true,
        reporterEmail: 'mei@student.tarc.edu.my',
        createdAt: now.subtract(const Duration(days: 1)),
        status: ReportStatus.inProgress,
      ),
      Report(
        id: 'RPT-004',
        category: 'Furniture',
        equipmentId: 'CHAIR-A210-17',
        building: 'Block A',
        room: '210',
        description: 'Chair leg is broken.',
        impact: 'Unsafe to sit on.',
        urgency: Urgency.low,
        hasPhoto: false,
        reporterEmail: 'student@student.tarc.edu.my',
        createdAt: now.subtract(const Duration(days: 6)),
        status: ReportStatus.resolved,
        notifiedAt: now.subtract(const Duration(days: 5)),
      ),
      Report(
        id: 'RPT-005',
        category: 'Network',
        equipmentId: 'WIFI-A104-02',
        building: 'Block A',
        room: '104',
        description: 'Wi-Fi drops every few minutes in the lab.',
        impact: 'Students cannot finish online quizzes.',
        urgency: Urgency.high,
        hasPhoto: false,
        reporterEmail: 'lim@student.tarc.edu.my',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ]);
  }
}
