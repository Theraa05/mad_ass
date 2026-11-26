import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/work_order.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';
import 'provide_more_information_screen.dart';
import 'review_repair_screen.dart';

class ReporterReportDetailsScreen extends StatelessWidget {
  const ReporterReportDetailsScreen({super.key, required this.reportId});

  final String reportId;

  bool _canReview(Report report, ReportStore store) {
    if (report.status != ReportStatus.resolved || report.workOrderId == null) {
      return false;
    }
    final order = store.workOrderById(report.workOrderId!);
    final submission = order?.latestSubmission;
    return submission != null &&
        (order?.inspections.any(
              (inspection) =>
                  inspection.submissionNumber == submission.number &&
                  inspection.decision == InspectionDecision.approved,
            ) ??
            false);
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Report Details'),
      ),
      body: ListenableBuilder(
        listenable: ReportStore.instance,
        builder: (context, _) {
          final store = ReportStore.instance;
          final report = store.byId(reportId);
          if (report == null) {
            return const Center(child: Text('Report not found.'));
          }
          final request = store.pendingClarification(report.id);
          final order = report.workOrderId == null
              ? null
              : store.workOrderById(report.workOrderId!);
          final submission = order?.latestSubmission;
          RepairFeedback? feedback;
          for (final item in report.repairFeedback) {
            if (item.workOrderId == order?.id &&
                item.submissionNumber == submission?.number) {
              feedback = item;
              break;
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.id,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ReportStatusChip(report.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${report.category} · ${report.location}',
                style: const TextStyle(color: TarumtColors.muted),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Equipment: ${report.equipmentId.isEmpty ? 'Not specified' : report.equipmentId}',
                    ),
                    Text('Submitted: ${_stamp(context, report.createdAt)}'),
                    Text(
                      'Impact: ${report.impact.isEmpty ? 'Not provided' : report.impact}',
                    ),
                  ],
                ),
              ),
              if (request != null) ...[
                const SectionTitle('Action required'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coordinator asked for more information.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(request.text),
                      if (request.photoRequested) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'A photo is required for this reply.',
                          style: TextStyle(color: TarumtColors.accent),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('provide-more-information'),
                        onPressed: () => _open(
                          context,
                          ProvideMoreInformationScreen(reportId: report.id),
                        ),
                        icon: const Icon(Icons.reply_rounded),
                        label: const Text('Provide More Information'),
                      ),
                    ],
                  ),
                ),
              ],
              const SectionTitle('Clarification history'),
              if (report.clarificationMessages.isEmpty)
                const AppCard(child: Text('No clarification messages yet.'))
              else
                for (final message in report.clarificationMessages)
                  _ClarificationCard(message: message),
              const SectionTitle('Report Details & Timeline'),
              AppCard(
                child: Column(
                  children: [
                    for (final event in store.timelineForReport(report.id))
                      _TimelineRow(event: event),
                  ],
                ),
              ),
              if (_canReview(report, store)) ...[
                const SectionTitle('Repair feedback'),
                if (feedback == null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'The Coordinator approved the latest repair.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          key: const ValueKey('review-repair'),
                          onPressed: () => _open(
                            context,
                            ReviewRepairScreen(reportId: report.id),
                          ),
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Review Repair'),
                        ),
                      ],
                    ),
                  )
                else
                  AppCard(
                    child: Text(
                      !feedback.stillNotWorking
                          ? 'Your feedback was submitted.'
                          : feedback.reviewedAt == null
                              ? 'Your feedback is waiting for Coordinator review.'
                              : 'Your feedback was reviewed by ${feedback.reviewedBy ?? 'the Coordinator'}.',
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ClarificationCard extends StatelessWidget {
  const _ClarificationCard({required this.message});

  final ClarificationMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.fromCoordinator ? 'Coordinator' : 'You',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              message.sentAt == null
                  ? 'Earlier note'
                  : _stamp(context, message.sentAt!),
              style: const TextStyle(fontSize: 12, color: TarumtColors.muted),
            ),
            const SizedBox(height: 8),
            Text(message.text),
            if (message.photo != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  message.photo!,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});

  final ReportTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 10, color: TarumtColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (event.at != null)
                  Text(
                    _stamp(context, event.at!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: TarumtColors.muted,
                    ),
                  ),
                const SizedBox(height: 3),
                Text(event.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _stamp(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true);
  return '${formatDate(local)} · $time';
}
