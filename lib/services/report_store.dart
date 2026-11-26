import 'package:flutter/foundation.dart';

import '../models/report.dart';
import '../models/work_order.dart';
import 'auth_service.dart';
import 'repair_scheduler.dart';
import 'dart:typed_data';

class ReportDraft {
  String category = 'Air Conditioning';
  String building = 'Block D';
  String room = '203H';
  String equipmentId = '';
  String description = '';
}

class ReportStore extends ChangeNotifier {
  ReportStore._() {
    _seed();
  }

  static final ReportStore instance = ReportStore._();

  final List<Report> _reports = [];
  final List<WorkOrder> _workOrders = [];

  int _next = 6;
  int _nextWorkOrder = 1;
  int _assignmentRevision = 0;

  ReportDraft draft = ReportDraft();

  int get assignmentRevision => _assignmentRevision;

  @override
  void notifyListeners() {
    _assignmentRevision++;
    super.notifyListeners();
  }

  void resetDraft() {
    draft = ReportDraft();
  }

  List<Report> get all {
    final reports = [..._reports];

    reports.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return reports;
  }

  List<Report> forReporter(String email) {
    return all.where((report) {
      return report.reporterEmail ==
          email.trim().toLowerCase();
    }).toList();
  }

  Report? byId(String? id) {
    for (final report in _reports) {
      if (report.id == id) {
        return report;
      }
    }

    return null;
  }

  Report submit({
    required String email,
    required String impact,
    required Urgency urgency,
    required bool hasPhoto,
  }) {
    final currentDraft = draft;
    final number = _next.toString().padLeft(3, '0');

    _next++;

    final report = Report(
      id: 'RPT-$number',
      category: currentDraft.category,
      equipmentId: currentDraft.equipmentId,
      building: currentDraft.building,
      room: currentDraft.room,
      description: currentDraft.description,
      impact: impact,
      urgency: urgency,
      hasPhoto: hasPhoto,
      reporterEmail: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );

    _reports.add(report);
    resetDraft();
    notifyListeners();

    return report;
  }

  void updateStatus(
      String id,
      ReportStatus status, {
        String? note,
      }) {
    final report = byId(id);

    if (report == null) {
      return;
    }

    report.status = status;
    report.updatedAt = DateTime.now();

    if (note != null && note.isNotEmpty) {
      report.managerNote = note;
    }

    notifyListeners();
  }

  void markNotified(String id) {
    final report = byId(id);

    if (report == null) {
      return;
    }

    report.notifiedAt = DateTime.now();
    notifyListeners();
  }

  // ---------- Coordinator review ----------

  static String? validateEstimate(int minutes) {
    if (minutes < 15 ||
        minutes > 480 ||
        minutes % 15 != 0) {
      return 'Use 15–480 minutes, in 15-minute steps.';
    }

    return null;
  }

  void _requireCoordinator() {
    if (AuthService.current?.role != UserRole.management) {
      throw StateError(
        'Coordinator access is required.',
      );
    }
  }

  Report _reviewableReport(String id) {
    _requireCoordinator();

    final report = byId(id);

    if (report == null) {
      throw StateError('Report not found.');
    }

    const allowedStatuses = {
      ReportStatus.submitted,
      ReportStatus.underReview,
      ReportStatus.needsInfo,
    };

    if (report.workOrderId != null ||
        !allowedStatuses.contains(report.status)) {
      throw StateError(
        'This report is assigned, in progress or resolved.',
      );
    }

    return report;
  }

  Report saveReview(
      String id, {
        required Urgency priority,
        required int estimatedMinutes,
      }) {
    final report = _reviewableReport(id);
    final error = validateEstimate(estimatedMinutes);

    if (error != null) {
      throw ArgumentError(error);
    }

    final now = DateTime.now();

    report.coordinatorPriority = priority;
    report.estimatedMinutes = estimatedMinutes;
    report.reviewedBy = AuthService.current!.email;
    report.reviewedAt = now;
    report.updatedAt = now;

    if (report.status == ReportStatus.submitted) {
      report.status = ReportStatus.underReview;
    }

    notifyListeners();

    return report;
  }

  Report requestMoreInformation(
      String id, {
        required String question,
        bool requestPhoto = false,
      }) {
    final report = _reviewableReport(id);
    final text = question.trim();

    if (text.isEmpty || text.length > 500) {
      throw ArgumentError(
        'Enter a question of 1–500 characters.',
      );
    }

    // Preserve an existing clarification note.
    if (report.clarificationMessages.isEmpty &&
        report.status == ReportStatus.needsInfo &&
        report.managerNote?.trim().isNotEmpty == true) {
      report.clarificationMessages.add(
        ClarificationMessage(
          text: report.managerNote!.trim(),
          fromCoordinator: true,
        ),
      );
    }

    final now = DateTime.now();

    report.clarificationMessages.add(
      ClarificationMessage(
        text: text,
        authorEmail: AuthService.current!.email,
        sentAt: now,
        fromCoordinator: true,
        photoRequested: requestPhoto,
      ),
    );

    report.managerNote = requestPhoto
        ? '$text\nPlease attach a clear photo of the '
        'affected equipment or label.'
        : text;

    report.status = ReportStatus.needsInfo;
    report.updatedAt = now;

    notifyListeners();

    return report;
  }

  ClarificationMessage? pendingClarification(String id) {
    final report = byId(id);
    if (report == null) return null;
    if (report.clarificationMessages.isEmpty) {
      final note = report.managerNote?.trim();
      if (report.status == ReportStatus.needsInfo &&
          note != null &&
          note.isNotEmpty) {
        return ClarificationMessage(text: note, fromCoordinator: true);
      }
      return null;
    }
    final message = report.clarificationMessages.last;
    return message.fromCoordinator ? message : null;
  }

  void submitClarificationReply(
    String id, {
    required String reply,
    Uint8List? photo,
  }) {
    final report = byId(id);
    final user = AuthService.current;

    if (user == null || user.role != UserRole.reporter) {
      throw StateError('Reporter access is required.');
    }

    if (report == null || report.reporterEmail != user.email) {
      throw StateError('Only the report owner can reply.');
    }

    final text = reply.trim();
    if (text.isEmpty || text.length > 1000) {
      throw ArgumentError('Enter a reply of 1–1000 characters.');
    }

    final request = pendingClarification(id);
    if (request == null || report.status != ReportStatus.needsInfo) {
      throw StateError('This report has no clarification awaiting a reply.');
    }

    if (request.photoRequested && photo == null) {
      throw ArgumentError('Attach the requested photo before replying.');
    }

    _validateReporterPhoto(photo);
    final now = DateTime.now();
    report.clarificationMessages.add(
      ClarificationMessage(
        text: text,
        authorEmail: user.email,
        sentAt: now,
        fromCoordinator: false,
        photo: photo,
      ),
    );
    report.status = ReportStatus.underReview;
    report.updatedAt = now;
    notifyListeners();
  }

  static void _validateReporterPhoto(Uint8List? photo) {
    if (photo == null) return;

    final png =
        photo.length >= 8 &&
        photo[0] == 137 &&
        photo[1] == 80 &&
        photo[2] == 78 &&
        photo[3] == 71 &&
        photo[4] == 13 &&
        photo[5] == 10 &&
        photo[6] == 26 &&
        photo[7] == 10;
    final jpeg =
        photo.length >= 3 &&
        photo[0] == 255 &&
        photo[1] == 216 &&
        photo[2] == 255;

    if (photo.length > 5 * 1024 * 1024 || (!png && !jpeg)) {
      throw ArgumentError('Attach a JPG or PNG photo, up to 5 MB.');
    }
  }

  // ---------- Work orders and technicians ----------

  List<WorkOrder> get workOrders {
    return List<WorkOrder>.unmodifiable(_workOrders);
  }

  WorkOrder? workOrderById(String id) {
    for (final order in _workOrders) {
      if (order.id == id) {
        return order;
      }
    }

    return null;
  }

  Technician? technicianById(String id) {
    for (final technician in campusTechnicians) {
      if (technician.id == id) {
        return technician;
      }
    }

    return null;
  }

  List<WorkOrder> ordersForTechnician(
      String technicianId,
      ) {
    return _workOrders.where((order) {
      return order.technicianId == technicianId;
    }).toList();
  }

  int openJobs(String technicianId) {
    return ordersForTechnician(technicianId)
        .where((order) => order.isOpen)
        .length;
  }

  Report _readyForAssignment(String id) {
    final report = _reviewableReport(id);

    if (report.status != ReportStatus.underReview ||
        report.workOrderId != null ||
        report.reviewedAt == null ||
        report.coordinatorPriority == null ||
        report.estimatedMinutes == null ||
        validateEstimate(report.estimatedMinutes!) != null) {
      throw StateError(
        '${report.id}: save the review and finish '
            'clarification before assigning.',
      );
    }

    return report;
  }

  List<Report> readyForTechnician(
      Technician technician,
      ) {
    return all.where((report) {
      return report.status == ReportStatus.underReview &&
          report.workOrderId == null &&
          report.reviewedAt != null &&
          report.coordinatorPriority != null &&
          report.estimatedMinutes != null &&
          validateEstimate(report.estimatedMinutes!) == null &&
          technician.supports(report.category);
    }).toList();
  }

  // ---------- Schedule preview ----------

  AssignmentPlan previewAssignments({
    required String technicianId,
    required Set<String> reportIds,
    required DateTime fromDate,
  }) {
    _requireCoordinator();

    final technician = technicianById(technicianId);

    if (technician == null) {
      throw StateError('Technician not found.');
    }

    if (reportIds.isEmpty) {
      throw StateError(
        'Select at least one request.',
      );
    }

    final today = RepairScheduler.day(DateTime.now());
    final date = RepairScheduler.day(fromDate);

    final latestDate = DateTime(
      today.year,
      today.month,
      today.day + 30,
    );

    if (date.isBefore(today) ||
        date.isAfter(latestDate)) {
      throw StateError(
        'Choose a date from today to the next 30 days.',
      );
    }

    final reports = reportIds
        .map(_readyForAssignment)
        .toList();

    for (final report in reports) {
      if (!technician.supports(report.category)) {
        throw StateError(
          '${technician.name} does not handle '
              '${report.category}.',
        );
      }
    }

    // Both corrective and preventive jobs reserve time.
    final booked = <RepairBlock>[
      for (final order
      in ordersForTechnician(technicianId))
        if (order.isOpen) ...order.blocks,
    ];

    final assignments = RepairScheduler.plan(
      requests: reports,
      booked: booked,
      fromDate: date,
      now: DateTime.now(),
    );

    return AssignmentPlan(
      technicianId: technicianId,
      fromDate: date,
      revision: assignmentRevision,
      assignments: assignments,
    );
  }

  // ---------- Confirm repair assignment ----------

  List<WorkOrder> confirmAssignments(
      AssignmentPlan plan,
      ) {
    _requireCoordinator();

    if (plan.revision != assignmentRevision) {
      throw StateError(
        'Reports or bookings changed. '
            'Refresh the preview.',
      );
    }

    final reportIds = plan.assignments
        .map((assignment) => assignment.reportId)
        .toSet();

    if (reportIds.isEmpty ||
        reportIds.length != plan.assignments.length) {
      throw StateError(
        'Invalid assignment preview.',
      );
    }

    // Recheck the plan before changing any records.
    final freshPlan = previewAssignments(
      technicianId: plan.technicianId,
      reportIds: reportIds,
      fromDate: plan.fromDate,
    );

    if (!_sameAssignments(plan, freshPlan)) {
      throw StateError(
        'The preview expired or changed. '
            'Refresh it first.',
      );
    }

    final now = DateTime.now();
    final createdOrders = <WorkOrder>[];

    for (var index = 0;
    index < freshPlan.assignments.length;
    index++) {
      final assignment = freshPlan.assignments[index];

      final number = (_nextWorkOrder + index)
          .toString()
          .padLeft(3, '0');

      createdOrders.add(
        WorkOrder(
          id: 'WO-$number',
          reportId: assignment.reportId,
          technicianId: freshPlan.technicianId,
          priority: assignment.priority,
          estimatedMinutes: assignment.estimatedMinutes,
          blocks: assignment.blocks,
          assignedAt: now,
          assignedBy: AuthService.current!.email,
        ),
      );
    }

    for (final order in createdOrders) {
      final report = byId(order.reportId)!;

      report.workOrderId = order.id;
      report.status = ReportStatus.assigned;
      report.updatedAt = now;
    }

    _nextWorkOrder += createdOrders.length;
    _workOrders.addAll(createdOrders);

    notifyListeners();

    return List<WorkOrder>.unmodifiable(
      createdOrders,
    );
  }

  bool _sameAssignments(
      AssignmentPlan first,
      AssignmentPlan second,
      ) {
    if (first.assignments.length !=
        second.assignments.length) {
      return false;
    }

    for (var index = 0;
    index < first.assignments.length;
    index++) {
      final a = first.assignments[index];
      final b = second.assignments[index];

      if (a.reportId != b.reportId ||
          a.priority != b.priority ||
          a.estimatedMinutes != b.estimatedMinutes ||
          a.blocks.length != b.blocks.length) {
        return false;
      }

      for (var blockIndex = 0;
      blockIndex < a.blocks.length;
      blockIndex++) {
        final firstBlock = a.blocks[blockIndex];
        final secondBlock = b.blocks[blockIndex];

        if (firstBlock.start != secondBlock.start ||
            firstBlock.end != secondBlock.end) {
          return false;
        }
      }
    }

    return true;
  }

  // ---------- Planned preventive maintenance ----------

  WorkOrder createPreventiveJob({
    required String sourceReportId,
    required String task,
    required String technicianId,
    required DateTime start,
    required int estimatedMinutes,
  }) {
    _requireCoordinator();

    final source = byId(sourceReportId);

    if (source == null ||
        source.equipmentId.trim().isEmpty) {
      throw StateError(
        'Choose equipment from an existing report.',
      );
    }

    if (source.building.trim().isEmpty ||
        source.room.trim().isEmpty) {
      throw StateError(
        'The equipment needs complete building '
            'and room details.',
      );
    }

    final description = task.trim();

    if (description.isEmpty ||
        description.length > 500) {
      throw ArgumentError(
        'Enter a maintenance task of 1–500 characters.',
      );
    }

    final technician = technicianById(technicianId);

    if (technician == null ||
        !technician.supports(source.category)) {
      throw StateError(
        'Choose a technician who handles '
            '${source.category}.',
      );
    }

    if (validateEstimate(estimatedMinutes) != null ||
        estimatedMinutes > 240) {
      throw ArgumentError(
        'Use 15–240 minutes, in 15-minute steps.',
      );
    }

    final localStart = start.toLocal();

    final block = RepairBlock(
      localStart,
      localStart.add(
        Duration(minutes: estimatedMinutes),
      ),
    );

    final now = DateTime.now();

    final latestDate = DateTime(
      now.year,
      now.month,
      now.day + 365,
    );

    if (!localStart.isAfter(now) ||
        RepairScheduler.day(localStart)
            .isAfter(latestDate)) {
      throw StateError(
        'Choose a future time within the next 365 days.',
      );
    }

    if (!RepairScheduler.validBlock(block)) {
      throw StateError(
        'Use a weekday slot within 09:00–13:00 '
            'or 14:00–17:00. The whole task must fit '
            'before lunch or closing.',
      );
    }

    final equipment =
    source.equipmentId.trim().toLowerCase();

    for (final existing
    in _workOrders.where((order) => order.isOpen)) {
      final overlaps = existing.blocks.any(
            (busy) => busy.overlaps(block),
      );

      if (!overlaps) {
        continue;
      }

      if (existing.technicianId == technicianId) {
        throw StateError(
          '${technician.name} already has a job '
              'in that slot.',
        );
      }

      final otherEquipment =
          existing.preventiveTask?.equipmentId ??
              byId(existing.reportId)?.equipmentId;

      if (otherEquipment?.trim().toLowerCase() ==
          equipment) {
        throw StateError(
          'This equipment already has a job '
              'in that slot.',
        );
      }
    }

    final number = _nextWorkOrder
        .toString()
        .padLeft(3, '0');

    final order = WorkOrder(
      id: 'WO-$number',
      preventiveTask: PreventiveTask(
        sourceReportId: source.id,
        equipmentId: source.equipmentId,
        category: source.category,
        building: source.building,
        room: source.room,
        task: description,
      ),
      technicianId: technicianId,
      priority: Urgency.low,
      estimatedMinutes: estimatedMinutes,
      blocks: [block],
      assignedAt: now,
      assignedBy: AuthService.current!.email,
    );

    _nextWorkOrder++;
    _workOrders.add(order);

    notifyListeners();

    return order;
  }

  // ---------- Repair completion and verification ----------

  List<WorkOrder> get pendingVerifications {
    final orders = _workOrders.where((order) {
      return order.status ==
          WorkOrderStatus.pendingVerification;
    }).toList();

    orders.sort((a, b) {
      final firstTime =
          a.latestSubmission?.submittedAt ?? a.assignedAt;

      final secondTime =
          b.latestSubmission?.submittedAt ?? b.assignedAt;

      final time = firstTime.compareTo(secondTime);

      return time != 0 ? time : a.id.compareTo(b.id);
    });

    return orders;
  }

  List<RepairFeedback> get pendingRepairFeedbacks {
    final feedback = <RepairFeedback>[];
    for (final report in _reports) {
      feedback.addAll(
        report.repairFeedback.where((item) => item.isPendingReview),
      );
    }
    feedback.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    return List<RepairFeedback>.unmodifiable(feedback);
  }

  Report? reportForFeedback(RepairFeedback feedback) {
    for (final report in _reports) {
      if (report.repairFeedback.contains(feedback)) return report;
    }
    return null;
  }

  RepairFeedback submitRepairFeedback(
    String reportId, {
    required RepairFeedbackOutcome outcome,
    String comment = '',
    Uint8List? photo,
  }) {
    final report = byId(reportId);
    final user = AuthService.current;

    if (user == null || user.role != UserRole.reporter) {
      throw StateError('Reporter access is required.');
    }
    if (report == null || report.reporterEmail != user.email) {
      throw StateError('Only the report owner can submit feedback.');
    }
    if (report.workOrderId == null || report.status != ReportStatus.resolved) {
      throw StateError('Feedback is available after Coordinator approval.');
    }

    final order = workOrderById(report.workOrderId!);
    final submission = order?.latestSubmission;
    RepairInspection? approved;
    if (order != null && submission != null) {
      for (final inspection in order.inspections.reversed) {
        if (inspection.submissionNumber == submission.number &&
            inspection.decision == InspectionDecision.approved) {
          approved = inspection;
          break;
        }
      }
    }
    if (order == null || submission == null || approved == null) {
      throw StateError('Feedback is available after Coordinator approval.');
    }
    if (report.repairFeedback.any(
      (item) =>
          item.workOrderId == order.id &&
          item.submissionNumber == submission.number,
    )) {
      throw StateError('Feedback was already submitted for this repair.');
    }

    final text = comment.trim();
    if (outcome == RepairFeedbackOutcome.stillNotWorking && text.isEmpty) {
      throw ArgumentError('Explain what is still not working.');
    }
    if (text.length > 1000) {
      throw ArgumentError('Enter a comment of no more than 1000 characters.');
    }
    _validateReporterPhoto(photo);

    final feedback = RepairFeedback(
      workOrderId: order.id,
      submissionNumber: submission.number,
      outcome: outcome,
      comment: text,
      photo: photo,
      submittedBy: user.email,
      submittedAt: DateTime.now(),
    );
    report.repairFeedback.add(feedback);
    notifyListeners();
    return feedback;
  }

  void markRepairFeedbackReviewed(
    String reportId, {
    String? workOrderId,
    int? submissionNumber,
  }) {
    _requireCoordinator();
    final report = byId(reportId);
    if (report == null) throw StateError('Report not found.');
    final feedback = report.repairFeedback.firstWhere(
      (item) =>
          item.isPendingReview &&
          (workOrderId == null || item.workOrderId == workOrderId) &&
          (submissionNumber == null ||
              item.submissionNumber == submissionNumber),
      orElse: () => throw StateError('No feedback is awaiting review.'),
    );
    feedback.reviewedBy = AuthService.current!.email;
    feedback.reviewedAt = DateTime.now();
    notifyListeners();
  }

  List<ReportTimelineEvent> timelineForReport(String reportId) {
    final report = byId(reportId);
    if (report == null) return const [];

    final events = <ReportTimelineEvent>[
      ReportTimelineEvent(
        title: 'Report submitted',
        detail: report.description,
        at: report.createdAt,
      ),
    ];
    for (final message in report.clarificationMessages) {
      events.add(
        ReportTimelineEvent(
          title: message.fromCoordinator
              ? 'Coordinator requested information'
              : 'Reporter provided information',
          detail: message.text,
          at: message.sentAt,
        ),
      );
    }
    if (report.clarificationMessages.isEmpty &&
        report.status == ReportStatus.needsInfo &&
        report.managerNote?.trim().isNotEmpty == true) {
      events.add(
        ReportTimelineEvent(
          title: 'Coordinator requested information',
          detail: report.managerNote!.trim(),
        ),
      );
    }
    final order = report.workOrderId == null
        ? null
        : workOrderById(report.workOrderId!);
    if (order != null) {
      events.add(
        ReportTimelineEvent(
          title: 'Technician assigned',
          detail: order.id,
          at: order.assignedAt,
        ),
      );
      for (final change in order.scheduleChanges) {
        events.add(
          ReportTimelineEvent(
            title: 'Schedule adjusted',
            detail: change.reason,
            at: change.changedAt,
          ),
        );
      }
      for (final submission in order.submissions) {
        events.add(
          ReportTimelineEvent(
            title: 'Technician submitted completion',
            detail: submission.repairNote,
            at: submission.submittedAt,
          ),
        );
      }
      for (final inspection in order.inspections) {
        events.add(
          ReportTimelineEvent(
            title: inspection.decision == InspectionDecision.approved
                ? 'Coordinator approved repair'
                : 'Coordinator returned repair for rework',
            detail: inspection.note,
            at: inspection.inspectedAt,
          ),
        );
      }
    }
    events.sort((a, b) {
      if (a.at == null && b.at == null) return 0;
      if (a.at == null) return -1;
      if (b.at == null) return 1;
      return a.at!.compareTo(b.at!);
    });
    return List<ReportTimelineEvent>.unmodifiable(events);
  }

  WorkOrder _existingOrder(String id) {
    final order = workOrderById(id);

    if (order == null) {
      throw StateError('Work order not found.');
    }

    return order;
  }

  Report? _linkedRepairReport(WorkOrder order) {
    if (order.isPreventive) {
      return null;
    }

    final report = byId(order.reportId);

    if (report == null || report.workOrderId != order.id) {
      throw StateError(
        'The work order is not linked to the correct report.',
      );
    }

    return report;
  }

  void _requireAssignedTechnician(WorkOrder order) {
    final technician = technicianById(
      order.technicianId,
    );

    if (technician == null ||
        AuthService.current?.email != technician.email) {
      throw StateError(
        'Only the assigned technician can update this job.',
      );
    }
  }

// Called by YT's Start Work or Continue Repair button.
  void startWorkOrder(String workOrderId) {
    final order = _existingOrder(workOrderId);

    _requireAssignedTechnician(order);

    if (order.status != WorkOrderStatus.assigned &&
        order.status != WorkOrderStatus.returnedForRework) {
      throw StateError(
        'This job cannot be started in its current status.',
      );
    }

    final report = _linkedRepairReport(order);

    order.status = WorkOrderStatus.inProgress;

    if (report != null) {
      report.status = ReportStatus.inProgress;
      report.updatedAt = DateTime.now();
    }

    notifyListeners();
  }

// Called by YT's Submit for Verification button.
  void submitRepairForVerification({
    required String workOrderId,
    required String repairNote,
    required Uint8List completionPhoto,
    required bool equipmentTested,
  }) {
    final order = _existingOrder(workOrderId);

    _requireAssignedTechnician(order);

    if (order.status != WorkOrderStatus.inProgress) {
      throw StateError(
        'Start the repair before submitting completion.',
      );
    }

    final report = _linkedRepairReport(order);
    final note = repairNote.trim();

    if (note.isEmpty || note.length > 1000) {
      throw ArgumentError(
        'Enter a repair note of 1–1000 characters.',
      );
    }

    if (!equipmentTested) {
      throw StateError(
        'Test the equipment before submitting.',
      );
    }

    final png = completionPhoto.length >= 8 &&
        completionPhoto[0] == 137 &&
        completionPhoto[1] == 80 &&
        completionPhoto[2] == 78 &&
        completionPhoto[3] == 71 &&
        completionPhoto[4] == 13 &&
        completionPhoto[5] == 10 &&
        completionPhoto[6] == 26 &&
        completionPhoto[7] == 10;

    final jpeg = completionPhoto.length >= 3 &&
        completionPhoto[0] == 255 &&
        completionPhoto[1] == 216 &&
        completionPhoto[2] == 255;

    if (completionPhoto.length > 5 * 1024 * 1024 ||
        (!png && !jpeg)) {
      throw ArgumentError(
        'Attach a JPG or PNG completion photo, up to 5 MB.',
      );
    }

    final now = DateTime.now();

    order.submissions.add(
      RepairSubmission(
        number: order.submissions.length + 1,
        repairNote: note,
        completionPhoto: completionPhoto,
        equipmentTested: equipmentTested,
        submittedBy: AuthService.current!.email,
        submittedAt: now,
      ),
    );

    order.status = WorkOrderStatus.pendingVerification;

    if (report != null) {
      report.status = ReportStatus.pendingVerification;
      report.updatedAt = now;
    }

    notifyListeners();
  }

  void verifyRepair({
    required String workOrderId,
    required int expectedSubmissionNumber,
    required InspectionDecision decision,
    required String inspectionNote,
    required bool correctEquipmentChecked,
    required bool workingTestPassed,
    required bool photoReviewed,
  }) {
    _requireCoordinator();

    final order = _existingOrder(workOrderId);
    final submission = order.latestSubmission;

    if (order.status !=
        WorkOrderStatus.pendingVerification ||
        submission == null) {
      throw StateError(
        'This job has no completion awaiting verification.',
      );
    }

    if (submission.number != expectedSubmissionNumber) {
      throw StateError(
        'New completion evidence arrived. '
            'Reopen the inspection.',
      );
    }

    final alreadyInspected = order.inspections.any(
          (inspection) =>
      inspection.submissionNumber == submission.number,
    );

    if (alreadyInspected) {
      throw StateError(
        'This completion has already been inspected.',
      );
    }

    final report = _linkedRepairReport(order);
    final note = inspectionNote.trim();

    if (note.isEmpty || note.length > 1000) {
      throw ArgumentError(
        'Enter an inspection note of 1–1000 characters.',
      );
    }

    final approved =
        decision == InspectionDecision.approved;

    if (approved &&
        (!submission.equipmentTested ||
            !correctEquipmentChecked ||
            !workingTestPassed ||
            !photoReviewed)) {
      throw StateError(
        'Confirm equipment, working test and '
            'completion photo before approval.',
      );
    }

    final now = DateTime.now();

    order.inspections.add(
      RepairInspection(
        submissionNumber: submission.number,
        decision: decision,
        note: note,
        correctEquipmentChecked: correctEquipmentChecked,
        workingTestPassed: workingTestPassed,
        photoReviewed: photoReviewed,
        inspectedBy: AuthService.current!.email,
        inspectedAt: now,
      ),
    );

    order.status = approved
        ? WorkOrderStatus.resolved
        : WorkOrderStatus.returnedForRework;

    if (report != null) {
      report.status = approved
          ? ReportStatus.resolved
          : ReportStatus.returnedForRework;

      report.managerNote = approved
          ? 'Repair completed: ${submission.repairNote}\n'
          'Coordinator inspection: $note'
          : 'Repair requires rework: $note';

      report.updatedAt = now;
    }

    notifyListeners();
  }
  // ---------- Adjust an assigned job's schedule ----------

  bool _sameRepairBlocks(
      List<RepairBlock> first,
      List<RepairBlock> second,
      ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0;
    index < first.length;
    index++) {
      if (first[index].start != second[index].start ||
          first[index].end != second[index].end) {
        return false;
      }
    }

    return true;
  }

  ReschedulePlan previewReschedule({
    required String workOrderId,
    required DateTime start,
  }) {
    _requireCoordinator();

    final order = _existingOrder(workOrderId);

    if (order.status != WorkOrderStatus.assigned) {
      throw StateError(
        'Adjust Time is available before the job starts.',
      );
    }

    final report = _linkedRepairReport(order);
    final local = start.toLocal();
    final now = DateTime.now();

    final latestDate = DateTime(
      now.year,
      now.month,
      now.day + 365,
    );

    if (!local.isAfter(now) ||
        RepairScheduler.day(local).isAfter(latestDate)) {
      throw StateError(
        'Choose a future time within the next 365 days.',
      );
    }

    final equipment = (
        order.preventiveTask?.equipmentId ??
            report?.equipmentId
    )?.trim().toLowerCase();

    final booked = <RepairBlock>[];

    for (final other in _workOrders) {
      if (!other.isOpen || other.id == order.id) {
        continue;
      }

      final otherEquipment = (
          other.preventiveTask?.equipmentId ??
              byId(other.reportId)?.equipmentId
      )?.trim().toLowerCase();

      final sameTechnician =
          other.technicianId == order.technicianId;

      final sameEquipment = equipment != null &&
          equipment.isNotEmpty &&
          equipment == otherEquipment;

      if (sameTechnician || sameEquipment) {
        booked.addAll(other.blocks);
      }
    }

    final blocks = RepairScheduler.blocksFrom(
      minutes: order.estimatedMinutes,
      start: local,
      booked: booked,
    );

    if (order.isPreventive && blocks.length != 1) {
      throw StateError(
        'Preventive servicing needs one continuous '
            'free slot before lunch or closing.',
      );
    }

    if (_sameRepairBlocks(order.blocks, blocks)) {
      throw StateError(
        'Choose a different time from the current schedule.',
      );
    }

    return ReschedulePlan(
      workOrderId: order.id,
      revision: assignmentRevision,
      requestedStart: local,
      blocks: blocks,
    );
  }

  void confirmReschedule(
      ReschedulePlan plan, {
        required String reason,
      }) {
    _requireCoordinator();

    if (plan.revision != assignmentRevision) {
      throw StateError(
        'Jobs or bookings changed. '
            'Preview the new time again.',
      );
    }

    final fresh = previewReschedule(
      workOrderId: plan.workOrderId,
      start: plan.requestedStart,
    );

    if (!_sameRepairBlocks(plan.blocks, fresh.blocks)) {
      throw StateError(
        'This preview changed. '
            'Preview the new time again.',
      );
    }

    final text = reason.trim();

    if (text.isEmpty || text.length > 500) {
      throw ArgumentError(
        'Enter a rescheduling reason of 1–500 characters.',
      );
    }

    final order = _existingOrder(plan.workOrderId);
    final report = _linkedRepairReport(order);
    final now = DateTime.now();

    order.recordReschedule(
      ScheduleChange(
        previousBlocks: order.blocks,
        newBlocks: fresh.blocks,
        reason: text,
        changedBy: AuthService.current!.email,
        changedAt: now,
      ),
    );

    if (report != null) {
      report.updatedAt = now;
    }

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
        description:
        'Air conditioner keeps blowing warm air.',
        impact: 'Room becomes hot during classes.',
        urgency: Urgency.medium,
        hasPhoto: true,
        reporterEmail: 'student@student.tarc.edu.my',
        createdAt: now.subtract(
          const Duration(days: 3),
        ),
        status: ReportStatus.needsInfo,
        managerNote:
        'Please confirm which AC unit is affected.',
      ),
      Report(
        id: 'RPT-002',
        category: 'Electrical',
        equipmentId: 'SOCKET-C305-04',
        building: 'Block C',
        room: '305',
        description:
        'Power sockets near the window are not working.',
        impact:
        'Students cannot charge laptops during lectures.',
        urgency: Urgency.high,
        hasPhoto: false,
        reporterEmail: 'amir@student.tarc.edu.my',
        createdAt: now.subtract(
          const Duration(days: 2),
        ),
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
        createdAt: now.subtract(
          const Duration(days: 1),
        ),
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
        createdAt: now.subtract(
          const Duration(days: 6),
        ),
        status: ReportStatus.resolved,
        notifiedAt: now.subtract(
          const Duration(days: 5),
        ),
      ),
      Report(
        id: 'RPT-005',
        category: 'Network',
        equipmentId: 'WIFI-A104-02',
        building: 'Block A',
        room: '104',
        description:
        'Wi-Fi drops every few minutes in the lab.',
        impact:
        'Students cannot finish online quizzes.',
        urgency: Urgency.high,
        hasPhoto: false,
        reporterEmail: 'lim@student.tarc.edu.my',
        createdAt: now.subtract(
          const Duration(hours: 3),
        ),
      ),
    ]);
  }
}