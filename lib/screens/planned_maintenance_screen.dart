import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/work_order.dart';
import '../services/auth_service.dart';
import '../services/repair_scheduler.dart';
import '../services/report_store.dart';
import '../widgets/common.dart';
import 'management_schedule_screen.dart';

class PlannedMaintenanceScreen extends StatefulWidget {
  const PlannedMaintenanceScreen({super.key});

  @override
  State<PlannedMaintenanceScreen> createState() =>
      _PlannedMaintenanceScreenState();
}

class _PlannedMaintenanceScreenState
    extends State<PlannedMaintenanceScreen> {
  final _store = ReportStore.instance;
  final _form = GlobalKey<FormState>();
  final _task = TextEditingController();

  String? _sourceId;
  String? _technicianId;

  int _duration = 30;
  int _startMinute = 9 * 60;

  bool _saving = false;
  late DateTime _date;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _date = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );

    while (_date.weekday > DateTime.friday) {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day + 1,
      );
    }
  }

  @override
  void dispose() {
    _task.dispose();
    super.dispose();
  }

  List<int> _starts(int duration) {
    return [
      for (var time = 9 * 60;
      time + duration <= 13 * 60;
      time += 15)
        time,
      for (var time = 14 * 60;
      time + duration <= 17 * 60;
      time += 15)
        time,
    ];
  }

  String _clock(int minutes) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(
        hour: minutes ~/ 60,
        minute: minutes % 60,
      ),
      alwaysUse24HourFormat: true,
    );
  }

  Future<void> _chooseDate() async {
    final today = RepairScheduler.day(DateTime.now());

    var initial = _date.isBefore(today) ? today : _date;

    while (initial.weekday > DateTime.friday) {
      initial = DateTime(
        initial.year,
        initial.month,
        initial.day + 1,
      );
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(
        today.year,
        today.month,
        today.day + 365,
      ),
      selectableDayPredicate: (date) {
        return date.weekday <= DateTime.friday;
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _date = selected;
      });
    }
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

  Future<void> _create() async {
    if (_saving) {
      return;
    }

    if (_sourceId == null) {
      _message('Select equipment first.');
      return;
    }

    if (_task.text.trim().isEmpty) {
      _message(
        'Enter the inspection or servicing task.',
      );
      return;
    }

    if (_technicianId == null) {
      _message('Select a matching technician.');
      return;
    }

    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final order = _store.createPreventiveJob(
        sourceReportId: _sourceId!,
        task: _task.text,
        technicianId: _technicianId!,
        start: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _startMinute ~/ 60,
          _startMinute % 60,
        ),
        estimatedMinutes: _duration,
      );

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Planned job created',
            ),
            content: Text(
              '${order.id} · Preventive maintenance\n'
                  '${order.preventiveTask!.equipmentId}\n'
                  '${order.preventiveTask!.location}\n'
                  'Technician: '
                  '${_store.technicianById(order.technicianId)!.name}\n'
                  '${formatDate(_date)} · '
                  '${_clock(_startMinute)}–'
                  '${_clock(_startMinute + _duration)}\n'
                  'Status: Assigned',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'View Schedule',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => ManagementScheduleScreen(
            initialDate: _date,
          ),
        ),
      );
    } catch (error, stack) {
      debugPrint(
        'Creating planned maintenance failed: '
            '$error\n$stack',
      );

      if (mounted) {
        _message(error);
      }
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
        title: const Text('Planned Maintenance'),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (AuthService.current?.role != UserRole.management) {
            return const Center(
              child: Text('Coordinator access is required.'),
            );
          }

          // Latest reported details for each equipment ID.
          final assets = <String, Report>{};

          for (final report in _store.all) {
            final id = report.equipmentId.trim().toLowerCase();

            if (id.isNotEmpty) {
              assets.putIfAbsent(id, () => report);
            }
          }

          final source = _store.byId(_sourceId);

          final technicians = source == null
              ? <Technician>[]
              : campusTechnicians.where((technician) {
            return technician.supports(source.category);
          }).toList();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 850,
              ),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    28,
                  ),
                  children: [
                    const AppCard(
                      child: Text(
                        'Schedule an inspection or service '
                            'before equipment breaks down. '
                            'Routine preventive jobs use Low priority.',
                      ),
                    ),

                    const SectionTitle('Equipment'),

                    DropdownButtonFormField<String>(
                      initialValue: _sourceId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Equipment from reports *',
                      ),
                      items: [
                        for (final report in assets.values)
                          DropdownMenuItem<String>(
                            value: report.id,
                            child: Text(
                              '${report.equipmentId} · '
                                  '${report.location}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                        setState(() {
                          _sourceId = value;
                          _technicianId = null;
                        });
                      },
                      validator: (value) {
                        return value == null
                            ? 'Select equipment.'
                            : null;
                      },
                    ),

                    if (source != null) ...[
                      const SizedBox(height: 12),
                      AppCard(
                        child: Text(
                          '${source.category}\n'
                              '${source.location}',
                        ),
                      ),
                    ],

                    const SectionTitle(
                      'Maintenance task',
                    ),

                    TextFormField(
                      controller: _task,
                      readOnly: _saving,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Task *',
                        hintText:
                        'Inspect cooling and clean filters.',
                      ),
                      validator: (value) {
                        return value?.trim().isNotEmpty == true
                            ? null
                            : 'Enter the inspection or servicing task.';
                      },
                    ),

                    const SectionTitle('Date and time'),

                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : _chooseDate,
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      label: Text(formatDate(_date)),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      initialValue: _duration,
                      decoration: const InputDecoration(
                        labelText: 'Duration *',
                      ),
                      items: [
                        for (var minutes = 15;
                        minutes <= 240;
                        minutes += 15)
                          DropdownMenuItem<int>(
                            value: minutes,
                            child: Text(
                              '$minutes minutes',
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
                          _duration = value;

                          final options = _starts(value);

                          if (!options.contains(
                            _startMinute,
                          )) {
                            _startMinute = options.first;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      key: ValueKey(
                        'start-$_duration',
                      ),
                      initialValue: _startMinute,
                      decoration: const InputDecoration(
                        labelText: 'Start time *',
                      ),
                      items: [
                        for (final time in _starts(_duration))
                          DropdownMenuItem<int>(
                            value: time,
                            child: Text(
                              _clock(time),
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
                          _startMinute = value;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Ends at '
                          '${_clock(_startMinute + _duration)}',
                    ),

                    const SectionTitle('Technician'),

                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'technician-$_sourceId',
                      ),
                      initialValue: _technicianId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Technician *',
                      ),
                      items: [
                        for (final technician in technicians)
                          DropdownMenuItem<String>(
                            value: technician.id,
                            child: Text(
                              '${technician.name} · '
                                  '${_store.openJobs(technician.id)} '
                                  'open jobs',
                            ),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                        setState(() {
                          _technicianId = value;
                        });
                      },
                      validator: (value) {
                        return value == null
                            ? 'Select a technician.'
                            : null;
                      },
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Technician and equipment booking '
                          'conflicts are checked when you create the job.',
                    ),

                    const SizedBox(height: 22),

                    FilledButton.icon(
                      onPressed: _saving ? null : _create,
                      icon: const Icon(
                        Icons.event_available_outlined,
                      ),
                      label: Text(
                        _saving
                            ? 'Creating…'
                            : 'Create Planned Job',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}