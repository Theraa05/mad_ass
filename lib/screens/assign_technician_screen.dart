import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/work_order.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../services/repair_scheduler.dart';
import '../widgets/common.dart';

String scheduleTime(BuildContext context, DateTime time) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(time),
    alwaysUse24HourFormat: true,
  );
}

String blockLabel(BuildContext context, RepairBlock block) {
  return '${formatDate(block.start)} · '
      '${scheduleTime(context, block.start)}–'
      '${scheduleTime(context, block.end)}';
}

// ============================================================
// Assign Technician
// ============================================================

class AssignTechnicianScreen extends StatefulWidget {
  const AssignTechnicianScreen({super.key});

  @override
  State<AssignTechnicianScreen> createState() =>
      _AssignTechnicianScreenState();
}

class _AssignTechnicianScreenState
    extends State<AssignTechnicianScreen> {
  final _store = ReportStore.instance;
  final Set<String> _selected = {};

  String? _reportId;
  String? _technicianId;

  DateTime _date = RepairScheduler.day(DateTime.now());

  bool _loaded = false;
  bool _previewing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loaded) {
      return;
    }

    _loaded = true;

    final argument = ModalRoute.of(context)?.settings.arguments;

    if (argument is String) {
      _reportId = argument;
      _selected.add(argument);
    }
  }

  void _error(Object error) {
    String message = error.toString();

    if (error is StateError) {
      message = error.message;
    } else if (error is ArgumentError) {
      message = error.message?.toString() ?? error.toString();
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _chooseDate() async {
    final today = RepairScheduler.day(DateTime.now());

    final chosen = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(
        today.year,
        today.month,
        today.day + 30,
      ),
    );

    if (chosen != null && mounted) {
      setState(() {
        _date = chosen;
      });
    }
  }

  Future<void> _preview() async {
    if (_previewing) {
      return;
    }

    if (_technicianId == null) {
      _error(
        StateError(
          'Select a technician by tapping their card first.',
        ),
      );
      return;
    }

    if (_selected.isEmpty) {
      _error(
        StateError('Select at least one reviewed request.'),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _previewing = true;
    });

    try {
      final plan = _store.previewAssignments(
        technicianId: _technicianId!,
        reportIds: Set<String>.of(_selected),
        fromDate: _date,
      );

      final created =
      await Navigator.of(context).push<List<WorkOrder>>(
        MaterialPageRoute<List<WorkOrder>>(
          settings: RouteSettings(
            name: AppRoutes.repairSchedule,
            arguments: plan,
          ),
          builder: (_) => const RepairScheduleScreen(),
        ),
      );

      if (created != null &&
          created.isNotEmpty &&
          mounted) {
        Navigator.pop(context, true);
      }
    } catch (error, stack) {
      debugPrint(
        'Preview Schedule failed: $error\n$stack',
      );

      if (mounted) {
        _error(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _previewing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Technician'),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (AuthService.current?.role != UserRole.management) {
            return const Center(
              child: Text('Coordinator access is required.'),
            );
          }

          final report = _store.byId(_reportId ?? '');

          if (report == null) {
            return const Center(
              child: Text('Report not found.'),
            );
          }

          final existing = _store.workOrderById(
            report.workOrderId ?? '',
          );

          // Display an existing assignment.
          if (existing != null) {
            final technician = _store.technicianById(
              existing.technicianId,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        existing.id,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Linked report: ${existing.reportId}',
                      ),
                      Text(
                        'Technician: '
                            '${technician?.name ?? existing.technicianId}',
                      ),
                      Text(
                        'Location: ${report.location}',
                      ),
                      Text(
                        'Priority: ${existing.priority.label}',
                      ),
                      Text(
                        'Estimated repair: '
                            '${existing.estimatedMinutes} minutes',
                      ),
                      const Divider(),
                      for (final block in existing.blocks)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8,
                          ),
                          child: Text(
                            blockLabel(context, block),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (report.status != ReportStatus.underReview ||
              report.reviewedAt == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Save the review and finish clarification first.',
                ),
              ),
            );
          }

          final matches = campusTechnicians
              .where(
                (technician) =>
                technician.supports(report.category),
          )
              .toList();

          matches.sort((a, b) {
            final workload = _store
                .openJobs(a.id)
                .compareTo(_store.openJobs(b.id));

            return workload != 0
                ? workload
                : a.name.compareTo(b.name);
          });

          final technician = _store.technicianById(
            _technicianId ?? '',
          );

          final ready = technician == null
              ? <Report>[]
              : _store.readyForTechnician(technician);

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
                          report.id,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${report.category} · ${report.location}',
                        ),
                        Text(
                          'Priority: '
                              '${report.coordinatorPriority?.label}',
                        ),
                        Text(
                          'Estimated repair: '
                              '${report.estimatedMinutes} minutes',
                        ),
                      ],
                    ),
                  ),

                  const SectionTitle('Select Technician'),

                  if (matches.isEmpty)
                    const AppCard(
                      child: Text(
                        'No matching technician is available.',
                      ),
                    ),

                  for (var index = 0;
                  index < matches.length;
                  index++)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: AppCard(
                        onTap: () {
                          final selectedTechnician =
                          matches[index];

                          setState(() {
                            _technicianId =
                                selectedTechnician.id;

                            final validIds = _store
                                .readyForTechnician(
                              selectedTechnician,
                            )
                                .map((item) => item.id)
                                .toSet();

                            _selected.removeWhere(
                                  (id) => !validIds.contains(id),
                            );

                            _selected.add(report.id);
                          });
                        },
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _technicianId == matches[index].id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    matches[index].name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                      FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${_store.openJobs(matches[index].id)} '
                                        'open jobs',
                                  ),
                                  Text(
                                    'Specialty: '
                                        '${matches[index].specialties.join(', ')}',
                                  ),
                                  if (index == 0)
                                    const Text(
                                      'Suggested — lowest open workload',
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SectionTitle('Schedule from'),

                  OutlinedButton.icon(
                    onPressed: _previewing
                        ? null
                        : _chooseDate,
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                    ),
                    label: Text(formatDate(_date)),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Weekdays 09:00–17:00; lunch 13:00–14:00. '
                        'Busy or longer jobs can continue on the '
                        'next working day.',
                  ),

                  if (technician != null) ...[
                    const SectionTitle(
                      'Requests to schedule',
                    ),
                    const Text(
                      'The current request is included. '
                          'You can add other reviewed requests '
                          'handled by this technician.',
                    ),
                    const SizedBox(height: 8),

                    for (final item in ready)
                      CheckboxListTile(
                        value: _selected.contains(item.id),
                        title: Text(
                          '${item.id} · ${item.category}',
                        ),
                        subtitle: Text(
                          '${item.coordinatorPriority!.label} priority · '
                              '${item.estimatedMinutes} min · '
                              'Submitted ${item.dateLabel}',
                        ),
                        controlAffinity:
                        ListTileControlAffinity.leading,
                        onChanged: item.id == report.id
                            ? null
                            : (selected) {
                          setState(() {
                            if (selected == true) {
                              _selected.add(item.id);
                            } else {
                              _selected.remove(item.id);
                            }
                          });
                        },
                      ),
                  ],

                  const SizedBox(height: 22),

                  FilledButton.icon(
                    key: const ValueKey(
                      'preview-schedule',
                    ),
                    onPressed: _previewing
                        ? null
                        : _preview,
                    icon: const Icon(
                      Icons.schedule_rounded,
                    ),
                    label: Text(
                      _previewing
                          ? 'Opening timetable…'
                          : 'Preview Schedule',
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

// ============================================================
// Repair Schedule Preview
// ============================================================

class RepairScheduleScreen extends StatefulWidget {
  const RepairScheduleScreen({super.key});

  @override
  State<RepairScheduleScreen> createState() =>
      _RepairScheduleScreenState();
}

class _RepairScheduleScreenState
    extends State<RepairScheduleScreen> {
  final _store = ReportStore.instance;

  AssignmentPlan? _plan;
  bool _loaded = false;
  bool _confirming = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loaded) {
      return;
    }

    _loaded = true;

    final argument = ModalRoute.of(context)?.settings.arguments;

    if (argument is AssignmentPlan) {
      _plan = argument;
    }
  }

  void _error(StateError error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error.message)),
      );
  }

  void _refresh() {
    final current = _plan;

    if (current == null) {
      return;
    }

    try {
      final next = _store.previewAssignments(
        technicianId: current.technicianId,
        reportIds: current.assignments
            .map((assignment) => assignment.reportId)
            .toSet(),
        fromDate: current.fromDate,
      );

      setState(() {
        _plan = next;
      });
    } on StateError catch (error) {
      _error(error);
    }
  }

  Future<void> _confirm() async {
    if (_confirming || _plan == null) {
      return;
    }

    setState(() {
      _confirming = true;
    });

    try {
      final created = _store.confirmAssignments(_plan!);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Assignment confirmed',
            ),
            content: Text(
              created
                  .map(
                    (order) =>
                '${order.id} created · '
                    '${order.reportId} Assigned',
              )
                  .join('\n'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context, created);
      }
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _confirming = false;
        });

        _error(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Schedule'),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (AuthService.current?.role != UserRole.management) {
            return const Center(
              child: Text('Coordinator access is required.'),
            );
          }

          final plan = _plan;

          if (plan == null ||
              plan.assignments.isEmpty ||
              plan.assignments.any(
                    (assignment) => assignment.blocks.isEmpty,
              )) {
            return const Center(
              child: Text('Schedule preview not found.'),
            );
          }

          final technician = _store.technicianById(
            plan.technicianId,
          );

          if (technician == null) {
            return const Center(
              child: Text('Technician not found.'),
            );
          }

          final now = DateTime.now();

          final expired = plan.assignments.any(
                (assignment) => assignment.blocks.any(
                  (block) => block.start.isBefore(now),
            ),
          );

          final stale =
              plan.revision != _store.assignmentRevision ||
                  expired;

          final newRows = [
            for (final assignment in plan.assignments)
              for (var index = 0;
              index < assignment.blocks.length;
              index++)
                (
                block: assignment.blocks[index],
                reportId: assignment.reportId,
                label:
                '${assignment.reportId} · '
                    '${assignment.priority.label} priority'
                    '${assignment.blocks.length > 1 ? ' · Part ${index + 1}/${assignment.blocks.length}' : ''}',
                confirmed: false,
                ),
          ];

          newRows.sort(
                (a, b) => a.block.start.compareTo(b.block.start),
          );

          final firstDay = RepairScheduler.day(
            newRows.first.block.start,
          );

          final lastDay = RepairScheduler.day(
            newRows.last.block.end,
          );

          final selectedReportIds = plan.assignments
              .map((assignment) => assignment.reportId)
              .toSet();

          final rows = [
            ...newRows,

            for (final order
            in _store.ordersForTechnician(plan.technicianId))
              if (order.isOpen &&
                  !selectedReportIds.contains(order.reportId))
                for (final block in order.blocks)
                  if (!RepairScheduler.day(
                    block.start,
                  ).isBefore(firstDay) &&
                      !RepairScheduler.day(
                        block.start,
                      ).isAfter(lastDay))
                    (
                    block: block,
                    reportId: order.reportId,
                    label:
                    '${order.id} · '
                        '${order.isPreventive ? 'Preventive maintenance' : 'Confirmed repair'}\n'
                        '${order.preventiveTask?.location ?? _store.byId(order.reportId)?.location ?? 'Location unavailable'}',
                    confirmed: true,
                    ),
          ];

          rows.sort(
                (a, b) => a.block.start.compareTo(b.block.start),
          );

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
                          technician.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${plan.assignments.length} '
                              'requests to assign',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'High → Medium → Low. '
                              'Equal priority uses submission time (FIFO).',
                        ),
                        const Text(
                          'Confirmed bookings stay reserved.',
                        ),
                      ],
                    ),
                  ),

                  if (stale && !_confirming) ...[
                    const SizedBox(height: 12),
                    const AppCard(
                      child: Text(
                        'This preview changed or expired. '
                            'Refresh before confirming.',
                      ),
                    ),
                  ],

                  const SectionTitle(
                    'Proposed timetable',
                  ),

                  for (final row in rows)
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
                              blockLabel(context, row.block),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(row.label),
                            Text(
                              _store.byId(row.reportId)?.location ??
                                  '',
                            ),
                            Text(
                              '${row.block.minutes} working minutes'
                                  '${row.confirmed ? '' : ' · New slot'}',
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _confirming
                        ? null
                        : _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Refresh Preview',
                    ),
                  ),

                  const SizedBox(height: 12),

                  FilledButton.icon(
                    onPressed: stale || _confirming
                        ? null
                        : _confirm,
                    icon: const Icon(
                      Icons.check_circle_outline,
                    ),
                    label: const Text(
                      'Confirm Schedule & Assign',
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