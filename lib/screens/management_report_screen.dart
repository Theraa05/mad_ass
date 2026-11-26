import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/report.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';
import 'assign_technician_screen.dart';

class ManagementReportScreen extends StatefulWidget {
  const ManagementReportScreen({super.key});

  @override
  State<ManagementReportScreen> createState() =>
      _ManagementReportScreenState();
}

class _ManagementReportScreenState
    extends State<ManagementReportScreen> {
  final _form = GlobalKey<FormState>();
  final _priority = GlobalKey<FormFieldState<Urgency>>();
  final _minutes = TextEditingController();

  String? _id;
  bool _loaded = false;
  bool _openingAssignment = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loaded) {
      return;
    }

    _loaded = true;

    final argument = ModalRoute.of(context)?.settings.arguments;

    if (argument is String) {
      _id = argument;
    }

    final report = ReportStore.instance.byId(_id ?? '');

    _minutes.text =
        report?.estimatedMinutes?.toString() ?? '30';
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  // Save the coordinator's priority and estimated duration.
  void _saveReview(Report report) {
    final form = _form.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    try {
      ReportStore.instance.saveReview(
        report.id,
        priority: _priority.currentState!.value!,
        estimatedMinutes: int.parse(
          _minutes.text.trim(),
        ),
      );

      _showError('Review saved for ${report.id}.');
    } on StateError catch (error) {
      _showError(error.message);
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
    }
  }

  bool _canAssign(Report report) {
    return report.status == ReportStatus.underReview &&
        report.workOrderId == null &&
        report.reviewedAt != null &&
        report.coordinatorPriority != null &&
        report.estimatedMinutes != null &&
        (_priority.currentState?.value ??
            report.coordinatorPriority) ==
            report.coordinatorPriority &&
        int.tryParse(_minutes.text.trim()) ==
            report.estimatedMinutes;
  }

  // Open the assignment screen directly and preserve the report ID.
  Future<void> _openAssignment(Report report) async {
    if (_openingAssignment) {
      return;
    }

    if (report.workOrderId == null) {
      if (report.status == ReportStatus.needsInfo) {
        _showError(
          'This report is waiting for the reporter’s reply. '
              'Finish clarification before assigning.',
        );
        return;
      }

      if (report.reviewedAt == null ||
          report.coordinatorPriority == null ||
          report.estimatedMinutes == null) {
        _showError(
          'Choose priority and duration, then tap Save Review.',
        );
        return;
      }

      if (report.status != ReportStatus.underReview) {
        _showError(
          'This report cannot be assigned in its current status.',
        );
        return;
      }

      if (!_canAssign(report)) {
        _showError(
          'Your review has unsaved changes. '
              'Tap Save Review first.',
        );
        return;
      }
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _openingAssignment = true;
    });

    try {
      final assigned = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          settings: RouteSettings(
            name: AppRoutes.assignTechnician,
            arguments: report.id,
          ),
          builder: (_) => const AssignTechnicianScreen(),
        ),
      );

      if (assigned == true && mounted) {
        _showError(
          '${report.workOrderId} created for ${report.id}.',
        );
      }
    } catch (error, stack) {
      debugPrint(
        'Opening Assign Technician failed: $error\n$stack',
      );

      if (mounted) {
        _showError(
          'Unable to open assignment: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingAssignment = false;
        });
      }
    }
  }

  Future<void> _requestInformation(Report report) async {
    final request = await showDialog<_QuestionDraft>(
      context: context,
      builder: (_) => const _QuestionDialog(),
    );

    if (request == null || !mounted) {
      return;
    }

    try {
      ReportStore.instance.requestMoreInformation(
        report.id,
        question: request.text,
        requestPhoto: request.photo,
      );

      _showError(
        '${report.id} now needs information. '
            'The question is visible in the reporter’s report details.',
      );
    } on StateError catch (error) {
      _showError(error.message);
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
    }
  }

  void _reviewFeedback(Report report, RepairFeedback feedback) {
    try {
      ReportStore.instance.markRepairFeedbackReviewed(
        report.id,
        workOrderId: feedback.workOrderId,
        submissionNumber: feedback.submissionNumber,
      );
      _showError('Repair feedback marked as reviewed.');
    } on StateError catch (error) {
      _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.current;

    if (user == null || user.role != UserRole.management) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Request'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Coordinator access is required.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.signIn,
                          (_) => false,
                    );
                  },
                  child: const Text('Go to Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Review Request'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ReportStore.instance,
          builder: (context, _) {
            final report = ReportStore.instance.byId(
              _id ?? '',
            );

            if (report == null) {
              return const Center(
                child: Text('Report not found.'),
              );
            }

            final editable = report.workOrderId == null &&
                {
                  ReportStatus.submitted,
                  ReportStatus.underReview,
                  ReportStatus.needsInfo,
                }.contains(report.status);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 850,
                ),
                child: ListView(
                  key: const PageStorageKey(
                    'review-request-scroll',
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    28,
                  ),
                  children: [
                    _ReportOverview(report: report),

                    // Existing work order.
                    if (report.workOrderId != null) ...[
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Work order: ${report.workOrderId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _openingAssignment
                                  ? null
                                  : () => _openAssignment(report),
                              icon: const Icon(
                                Icons.assignment_outlined,
                              ),
                              label: const Text(
                                'View Assigned Work Order',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Waiting for clarification.
                    if (report.status ==
                        ReportStatus.needsInfo) ...[
                      const SizedBox(height: 14),
                      const _ReviewNotice(
                        icon: Icons.question_answer_outlined,
                        text:
                        'Waiting for information from the reporter. '
                            'Saving a review keeps this status.',
                      ),
                    ],

                    // Previously saved review.
                    if (report.reviewedAt != null) ...[
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Saved review',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Coordinator priority: '
                                  '${report.coordinatorPriority?.label ?? 'Not set'}',
                            ),
                            Text(
                              'Estimated repair: '
                                  '${report.estimatedMinutes ?? 0} minutes',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stamp(
                                context,
                                report.reviewedAt!,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: TarumtColors.muted,
                              ),
                            ),
                            if (report.reviewedBy != null)
                              Text(
                                report.reviewedBy!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TarumtColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    if (editable) ...[
                      const SectionTitle(
                        'Coordinator review',
                      ),

                      Form(
                        key: _form,
                        onChanged: () {
                          setState(() {});
                        },
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Repair priority *',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Confirm the priority after checking '
                                    'the issue and its impact.',
                                style: TextStyle(
                                  color: TarumtColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),

                              FormField<Urgency>(
                                key: _priority,
                                initialValue:
                                report.coordinatorPriority,
                                validator: (value) {
                                  if (value == null) {
                                    return 'Select a repair priority.';
                                  }

                                  return null;
                                },
                                builder: (field) {
                                  return Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final priority in [
                                            Urgency.high,
                                            Urgency.medium,
                                            Urgency.low,
                                          ])
                                            ChoiceChip(
                                              key: ValueKey(
                                                'priority-${priority.name}',
                                              ),
                                              label: Text(
                                                priority.label,
                                              ),
                                              selected:
                                              field.value ==
                                                  priority,
                                              selectedColor:
                                              TarumtColors
                                                  .primaryTint,
                                              onSelected: (_) {
                                                field.didChange(
                                                  priority,
                                                );
                                              },
                                            ),
                                        ],
                                      ),

                                      if (field.value != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _priorityDescription(
                                            field.value!,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                            TarumtColors.muted,
                                          ),
                                        ),
                                      ],

                                      if (field.hasError)
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            field.errorText!,
                                            style: TextStyle(
                                              color:
                                              Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 22),

                              TextFormField(
                                key: const ValueKey(
                                  'review-duration',
                                ),
                                controller: _minutes,
                                keyboardType:
                                TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly,
                                ],
                                decoration:
                                const InputDecoration(
                                  labelText:
                                  'Estimated repair duration *',
                                  suffixText: 'minutes',
                                  helperText:
                                  '15–480 minutes, in 15-minute steps',
                                  helperMaxLines: 2,
                                ),
                                validator: (value) {
                                  final minutes = int.tryParse(
                                    value?.trim() ?? '',
                                  );

                                  if (minutes == null) {
                                    return 'Enter the estimated minutes.';
                                  }

                                  return ReportStore
                                      .validateEstimate(minutes);
                                },
                              ),

                              const SizedBox(height: 22),

                              FilledButton.icon(
                                key: const ValueKey(
                                  'save-review',
                                ),
                                onPressed: () {
                                  _saveReview(report);
                                },
                                icon: const Icon(
                                  Icons.save_outlined,
                                ),
                                label: const Text(
                                  'Save Review',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      OutlinedButton.icon(
                        key: const ValueKey(
                          'request-information',
                        ),
                        onPressed: () {
                          _requestInformation(report);
                        },
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                        ),
                        label: const Text(
                          'Request More Information',
                        ),
                      ),

                      const SizedBox(height: 12),

                      FilledButton.icon(
                        key: const ValueKey(
                          'assign-technician',
                        ),
                        onPressed: _openingAssignment
                            ? null
                            : () => _openAssignment(report),
                        icon: const Icon(
                          Icons.engineering_outlined,
                        ),
                        label: Text(
                          _openingAssignment
                              ? 'Opening…'
                              : 'Assign Technician',
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        report.status == ReportStatus.needsInfo
                            ? 'Wait for the reporter’s reply before assigning.'
                            : _canAssign(report)
                            ? 'Ready to select a technician '
                            'and preview the schedule.'
                            : 'Save your current review before assigning.',
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      const _ReviewNotice(
                        icon: Icons.lock_outline_rounded,
                        text:
                        'Assigned, in-progress and resolved requests '
                            'have a read-only initial review.',
                      ),
                    ],

                    const SectionTitle(
                      'Clarification history',
                    ),

                    if (report.clarificationMessages.isEmpty)
                      AppCard(
                        child: Text(
                          report.managerNote
                              ?.trim()
                              .isNotEmpty ==
                              true
                              ? 'Previous maintenance note:\n'
                              '${report.managerNote}'
                              : 'No clarification requests yet.',
                        ),
                      )
                    else
                      for (final message
                      in report.clarificationMessages)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.fromCoordinator
                                      ? 'Coordinator'
                                      : 'Reporter',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.sentAt == null
                                      ? 'Earlier maintenance note'
                                      : _stamp(
                                    context,
                                    message.sentAt!,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: TarumtColors.muted,
                                  ),
                                ),
                                if (message.authorEmail != null)
                                  Text(
                                    message.authorEmail!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TarumtColors.muted,
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Text(message.text),

                                if (message.photo != null) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      message.photo!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],

                                if (message.photoRequested) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Clear equipment photo requested',
                                    style: TextStyle(
                                      color:
                                      TarumtColors.primary,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                    if (report.repairFeedback.isNotEmpty) ...[
                      const SectionTitle('Repair feedback'),
                      for (final feedback in report.repairFeedback)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feedback.stillNotWorking
                                      ? 'Still Not Working'
                                      : 'Yes, It Works',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  feedback.comment.isEmpty
                                      ? 'No comment provided.'
                                      : feedback.comment,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${feedback.submittedBy} · ${_stamp(context, feedback.submittedAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: TarumtColors.muted,
                                  ),
                                ),
                                if (feedback.photo != null) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      feedback.photo!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                if (feedback.isPendingReview)
                                  FilledButton.icon(
                                        key: ValueKey(
                                          'review-feedback-${report.id}',
                                        ),
                                        onPressed: () =>
                                            _reviewFeedback(report, feedback),
                                        icon: const Icon(Icons.done_rounded),
                                        label: const Text('Mark as reviewed'),
                                      )
                                else if (feedback.reviewedAt != null)
                                  Text(
                                        'Reviewed ${_stamp(context, feedback.reviewedAt!)}',
                                        style: const TextStyle(
                                          color: TarumtColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Formatting helpers
// ============================================================

String _priorityDescription(Urgency priority) {
  return switch (priority) {
    Urgency.high =>
    'Safety risk or major disruption to campus activities.',
    Urgency.medium =>
    'Normal use is affected, but a workaround is available.',
    Urgency.low =>
    'Minor fault with limited disruption.',
  };
}

String _stamp(BuildContext context, DateTime value) {
  final local = value.toLocal();

  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: true,
  );

  return '${formatDate(local)} · $time';
}

// ============================================================
// Report overview
// ============================================================

class _ReportOverview extends StatelessWidget {
  final Report report;

  const _ReportOverview({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                report.id,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ReportStatusChip(report.status),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            report.category,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          _DetailRow(
            Icons.location_on_outlined,
            report.location,
          ),

          _DetailRow(
            Icons.qr_code_rounded,
            report.equipmentId.isEmpty
                ? 'Equipment not specified'
                : report.equipmentId,
          ),

          _DetailRow(
            Icons.person_outline_rounded,
            report.reporterEmail,
          ),

          _DetailRow(
            Icons.schedule_rounded,
            'Submitted ${_stamp(context, report.createdAt)}',
          ),

          _DetailRow(
            Icons.flag_outlined,
            'Reporter urgency: ${report.urgency.label}',
          ),

          const Divider(height: 26),

          const Text(
            'Report description',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(report.description),

          const SizedBox(height: 16),

          const Text(
            'Impact on campus',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            report.impact.isEmpty
                ? 'No impact details provided.'
                : report.impact,
          ),

          const SizedBox(height: 16),

          _DetailRow(
            Icons.image_outlined,
            report.hasPhoto
                ? 'Attachment preview unavailable. '
                'Request a clear photo if needed.'
                : 'No photo attached.',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow(
      this.icon,
      this.text,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: TarumtColors.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: TarumtColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReviewNotice({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: TarumtColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Request more information dialog
// ============================================================

class _QuestionDraft {
  final String text;
  final bool photo;

  const _QuestionDraft(
      this.text,
      this.photo,
      );
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog();

  @override
  State<_QuestionDialog> createState() =>
      _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();

  bool _photo = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request More Information'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey(
                    'clarification-question',
                  ),
                  controller: _message,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Question to reporter *',
                    hintText:
                    'Which unit is affected? '
                        'Please provide its equipment label.',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a question for the reporter.';
                    }

                    return null;
                  },
                ),

                CheckboxListTile(
                  key: const ValueKey(
                    'clarification-photo',
                  ),
                  value: _photo,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity:
                  ListTileControlAffinity.leading,
                  title: const Text(
                    'Ask for a photo',
                  ),
                  subtitle: const Text(
                    'Request a clear photo of the equipment or label.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _photo = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey(
            'cancel-clarification',
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),

        FilledButton(
          key: const ValueKey(
            'send-clarification',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(140, 48),
          ),
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(
                context,
                _QuestionDraft(
                  _message.text.trim(),
                  _photo,
                ),
              );
            }
          },
          child: const Text('Send Request'),
        ),
      ],
    );
  }
}