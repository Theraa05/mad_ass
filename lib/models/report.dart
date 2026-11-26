import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../theme/app_theme.dart';

enum ReportStatus {
  submitted,
  underReview,
  assigned,
  inProgress,
  needsInfo,
  pendingVerification,
  returnedForRework,
  resolved,
}

extension ReportStatusX on ReportStatus {
  String get label => switch (this) {
    ReportStatus.submitted => 'Submitted',
    ReportStatus.underReview => 'Under review',
    ReportStatus.assigned => 'Assigned',
    ReportStatus.inProgress => 'In progress',
    ReportStatus.needsInfo => 'Needs info',
    ReportStatus.pendingVerification => 'Pending verification',
    ReportStatus.returnedForRework => 'Rework required',
    ReportStatus.resolved => 'Resolved',
  };

  IconData get icon => switch (this) {
    ReportStatus.submitted => Icons.send_rounded,
    ReportStatus.underReview => Icons.manage_search_rounded,
    ReportStatus.assigned => Icons.assignment_ind_rounded,
    ReportStatus.inProgress => Icons.engineering_rounded,
    ReportStatus.needsInfo => Icons.info_outline_rounded,
    ReportStatus.pendingVerification => Icons.fact_check_outlined,
    ReportStatus.returnedForRework => Icons.build_circle_outlined,
    ReportStatus.resolved => Icons.check_circle_rounded,
  };

  Color get color => switch (this) {
    ReportStatus.submitted => TarumtColors.primary,
    ReportStatus.underReview => TarumtColors.warning,
    ReportStatus.assigned => TarumtColors.primary,
    ReportStatus.inProgress => const Color(0xFF6C4AB6),
    ReportStatus.needsInfo => TarumtColors.accent,
    ReportStatus.pendingVerification => TarumtColors.warning,
    ReportStatus.returnedForRework => TarumtColors.accent,
    ReportStatus.resolved => TarumtColors.success,
  };

  Color get tint => switch (this) {
    ReportStatus.submitted => TarumtColors.primaryTint,
    ReportStatus.underReview => TarumtColors.warningTint,
    ReportStatus.assigned => TarumtColors.primaryTint,
    ReportStatus.inProgress => const Color(0xFFEFEAF8),
    ReportStatus.needsInfo => TarumtColors.accentTint,
    ReportStatus.pendingVerification => TarumtColors.warningTint,
    ReportStatus.returnedForRework => TarumtColors.accentTint,
    ReportStatus.resolved => TarumtColors.successTint,
  };

  int get progress => switch (this) {
    ReportStatus.submitted => 1,
    ReportStatus.underReview => 2,
    ReportStatus.assigned => 3,
    ReportStatus.inProgress => 3,
    ReportStatus.needsInfo => 2,
    ReportStatus.pendingVerification => 3,
    ReportStatus.returnedForRework => 3,
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

class ClarificationMessage {
  final String text;
  final String? authorEmail;
  final DateTime? sentAt;
  final bool fromCoordinator;
  final bool photoRequested;
  final Uint8List? photo;

  const ClarificationMessage({
    required this.text,
    required this.fromCoordinator,
    this.authorEmail,
    this.sentAt,
    this.photoRequested = false,
    this.photo,
  });
}

enum RepairFeedbackOutcome {
  works, stillNotWorking
}

class RepairFeedback {
  final String workOrderId;
  final int submissionNumber;
  final RepairFeedbackOutcome outcome;
  final String comment;
  final Uint8List? photo;
  final String submittedBy;
  final DateTime submittedAt;
  String? reviewedBy;
  DateTime? reviewedAt;

  RepairFeedback({
    required this.workOrderId,
    required this.submissionNumber,
    required this.outcome,
    required this.comment,
    required Uint8List? photo,
    required this.submittedBy,
    required this.submittedAt,
  }) : photo = photo == null
           ? null
           : Uint8List.fromList(photo).asUnmodifiableView();

  bool get isPendingReview => stillNotWorking && reviewedAt == null;
  bool get stillNotWorking => outcome == RepairFeedbackOutcome.stillNotWorking;
}

class ReportTimelineEvent {
  final String title;
  final String detail;
  final DateTime? at;

  const ReportTimelineEvent({
    required this.title,
    required this.detail,
    this.at,
  });
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

  // Priority confirmed by the coordinator.
  // The reporter's original urgency remains unchanged.
  Urgency? coordinatorPriority;
  int? estimatedMinutes;
  String? reviewedBy;
  DateTime? reviewedAt;
  String? workOrderId;

  final List<ClarificationMessage> clarificationMessages = [];
  final List<RepairFeedback> repairFeedback = [];

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
    this.coordinatorPriority,
    this.estimatedMinutes,
    this.reviewedBy,
    this.reviewedAt,
    this.workOrderId,
  }) : updatedAt = createdAt;

  String get location => '$building Room $room';
  String get dateLabel => formatDate(createdAt);

  IconData get icon => repairCategories
      .firstWhere((c) => c.label == category,
          orElse: () => RepairCategory(category, Icons.build_rounded))
      .icon;
}
