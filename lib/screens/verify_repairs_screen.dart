import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/work_order.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

String _verificationStamp(
    BuildContext context,
    DateTime date,
    ) {
  final local = date.toLocal();

  final time = MaterialLocalizations.of(context)
      .formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: true,
  );

  return '${formatDate(local)} · $time';
}

class VerifyRepairsScreen extends StatelessWidget {
  const VerifyRepairsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Repairs'),
      ),
      body: ListenableBuilder(
        listenable: ReportStore.instance,
        builder: (context, _) {
          if (AuthService.current?.role !=
              UserRole.management) {
            return const Center(
              child: Text(
                'Coordinator access is required.',
              ),
            );
          }

          final store = ReportStore.instance;
          final pending = store.pendingVerifications;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 850,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  28,
                ),
                children: [
                  Text(
                    '${pending.length} jobs '
                        'awaiting inspection',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Oldest completion submissions '
                        'appear first. Inspect the equipment '
                        'before approving a repair.',
                  ),
                  const SizedBox(height: 16),

                  if (pending.isEmpty)
                    const AppCard(
                      child: Text(
                        'No repairs awaiting verification. '
                            'Jobs appear here after the assigned '
                            'technician submits a repair note '
                            'and completion photo.',
                      ),
                    ),

                  for (final order in pending)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                            Text(
                              order.isPreventive
                                  ? 'Preventive maintenance'
                                  : 'Report: ${order.reportId}',
                            ),
                            Text(
                              order.preventiveTask
                                  ?.location ??
                                  store
                                      .byId(order.reportId)
                                      ?.location ??
                                  'Location unavailable',
                            ),
                            Text(
                              'Technician: '
                                  '${store.technicianById(order.technicianId)?.name ?? order.technicianId}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              order.latestSubmission
                                  ?.repairNote ??
                                  'No completion evidence saved.',
                            ),
                            if (order.latestSubmission != null)
                              Text(
                                'Submitted '
                                    '${_verificationStamp(context, order.latestSubmission!.submittedAt)}',
                              ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context)
                                    .push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) =>
                                        RepairInspectionScreen(
                                          workOrderId: order.id,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.fact_check_outlined,
                              ),
                              label: const Text(
                                'Open Inspection',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RepairInspectionScreen extends StatefulWidget {
  final String workOrderId;

  const RepairInspectionScreen({
    super.key,
    required this.workOrderId,
  });

  @override
  State<RepairInspectionScreen> createState() =>
      _RepairInspectionScreenState();
}

class _RepairInspectionScreenState
    extends State<RepairInspectionScreen> {
  final _store = ReportStore.instance;
  final _note = TextEditingController();

  int? _submissionNumber;

  bool _equipmentChecked = false;
  bool _workingConfirmed = false;
  bool _photoReviewed = false;
  bool _photoReady = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _submissionNumber = _store
        .workOrderById(widget.workOrderId)
        ?.latestSubmission
        ?.number;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _message(Object error) {
    String message = error.toString();

    if (error is StateError) {
      message = error.message;
    } else if (error is ArgumentError) {
      message = error.message.toString();
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _markPhotoReady(
      bool ready,
      int number,
      ) {
    if (_photoReady == ready ||
        number != _submissionNumber) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          number != _submissionNumber ||
          _photoReady == ready) {
        return;
      }

      setState(() {
        _photoReady = ready;

        if (!ready) {
          _photoReviewed = false;
        }
      });
    });
  }

  void _decide(InspectionDecision decision) {
    if (_saving) {
      return;
    }

    final order = _store.workOrderById(
      widget.workOrderId,
    );

    if (_submissionNumber == null ||
        order?.latestSubmission?.number !=
            _submissionNumber) {
      _message(
        'Completion evidence changed. '
            'Reopen this inspection.',
      );
      return;
    }

    if (_note.text.trim().isEmpty) {
      _message(
        'Enter your inspection findings '
            'or the reason for rework.',
      );
      return;
    }

    if (decision == InspectionDecision.approved &&
        !_photoReady) {
      _message(
        'The completion photo must load '
            'before approval.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      _store.verifyRepair(
        workOrderId: widget.workOrderId,
        expectedSubmissionNumber: _submissionNumber!,
        decision: decision,
        inspectionNote: _note.text,
        correctEquipmentChecked: _equipmentChecked,
        workingTestPassed: _workingConfirmed,
        photoReviewed: _photoReviewed,
      );

      _message(
        decision == InspectionDecision.approved
            ? '${widget.workOrderId} approved as Resolved.'
            : '${widget.workOrderId} returned for rework.',
      );

      Navigator.pop(context, true);
    } on StateError catch (error) {
      _message(error);
    } on ArgumentError catch (error) {
      _message(error);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspect Repair'),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (AuthService.current?.role !=
              UserRole.management) {
            return const Center(
              child: Text(
                'Coordinator access is required.',
              ),
            );
          }

          final order = _store.workOrderById(
            widget.workOrderId,
          );

          final submission = order?.latestSubmission;

          if (order == null || submission == null) {
            return const Center(
              child: Text(
                'No submitted completion evidence '
                    'is available.',
              ),
            );
          }

          final report = _store.byId(order.reportId);

          final pending = order.status ==
              WorkOrderStatus.pendingVerification;

          final current =
              submission.number == _submissionNumber;

          final editable =
              pending && current && !_saving;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 850,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  28,
                ),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          order.isPreventive
                              ? 'Preventive maintenance'
                              : 'Linked report: ${order.reportId}',
                        ),
                        Text(
                          order.preventiveTask
                              ?.equipmentId ??
                              report?.equipmentId ??
                              'Equipment not specified',
                        ),
                        Text(
                          order.preventiveTask
                              ?.location ??
                              report?.location ??
                              'Location unavailable',
                        ),
                        Text(
                          'Technician: '
                              '${_store.technicianById(order.technicianId)?.name ?? order.technicianId}',
                        ),
                        Text(
                          'Completion submission '
                              '${submission.number}',
                        ),
                        Text(
                          _verificationStamp(
                            context,
                            submission.submittedAt,
                          ),
                        ),
                        Text(
                          'Submitted by: '
                              '${submission.submittedBy}',
                        ),
                      ],
                    ),
                  ),

                  if (!current) ...[
                    const SizedBox(height: 12),
                    const AppCard(
                      child: Text(
                        'New completion evidence arrived. '
                            'Go back and reopen this inspection.',
                      ),
                    ),
                  ],

                  if (!pending) ...[
                    const SizedBox(height: 12),
                    const AppCard(
                      child: Text(
                        'This job is no longer '
                            'awaiting verification.',
                      ),
                    ),
                  ],

                  const SectionTitle(
                    'Work requested',
                  ),

                  AppCard(
                    child: Text(
                      order.preventiveTask?.task ??
                          report?.description ??
                          'Details unavailable.',
                    ),
                  ),

                  const SectionTitle(
                    'Technician repair note',
                  ),

                  AppCard(
                    child: Text(
                      submission.repairNote,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    submission.equipmentTested
                        ? 'Technician confirmed: equipment tested.'
                        : 'Technician has not confirmed equipment testing.',
                  ),

                  const SectionTitle(
                    'Completion photo',
                  ),

                  AppCard(
                    child: Image.memory(
                      submission.completionPhoto,
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      cacheWidth: 1000,
                      frameBuilder: (
                          context,
                          child,
                          frame,
                          synchronous,
                          ) {
                        if (frame != null) {
                          _markPhotoReady(
                            true,
                            submission.number,
                          );

                          return child;
                        }

                        return const SizedBox(
                          height: 230,
                          child: Center(
                            child:
                            CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (
                          context,
                          error,
                          stack,
                          ) {
                        _markPhotoReady(
                          false,
                          submission.number,
                        );

                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'The completion photo could '
                                'not be displayed. Return '
                                'the job for rework and '
                                'request a valid photo.',
                          ),
                        );
                      },
                    ),
                  ),

                  if (pending && current) ...[
                    const SectionTitle(
                      'Coordinator inspection',
                    ),

                    AppCard(
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding:
                            EdgeInsets.zero,
                            value: _equipmentChecked,
                            title: const Text(
                              'I checked the equipment '
                                  'ID and location.',
                            ),
                            onChanged: editable
                                ? (value) {
                              setState(() {
                                _equipmentChecked =
                                    value ?? false;
                              });
                            }
                                : null,
                          ),

                          CheckboxListTile(
                            contentPadding:
                            EdgeInsets.zero,
                            value: _workingConfirmed,
                            title: const Text(
                              'I tested the repair '
                                  'and confirmed it works.',
                            ),
                            onChanged: editable
                                ? (value) {
                              setState(() {
                                _workingConfirmed =
                                    value ?? false;
                              });
                            }
                                : null,
                          ),

                          CheckboxListTile(
                            contentPadding:
                            EdgeInsets.zero,
                            value: _photoReviewed,
                            title: const Text(
                              'I reviewed the '
                                  'completion photo.',
                            ),
                            onChanged:
                            editable && _photoReady
                                ? (value) {
                              setState(() {
                                _photoReviewed =
                                    value ??
                                        false;
                              });
                            }
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _note,
                      readOnly: _saving,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText:
                        'Inspection note / rework reason *',
                        hintText:
                        'Cooling confirmed on site, '
                            'or explain what still needs repair.',
                      ),
                    ),

                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () {
                        _decide(
                          InspectionDecision.approved,
                        );
                      },
                      icon: const Icon(
                        Icons.verified_outlined,
                      ),
                      label: const Text(
                        'Approve as Resolved',
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                        TarumtColors.accent,
                        side: const BorderSide(
                          color: TarumtColors.accent,
                        ),
                      ),
                      onPressed: _saving
                          ? null
                          : () {
                        _decide(
                          InspectionDecision
                              .reworkRequired,
                        );
                      },
                      icon: const Icon(
                        Icons.build_circle_outlined,
                      ),
                      label: const Text(
                        'Return for Rework',
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Approval requires all three checks. '
                          'For rework, enter the reason; '
                          'failed checks can stay unticked.',
                    ),
                  ],

                  if (order.inspections.isNotEmpty) ...[
                    const SectionTitle(
                      'Inspection history',
                    ),

                    for (final inspection
                    in order.inspections)
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
                                'Submission '
                                    '${inspection.submissionNumber} · '
                                    '${inspection.decision == InspectionDecision.approved ? 'Approved' : 'Returned for rework'}',
                                style: const TextStyle(
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${inspection.inspectedBy}\n'
                                    '${_verificationStamp(context, inspection.inspectedAt)}',
                              ),
                              const SizedBox(height: 8),
                              Text(inspection.note),
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
    );
  }
}