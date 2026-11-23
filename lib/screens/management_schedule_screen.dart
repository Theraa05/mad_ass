import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/work_order.dart';
import '../services/auth_service.dart';
import '../services/repair_scheduler.dart';
import '../services/report_store.dart';
import '../widgets/common.dart';
import 'adjust_schedule_screen.dart';
import 'assign_technician_screen.dart';

class ManagementScheduleScreen extends StatefulWidget {
  final DateTime? initialDate;

  const ManagementScheduleScreen({
    super.key,
    this.initialDate,
  });

  @override
  State<ManagementScheduleScreen> createState() =>
      _ManagementScheduleScreenState();
}

class _ManagementScheduleScreenState
    extends State<ManagementScheduleScreen> {
  final _store = ReportStore.instance;

  DateTime _date = RepairScheduler.day(DateTime.now());
  String _technicianId = '';
  bool _openingOrder = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialDate != null) {
      _date = RepairScheduler.day(widget.initialDate!);
      return;
    }

    final today = _date;

    final dates = [
      for (final order in _store.workOrders)
        if (order.isOpen)
          for (final block in order.blocks)
            if (!RepairScheduler.day(block.start)
                .isBefore(today))
              RepairScheduler.day(block.start),
    ]..sort();

    if (dates.isNotEmpty) {
      _date = dates.first;
    }
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 5),
      lastDate: DateTime(
        _date.year + 5,
        12,
        31,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _date = RepairScheduler.day(selected);
      });
    }
  }

  void _changeDay(int offset) {
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day + offset,
      );
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  Future<void> _openOrder(WorkOrder order) async {
    if (_openingOrder) {
      return;
    }

    final report = _store.byId(order.reportId);

    if (!order.isPreventive &&
        (report == null ||
            report.workOrderId != order.id)) {
      _message(
        'The linked report or work order is unavailable.',
      );
      return;
    }

    setState(() {
      _openingOrder = true;
    });

    try {
      final task = order.preventiveTask;

      if (task != null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(
                '${order.id} · Preventive',
              ),
              content: SingleChildScrollView(
                child: Text(
                  '${task.equipmentId}\n'
                      '${task.category}\n'
                      '${task.location}\n\n'
                      'Task: ${task.task}\n\n'
                      'Technician: '
                      '${_store.technicianById(order.technicianId)?.name ?? order.technicianId}\n'
                      'Status: ${_workStatus(order.status)}\n'
                      '${order.blocks.map((block) => blockLabel(context, block)).join('\n')}',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            settings: RouteSettings(
              arguments: order.reportId,
            ),
            builder: (_) =>
            const AssignTechnicianScreen(),
          ),
        );
      }
    } catch (error, stack) {
      debugPrint(
        'Opening work order failed: $error\n$stack',
      );

      if (mounted) {
        _message(
          'Unable to open work order: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingOrder = false;
        });
      }
    }
  }

  Future<void> _adjustOrder(WorkOrder order) async {
    if (_openingOrder) {
      return;
    }

    setState(() {
      _openingOrder = true;
    });

    try {
      final newStart =
      await Navigator.of(context).push<DateTime>(
        MaterialPageRoute<DateTime>(
          builder: (_) => AdjustScheduleScreen(
            workOrderId: order.id,
          ),
        ),
      );

      if (newStart != null && mounted) {
        setState(() {
          _date = RepairScheduler.day(newStart);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingOrder = false;
        });
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
          if (AuthService.current?.role !=
              UserRole.management) {
            return const Center(
              child: Text(
                'Coordinator access is required.',
              ),
            );
          }

          final orders = _store.workOrders.where((order) {
            return _technicianId.isEmpty ||
                order.technicianId == _technicianId;
          }).toList();

          final entries = <_ScheduleEntry>[
            for (final order in orders)
              for (var index = 0;
              index < order.blocks.length;
              index++)
                if (RepairScheduler.day(
                  order.blocks[index].start,
                ) ==
                    _date)
                  _ScheduleEntry(
                    order,
                    order.blocks[index],
                    index + 1,
                  ),
          ];

          entries.sort((a, b) {
            final time = a.block.start.compareTo(
              b.block.start,
            );

            if (time != 0) {
              return time;
            }

            final technician =
            a.order.technicianId.compareTo(
              b.order.technicianId,
            );

            return technician != 0
                ? technician
                : a.order.id.compareTo(b.order.id);
          });

          final nextDates = {
            for (final order in orders)
              for (final block in order.blocks)
                if (RepairScheduler.day(block.start)
                    .isAfter(_date))
                  RepairScheduler.day(block.start),
          }.toList()
            ..sort();

          final DateTime? nextDate =
          nextDates.isEmpty
              ? null
              : nextDates.first;

          final jobCount = entries
              .map((entry) => entry.order.id)
              .toSet()
              .length;

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
                  const AppCard(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirmed maintenance timetable',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'New assignment batches use '
                              'High → Medium → Low, then FIFO '
                              'within the same priority. '
                              'Confirmed jobs appear in time order.',
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Different technicians can work '
                              'at the same time.',
                        ),
                      ],
                    ),
                  ),

                  const SectionTitle('Choose date'),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment:
                    WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        onPressed: () {
                          _changeDay(-1);
                        },
                        icon: const Icon(
                          Icons.chevron_left,
                        ),
                      ),

                      OutlinedButton.icon(
                        onPressed: _chooseDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                        ),
                        label: Text(
                          formatDate(_date),
                        ),
                      ),

                      IconButton(
                        tooltip: 'Next day',
                        onPressed: () {
                          _changeDay(1);
                        },
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            _date = RepairScheduler.day(
                              DateTime.now(),
                            );
                          });
                        },
                        child: const Text('Today'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _technicianId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Technician',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                          'All technicians',
                        ),
                      ),
                      for (final technician
                      in campusTechnicians)
                        DropdownMenuItem<String>(
                          value: technician.id,
                          child: Text(
                            technician.name,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _technicianId = value ?? '';
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  Text(
                    '$jobCount jobs · '
                        '${entries.length} time blocks',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (entries.isEmpty)
                    AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No confirmed jobs for this '
                                'date and technician.',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Confirm a repair assignment or '
                                'create a planned maintenance job '
                                'to add a booking here.',
                          ),

                          if (nextDate != null) ...[
                            const SizedBox(height: 12),

                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _date = nextDate;
                                });
                              },
                              icon: const Icon(
                                Icons.event_available_outlined,
                              ),
                              label: Text(
                                'Next booked day: '
                                    '${formatDate(nextDate)}',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  for (final entry in entries)
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
                              blockLabel(
                                context,
                                entry.block,
                              ),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              '${entry.order.id} · '
                                  '${entry.order.isPreventive ? 'Preventive' : entry.order.reportId}',
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),

                            Text(
                              'Technician: '
                                  '${_store.technicianById(entry.order.technicianId)?.name ?? entry.order.technicianId}',
                            ),

                            Text(
                              entry.order.preventiveTask
                                  ?.category ??
                                  _store
                                      .byId(entry.order.reportId)
                                      ?.category ??
                                  '',
                            ),

                            Text(
                              entry.order.preventiveTask
                                  ?.location ??
                                  _store
                                      .byId(entry.order.reportId)
                                      ?.location ??
                                  'Location unavailable',
                            ),

                            Text(
                              'Priority: '
                                  '${entry.order.priority.label}',
                            ),

                            Text(
                              'Status: '
                                  '${_workStatus(entry.order.status)}',
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'This slot: '
                                  '${entry.block.minutes} min · '
                                  'Total estimate: '
                                  '${entry.order.estimatedMinutes} min',
                            ),

                            if (entry.order.blocks.length > 1)
                              Text(
                                'Part ${entry.part} of '
                                    '${entry.order.blocks.length}',
                              ),

                            const SizedBox(height: 12),

                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _openingOrder
                                      ? null
                                      : () {
                                    _openOrder(
                                      entry.order,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.assignment_outlined,
                                  ),
                                  label: const Text(
                                    'View Work Order',
                                  ),
                                ),

                                if (entry.order.status ==
                                    WorkOrderStatus.assigned) ...[
                                  const SizedBox(height: 8),

                                  OutlinedButton.icon(
                                    onPressed: _openingOrder
                                        ? null
                                        : () {
                                      _adjustOrder(
                                        entry.order,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.edit_calendar_outlined,
                                    ),
                                    label: const Text(
                                      'Adjust Time',
                                    ),
                                  ),
                                ],
                              ],
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

class _ScheduleEntry {
  final WorkOrder order;
  final RepairBlock block;
  final int part;

  const _ScheduleEntry(
      this.order,
      this.block,
      this.part,
      );
}

String _workStatus(WorkOrderStatus status) {
  return switch (status) {
    WorkOrderStatus.assigned => 'Assigned',
    WorkOrderStatus.inProgress => 'In progress',
    WorkOrderStatus.onHold => 'On hold',
    WorkOrderStatus.pendingVerification =>
    'Pending verification',
    WorkOrderStatus.returnedForRework =>
    'Returned for rework',
    WorkOrderStatus.resolved => 'Resolved',
  };
}