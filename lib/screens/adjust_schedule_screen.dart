import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/work_order.dart';
import '../services/auth_service.dart';
import '../services/repair_scheduler.dart';
import '../services/report_store.dart';
import '../widgets/common.dart';
import 'assign_technician_screen.dart';

class AdjustScheduleScreen extends StatefulWidget {
  final String workOrderId;

  const AdjustScheduleScreen({
    super.key,
    required this.workOrderId,
  });

  @override
  State<AdjustScheduleScreen> createState() =>
      _AdjustScheduleScreenState();
}

class _AdjustScheduleScreenState
    extends State<AdjustScheduleScreen> {
  final _store = ReportStore.instance;
  final _reason = TextEditingController();

  late DateTime _date;

  int _minute = 9 * 60;
  ReschedulePlan? _plan;
  bool _saving = false;

  final _starts = [
    for (var minute = 9 * 60;
    minute < 13 * 60;
    minute += 15)
      minute,
    for (var minute = 14 * 60;
    minute < 17 * 60;
    minute += 15)
      minute,
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _date = _weekday(
      DateTime(
        now.year,
        now.month,
        now.day + 1,
      ),
    );

    final order = _store.workOrderById(
      widget.workOrderId,
    );

    if (order != null &&
        order.blocks.isNotEmpty &&
        order.blocks.first.start.isAfter(now)) {
      final first = order.blocks.first.start.toLocal();

      _date = RepairScheduler.day(first);

      final minute = first.hour * 60 + first.minute;

      if (_starts.contains(minute)) {
        _minute = minute;
      }
    }
  }

  DateTime _weekday(DateTime date) {
    var result = date;

    while (result.weekday > DateTime.friday) {
      result = DateTime(
        result.year,
        result.month,
        result.day + 1,
      );
    }

    return result;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _message(Object error) {
    String text = error.toString();

    if (error is StateError) {
      text = error.message;
    } else if (error is ArgumentError) {
      text = error.message.toString();
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  String _clock(int minute) {
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(
      TimeOfDay(
        hour: minute ~/ 60,
        minute: minute % 60,
      ),
      alwaysUse24HourFormat: true,
    );
  }

  Future<void> _chooseDate() async {
    final today = RepairScheduler.day(
      DateTime.now(),
    );

    final selected = await showDatePicker(
      context: context,
      initialDate: _weekday(
        _date.isBefore(today) ? today : _date,
      ),
      firstDate: today,
      lastDate: DateTime(
        today.year,
        today.month,
        today.day + 365,
      ),
      selectableDayPredicate: (day) {
        return day.weekday <= DateTime.friday;
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _date = selected;
        _plan = null;
      });
    }
  }

  void _preview() {
    setState(() {
      _plan = null;
    });

    try {
      final next = _store.previewReschedule(
        workOrderId: widget.workOrderId,
        start: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _minute ~/ 60,
          _minute % 60,
        ),
      );

      setState(() {
        _plan = next;
      });
    } on StateError catch (error) {
      _message(error);
    } on ArgumentError catch (error) {
      _message(error);
    }
  }

  void _confirm() {
    if (_saving) {
      return;
    }

    final plan = _plan;

    if (plan == null) {
      _message('Preview the new time first.');
      return;
    }

    if (_reason.text.trim().isEmpty) {
      _message(
        'Enter the reason for changing the schedule.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      _store.confirmReschedule(
        plan,
        reason: _reason.text,
      );

      _message(
        '${widget.workOrderId} rescheduled.',
      );

      Navigator.pop(
        context,
        plan.blocks.first.start,
      );
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
        title: const Text('Adjust Time'),
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

          if (order == null || order.blocks.isEmpty) {
            return const Center(
              child: Text(
                'No booked work order found.',
              ),
            );
          }

          final report = _store.byId(
            order.reportId,
          );

          final plan = _plan;

          final editable =
              order.status == WorkOrderStatus.assigned;

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
                          order.preventiveTask?.location ??
                              report?.location ??
                              'Location unavailable',
                        ),
                        Text(
                          'Technician: '
                              '${_store.technicianById(order.technicianId)?.name ?? order.technicianId}',
                        ),
                        Text(
                          'Duration: '
                              '${order.estimatedMinutes} working minutes',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Adjust Time is available before '
                              'work starts. Other confirmed '
                              'jobs stay reserved.',
                        ),
                      ],
                    ),
                  ),

                  const SectionTitle(
                    'Current time blocks',
                  ),

                  for (final block in order.blocks)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: AppCard(
                        child: Text(
                          blockLabel(context, block),
                        ),
                      ),
                    ),

                  if (editable) ...[
                    const SectionTitle(
                      'Choose new start',
                    ),

                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : _chooseDate,
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      label: Text(
                        formatDate(_date),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      initialValue: _minute,
                      decoration: const InputDecoration(
                        labelText: 'New start time',
                      ),
                      items: [
                        for (final minute in _starts)
                          DropdownMenuItem<int>(
                            value: minute,
                            child: Text(
                              _clock(minute),
                            ),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _minute = value;
                          _plan = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : _preview,
                      icon: const Icon(
                        Icons.preview_outlined,
                      ),
                      label: const Text(
                        'Preview New Time',
                      ),
                    ),

                    if (plan != null) ...[
                      const SectionTitle(
                        'Proposed time blocks',
                      ),

                      for (final block in plan.blocks)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8,
                          ),
                          child: AppCard(
                            child: Text(
                              blockLabel(
                                context,
                                block,
                              ),
                            ),
                          ),
                        ),

                      if (plan.revision !=
                          _store.assignmentRevision &&
                          !_saving)
                        const AppCard(
                          child: Text(
                            'Bookings changed. '
                                'Preview the new time again.',
                          ),
                        ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _reason,
                        readOnly: _saving,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText:
                          'Reason for changing time *',
                          hintText:
                          'Room is occupied; access '
                              'is available later.',
                        ),
                      ),

                      const SizedBox(height: 16),

                      FilledButton.icon(
                        onPressed: _saving
                            ? null
                            : _confirm,
                        icon: const Icon(
                          Icons.check_circle_outline,
                        ),
                        label: Text(
                          _saving
                              ? 'Saving…'
                              : 'Confirm New Time',
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 16),
                    const AppCard(
                      child: Text(
                        'This job has already started '
                            'or finished. Its schedule is locked.',
                      ),
                    ),
                  ],

                  if (order.scheduleChanges.isNotEmpty) ...[
                    const SectionTitle(
                      'Schedule change history',
                    ),

                    for (final change
                    in order.scheduleChanges)
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
                                '${formatDate(change.changedAt)} · '
                                    '${scheduleTime(context, change.changedAt)}',
                                style: const TextStyle(
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Changed by: '
                                    '${change.changedBy}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Previous:\n'
                                    '${change.previousBlocks.map((block) => blockLabel(context, block)).join('\n')}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'New:\n'
                                    '${change.newBlocks.map((block) => blockLabel(context, block)).join('\n')}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reason: ${change.reason}',
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
    );
  }
}