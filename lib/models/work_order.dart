import 'dart:typed_data';

import 'report.dart';

class Technician {
  final String id;
  final String name;
  final String email;
  final List<String> specialties;

  const Technician(
      this.id,
      this.name,
      this.email,
      this.specialties,
      );

  bool supports(String category) {
    return specialties.any(
          (specialty) =>
      specialty.toLowerCase() ==
          category.trim().toLowerCase(),
    );
  }
}

const campusTechnicians = [
  Technician(
    'TECH-001',
    'Aina',
    'aina@tarc.edu.my',
    ['Air Conditioning'],
  ),
  Technician(
    'TECH-002',
    'Daniel',
    'daniel@tarc.edu.my',
    ['Air Conditioning'],
  ),
  Technician(
    'TECH-003',
    'Ravi',
    'ravi@tarc.edu.my',
    ['Electrical', 'Lighting'],
  ),
  Technician(
    'TECH-004',
    'Mei',
    'mei@tarc.edu.my',
    ['Plumbing'],
  ),
  Technician(
    'TECH-005',
    'Farid',
    'farid@tarc.edu.my',
    ['Network'],
  ),
  Technician(
    'TECH-006',
    'Chloe',
    'chloe@tarc.edu.my',
    ['Furniture'],
  ),
];

class RepairBlock {
  final DateTime start;
  final DateTime end;

  const RepairBlock(this.start, this.end);

  int get minutes => end.difference(start).inMinutes;

  bool overlaps(RepairBlock other) {
    return start.isBefore(other.end) &&
        end.isAfter(other.start);
  }
}

class PlannedAssignment {
  final String reportId;
  final Urgency priority;
  final int estimatedMinutes;
  final DateTime submittedAt;
  final List<RepairBlock> blocks;

  PlannedAssignment({
    required this.reportId,
    required this.priority,
    required this.estimatedMinutes,
    required this.submittedAt,
    required List<RepairBlock> blocks,
  }) : blocks = List.unmodifiable(blocks);
}

class AssignmentPlan {
  final String technicianId;
  final DateTime fromDate;
  final int revision;
  final List<PlannedAssignment> assignments;

  AssignmentPlan({
    required this.technicianId,
    required this.fromDate,
    required this.revision,
    required List<PlannedAssignment> assignments,
  }) : assignments = List.unmodifiable(assignments);
}

enum WorkOrderStatus {
  assigned,
  inProgress,
  onHold,
  pendingVerification,
  returnedForRework,
  resolved,
}

class PreventiveTask {
  final String sourceReportId;
  final String equipmentId;
  final String category;
  final String building;
  final String room;
  final String task;

  const PreventiveTask({
    required this.sourceReportId,
    required this.equipmentId,
    required this.category,
    required this.building,
    required this.room,
    required this.task,
  });

  String get location => '$building Room $room';
}

class RepairSubmission {
  final int number;
  final String repairNote;
  final Uint8List completionPhoto;
  final bool equipmentTested;
  final String submittedBy;
  final DateTime submittedAt;

  RepairSubmission({
    required this.number,
    required this.repairNote,
    required Uint8List completionPhoto,
    required this.equipmentTested,
    required this.submittedBy,
    required this.submittedAt,
  }) : completionPhoto = Uint8List.fromList(
    completionPhoto,
  ).asUnmodifiableView();
}

enum InspectionDecision {
  approved,
  reworkRequired,
}

class RepairInspection {
  final int submissionNumber;
  final InspectionDecision decision;
  final String note;
  final bool correctEquipmentChecked;
  final bool workingTestPassed;
  final bool photoReviewed;
  final String inspectedBy;
  final DateTime inspectedAt;

  const RepairInspection({
    required this.submissionNumber,
    required this.decision,
    required this.note,
    required this.correctEquipmentChecked,
    required this.workingTestPassed,
    required this.photoReviewed,
    required this.inspectedBy,
    required this.inspectedAt,
  });
}

class ReschedulePlan {
  final String workOrderId;
  final int revision;
  final DateTime requestedStart;
  final List<RepairBlock> blocks;

  ReschedulePlan({
    required this.workOrderId,
    required this.revision,
    required this.requestedStart,
    required List<RepairBlock> blocks,
  }) : blocks = List.unmodifiable(blocks);
}

class ScheduleChange {
  final List<RepairBlock> previousBlocks;
  final List<RepairBlock> newBlocks;
  final String reason;
  final String changedBy;
  final DateTime changedAt;

  ScheduleChange({
    required List<RepairBlock> previousBlocks,
    required List<RepairBlock> newBlocks,
    required this.reason,
    required this.changedBy,
    required this.changedAt,
  }) : previousBlocks = List.unmodifiable(previousBlocks),
        newBlocks = List.unmodifiable(newBlocks);
}

class WorkOrder {
  final String id;
  final String? reportId;
  final PreventiveTask? preventiveTask;
  final String technicianId;
  final Urgency priority;
  final int estimatedMinutes;

  List<RepairBlock> _blocks;

  final DateTime assignedAt;
  final String assignedBy;

  WorkOrderStatus status;

  final List<RepairSubmission> submissions = [];
  final List<RepairInspection> inspections = [];
  final List<ScheduleChange> scheduleChanges = [];

  WorkOrder({
    required this.id,
    this.reportId,
    this.preventiveTask,
    required this.technicianId,
    required this.priority,
    required this.estimatedMinutes,
    required List<RepairBlock> blocks,
    required this.assignedAt,
    required this.assignedBy,
    this.status = WorkOrderStatus.assigned,
  }) : assert(
  (reportId != null && preventiveTask == null) ||
      (reportId == null && preventiveTask != null),
  'A job must have either a repair report '
      'or a preventive task.',
  ),
        _blocks = List.unmodifiable(blocks);

  List<RepairBlock> get blocks => _blocks;

  bool get isPreventive => preventiveTask != null;

  bool get isOpen => status != WorkOrderStatus.resolved;

  RepairSubmission? get latestSubmission {
    return submissions.isEmpty ? null : submissions.last;
  }

  void recordReschedule(ScheduleChange change) {
    if (status != WorkOrderStatus.assigned) {
      throw StateError(
        'Only an assigned job can be rescheduled.',
      );
    }

    if (change.newBlocks.isEmpty) {
      throw ArgumentError(
        'A schedule must contain at least one time block.',
      );
    }

    _blocks = change.newBlocks;
    scheduleChanges.add(change);
  }
}