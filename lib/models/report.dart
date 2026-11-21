import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../theme/app_theme.dart';

enum ReportStatus { submitted, underReview, inProgress, needsInfo, resolved }

extension ReportStatusX on ReportStatus {
  String get label => switch (this) {
        ReportStatus.submitted => 'Submitted',
        ReportStatus.underReview => 'Under review',
        ReportStatus.inProgress => 'In progress',
        ReportStatus.needsInfo => 'Needs info',
        ReportStatus.resolved => 'Resolved',
      };

  IconData get icon => switch (this) {
        ReportStatus.submitted => Icons.send_rounded,
        ReportStatus.underReview => Icons.manage_search_rounded,
        ReportStatus.inProgress => Icons.engineering_rounded,
        ReportStatus.needsInfo => Icons.info_outline_rounded,
        ReportStatus.resolved => Icons.check_circle_rounded,
      };

  Color get color => switch (this) {
        ReportStatus.submitted => TarumtColors.primary,
        ReportStatus.underReview => TarumtColors.warning,
        ReportStatus.inProgress => const Color(0xFF6C4AB6),
        ReportStatus.needsInfo => TarumtColors.accent,
        ReportStatus.resolved => TarumtColors.success,
      };

  Color get tint => switch (this) {
        ReportStatus.submitted => TarumtColors.primaryTint,
        ReportStatus.underReview => TarumtColors.warningTint,
        ReportStatus.inProgress => const Color(0xFFEFEAF8),
        ReportStatus.needsInfo => TarumtColors.accentTint,
        ReportStatus.resolved => TarumtColors.successTint,
      };

  /// How many steps of the 4-step timeline are done.
  int get progress => switch (this) {
        ReportStatus.submitted => 1,
        ReportStatus.underReview => 2,
        ReportStatus.needsInfo => 2,
        ReportStatus.inProgress => 3,
        ReportStatus.resolved => 4,
      };
}

enum Urgency { low, medium, high }

extension UrgencyX on Urgency {
  String get label => switch (this) {
        Urgency.low => 'Low',
        Urgency.medium => 'Medium',
        Urgency.high => 'High',
      };
}

String formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class Report {
  final String id;
  final String category;
  final String equipmentId;
  final String building;
  final String room;
  final String description;
  final String impact;
  final Urgency urgency;
  final bool hasPhoto;
  final String reporterEmail;
  final DateTime createdAt;

  // These change when management updates the report.
  ReportStatus status;
  String? managerNote;
  DateTime updatedAt;
  DateTime? notifiedAt;

  Report({
    required this.id,
    required this.category,
    required this.equipmentId,
    required this.building,
    required this.room,
    required this.description,
    required this.impact,
    required this.urgency,
    required this.hasPhoto,
    required this.reporterEmail,
    required this.createdAt,
    this.status = ReportStatus.submitted,
    this.managerNote,
    this.notifiedAt,
  }) : updatedAt = createdAt;

  String get location => '$building Room $room';
  String get dateLabel => formatDate(createdAt);

  IconData get icon => repairCategories
      .firstWhere((c) => c.label == category,
          orElse: () => RepairCategory(category, Icons.build_rounded))
      .icon;
}
