import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/work_order.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/reporter_photo_input.dart';

class ReviewRepairScreen extends StatefulWidget {
  const ReviewRepairScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ReviewRepairScreen> createState() => _ReviewRepairScreenState();
}

class _ReviewRepairScreenState extends State<ReviewRepairScreen> {
  final _comment = TextEditingController();
  RepairFeedbackOutcome _outcome = RepairFeedbackOutcome.works;
  Uint8List? _photo;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (_outcome == RepairFeedbackOutcome.stillNotWorking &&
        _comment.text.trim().isEmpty) {
      _message('Explain what is still not working.');
      return;
    }
    try {
      ReportStore.instance.submitRepairFeedback(
        widget.reportId,
        outcome: _outcome,
        comment: _comment.text,
        photo: _photo,
      );
      if (mounted) {
        _message('Your repair feedback was sent to the Coordinator.');
        Navigator.pop(context);
      }
    } on StateError catch (error) {
      _message(error.message);
    } on ArgumentError catch (error) {
      _message(error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Review Repair'),
      ),
      body: ListenableBuilder(
        listenable: ReportStore.instance,
        builder: (context, _) {
          final store = ReportStore.instance;
          final report = store.byId(widget.reportId);
          final order = report?.workOrderId == null
              ? null
              : store.workOrderById(report!.workOrderId!);
          final submission = order?.latestSubmission;
          final approved =
              order?.inspections.any(
                (inspection) =>
                    inspection.submissionNumber == submission?.number &&
                    inspection.decision == InspectionDecision.approved,
              ) ??
              false;

          if (report == null ||
              order == null ||
              submission == null ||
              !approved) {
            return const Center(
              child: Text('Repair feedback is available after approval.'),
            );
          }
          if (AuthService.current?.email != report.reporterEmail) {
            return const Center(child: Text('Reporter access is required.'));
          }
          RepairFeedback? previous;
          for (final item in report.repairFeedback) {
            if (item.workOrderId == order.id &&
                item.submissionNumber == submission.number) {
              previous = item;
              break;
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              const ScreenTitle('Review Repair'),
              const SizedBox(height: 8),
              Text(
                '${report.id} · ${report.location}',
                style: const TextStyle(color: TarumtColors.muted),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Approved repair',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(submission.repairNote),
                    const SizedBox(height: 6),
                    Text(
                      'Work order ${order.id} · submission #${submission.number}',
                      style: const TextStyle(
                        color: TarumtColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (previous != null)
                AppCard(
                  child: Text(
                    previous.reviewedAt == null
                        ? 'Feedback submitted and waiting for Coordinator review.'
                        : 'Feedback reviewed by ${previous.reviewedBy ?? 'Coordinator'}.',
                  ),
                )
              else ...[
                const Text(
                  'Is the reported issue working properly now?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('review-repair-works'),
                      label: const Text('Yes, It Works'),
                      selected: _outcome == RepairFeedbackOutcome.works,
                      selectedColor: TarumtColors.successTint,
                      onSelected: (_) => setState(
                        () => _outcome = RepairFeedbackOutcome.works,
                      ),
                    ),
                    ChoiceChip(
                      key: const ValueKey('review-repair-still-not-working'),
                      label: const Text('Still Not Working'),
                      selected:
                          _outcome == RepairFeedbackOutcome.stillNotWorking,
                      selectedColor: TarumtColors.accentTint,
                      onSelected: (_) => setState(
                        () => _outcome = RepairFeedbackOutcome.stillNotWorking,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('repair-feedback-comment'),
                  controller: _comment,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: _outcome == RepairFeedbackOutcome.stillNotWorking
                        ? 'What is still not working? *'
                        : 'Comment (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                ReporterPhotoInput(
                  key: const ValueKey('repair-feedback-photo-input'),
                  onChanged: (photo) => _photo = photo,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('submit-repair-feedback'),
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Feedback'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
