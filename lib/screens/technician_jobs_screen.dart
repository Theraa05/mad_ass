import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'technician_photo_picker.dart'
if (dart.library.html) 'technician_photo_picker_web.dart';

import '../models/work_order.dart';
import '../services/report_store.dart';

class TechnicianJobsScreen extends StatefulWidget {
  const TechnicianJobsScreen({
    super.key,
    required this.technicianId,
  });

  final String technicianId;

  @override
  State<TechnicianJobsScreen> createState() => _TechnicianJobsScreenState();
}

class _TechnicianJobsScreenState extends State<TechnicianJobsScreen> {
  final _store = ReportStore.instance;
  final _notes = <String, _TechnicianNotes>{};
  bool _plannedOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _TechnicianHeader(),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final technician = _store.technicianById(widget.technicianId);
          final assigned = _store.ordersForTechnician(widget.technicianId);
          final jobs = assigned
              .where((job) => !_plannedOnly || job.isPreventive)
              .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (technician != null)
                    Text(
                      technician.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All Jobs'),
                        selected: !_plannedOnly,
                        onSelected: (_) {
                          setState(() => _plannedOnly = false);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Preventive'),
                        selected: _plannedOnly,
                        onSelected: (_) {
                          setState(() => _plannedOnly = true);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (jobs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          _plannedOnly
                              ? 'No preventive jobs assigned.'
                              : 'No assigned jobs yet.',
                        ),
                      ),
                    ),
                  for (final job in jobs)
                    Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: Icon(
                          job.isPreventive
                              ? Icons.event_note_outlined
                              : Icons.build_outlined,
                        ),
                        title: Text('${job.id} · ${_statusLabel(job.status)}'),
                        subtitle: Text(
                          [
                            _scheduleLabel(context, job),
                            if (job.preventiveTask case final task?)
                              task.location
                            else if (_store.byId(job.reportId) case final report?)
                              '${report.building}, Room ${report.room}',
                          ].join('\n'),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openJob(job),
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

  Future<void> _openJob(WorkOrder job) async {
    final notes = _notes.putIfAbsent(job.id, _TechnicianNotes.new);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _TechnicianWorkOrderScreen(job: job, notes: notes),
      ),
    );

    if (mounted) setState(() {});
  }
}

class _TechnicianNotes {
  String progress = '';
  String holdReason = '';
  String holdNote = '';
  String resumeNote = '';
  String overrun = '';
}

class _TechnicianWorkOrderScreen extends StatefulWidget {
  const _TechnicianWorkOrderScreen({
    required this.job,
    required this.notes,
  });

  final WorkOrder job;
  final _TechnicianNotes notes;

  @override
  State<_TechnicianWorkOrderScreen> createState() =>
      _TechnicianWorkOrderScreenState();
}

class _TechnicianWorkOrderScreenState
    extends State<_TechnicianWorkOrderScreen> {
  final _store = ReportStore.instance;

  WorkOrder get _job => widget.job;
  _TechnicianNotes get _notes => widget.notes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final report = _store.byId(_job.reportId);
        final preventiveTask = _job.preventiveTask;
        final location = preventiveTask?.location ??
            (report == null
                ? 'Location unavailable'
                : '${report.building}, Room ${report.room}');
        final submission = _job.latestSubmission;

        return Scaffold(
          appBar: AppBar(title: Text(_screenTitle(_job.status))),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _job.id,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Status: ${_statusLabel(_job.status)}'),
                          Text(
                            'Type: ${_job.isPreventive ? 'Preventive' : 'Corrective'}',
                          ),
                          if (_job.reportId != null)
                            Text('Linked report: ${_job.reportId}'),
                          Text(
                            'Equipment: ${preventiveTask?.equipmentId ?? report?.equipmentId ?? 'Unavailable'}',
                          ),
                          Text('Location: $location'),
                          Text('Priority: ${_job.priority.name}'),
                          Text('Estimate: ${_job.estimatedMinutes} min'),
                          const SizedBox(height: 8),
                          const Text('Schedule'),
                          Text(_scheduleLabel(context, _job)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (report != null || preventiveTask != null)
                    _InfoCard(
                      title: _job.isPreventive
                          ? 'Maintenance Task'
                          : 'Report Description',
                      text: preventiveTask?.task ?? report?.description ?? '',
                    ),
                  if (_job.status == WorkOrderStatus.inProgress)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        initialValue: _notes.progress,
                        maxLines: 3,
                        onChanged: (value) => _notes.progress = value,
                        decoration: const InputDecoration(
                          labelText: 'Progress Note',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  if (_job.status == WorkOrderStatus.onHold)
                    _InfoCard(
                      title: 'Hold Reason',
                      text: [
                        _notes.holdReason,
                        _notes.holdNote,
                      ].where((text) => text.isNotEmpty).join('\n'),
                    ),
                  if (_notes.resumeNote.isNotEmpty)
                    _InfoCard(title: 'Resume Note', text: _notes.resumeNote),
                  if (_notes.overrun.isNotEmpty)
                    _InfoCard(title: 'Overrun Note', text: _notes.overrun),
                  if (_job.status == WorkOrderStatus.returnedForRework &&
                      _job.inspections.isNotEmpty)
                    _InfoCard(
                      title: 'Coordinator Note',
                      text: _job.inspections.last.note,
                    ),
                  if (submission != null &&
                      (_job.status == WorkOrderStatus.pendingVerification ||
                          _job.status == WorkOrderStatus.returnedForRework ||
                          _job.status == WorkOrderStatus.resolved)) ...[
                    _InfoCard(
                      title: 'Repair Note',
                      text: submission.repairNote,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.memory(
                        submission.completionPhoto,
                        height: 180,
                        fit: BoxFit.contain,
                        semanticLabel: 'Completion photo',
                        errorBuilder: (_, _, _) =>
                        const Text('Photo preview unavailable.'),
                      ),
                    ),
                    Text(
                      submission.equipmentTested
                          ? 'Equipment tested'
                          : 'Equipment test not recorded',
                    ),
                  ],
                  const SizedBox(height: 16),
                  ..._actions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _actions() {
    switch (_job.status) {
      case WorkOrderStatus.assigned:
        return [
          FilledButton(
            onPressed: _startWork,
            child: const Text('Start Work'),
          ),
        ];
      case WorkOrderStatus.inProgress:
        return [
          FilledButton(
            onPressed: _completeRepair,
            child: const Text('Complete Repair'),
          ),
          OutlinedButton(
            onPressed: _putOnHold,
            child: const Text('Put On Hold'),
          ),
          OutlinedButton(
            onPressed: _reportOverrun,
            child: const Text('Report Overrun'),
          ),
        ];
      case WorkOrderStatus.onHold:
        return [
          FilledButton(
            onPressed: _resumeWork,
            child: const Text('Resume Work'),
          ),
        ];
      case WorkOrderStatus.returnedForRework:
        return [
          FilledButton(
            onPressed: _startWork,
            child: const Text('Continue Repair'),
          ),
        ];
      case WorkOrderStatus.pendingVerification:
      case WorkOrderStatus.resolved:
        return [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to My Jobs'),
          ),
        ];
    }
  }

  void _startWork() {
    try {
      _store.startWorkOrder(_job.id);
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _putOnHold() async {
    final reason = await _askForText(
      context,
      title: 'Put On Hold',
      label: 'Delay reason',
      button: 'Confirm Hold',
    );
    if (!mounted || reason == null ||
        _job.status != WorkOrderStatus.inProgress) {
      return;
    }

    setState(() {
      _notes.holdReason = reason;
      _job.status = WorkOrderStatus.onHold;
    });
  }

  Future<void> _resumeWork() async {
    final note = await _askForText(
      context,
      title: 'Resume Work',
      label: 'Resume note',
      button: 'Resume Work',
    );
    if (!mounted || note == null || _job.status != WorkOrderStatus.onHold) {
      return;
    }

    setState(() {
      _notes.resumeNote = note;
      _job.status = WorkOrderStatus.inProgress;
    });
  }

  Future<void> _reportOverrun() async {
    final note = await _askForText(
      context,
      title: 'Report Overrun',
      label: 'Reason and extra time needed',
      button: 'Save Overrun Note',
    );
    if (!mounted || note == null) return;

    setState(() => _notes.overrun = note);
    _showMessage('Overrun note saved for this session.');
  }

  Future<void> _completeRepair() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _CompleteRepairScreen(job: _job),
      ),
    );

    if (mounted && submitted == true) {
      _showMessage('Repair submitted for verification.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _CompleteRepairScreen extends StatefulWidget {
  const _CompleteRepairScreen({required this.job});

  final WorkOrder job;

  @override
  State<_CompleteRepairScreen> createState() => _CompleteRepairScreenState();
}

class _CompleteRepairScreenState extends State<_CompleteRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repairNote = TextEditingController();

  Uint8List? _photo;
  bool _equipmentTested = false;
  bool _pickingPhoto = false;

  @override
  void dispose() {
    _repairNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Repair')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.job.id,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _repairNote,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Repair Note',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Enter a repair note.'
                      : null,
                ),
                OutlinedButton.icon(
                  onPressed: _pickingPhoto ? null : _pickPhoto,
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(
                    _photo == null
                        ? 'Upload Completion Photo'
                        : 'Replace Completion Photo',
                  ),
                ),
                if (_photo != null)
                  Image.memory(
                    _photo!,
                    height: 180,
                    fit: BoxFit.contain,
                    semanticLabel: 'Selected completion photo',
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Equipment tested'),
                  value: _equipmentTested,
                  onChanged: (value) {
                    setState(() => _equipmentTested = value ?? false);
                  },
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _pickingPhoto ? null : _submit,
                  child: const Text('Submit for Verification'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);

    try {
      final bytes = await pickTechnicianPhoto();
      if (!mounted || bytes == null) return;

      setState(() => _photo = bytes);
    } on UnsupportedError catch (error) {
      if (mounted) _showMessage('${error.message}');
    } catch (_) {
      if (mounted) _showMessage('Could not open the photo.');
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final photo = _photo;
    if (photo == null || photo.isEmpty) {
      _showMessage('Select a completion photo.');
      return;
    }

    if (!_equipmentTested) {
      _showMessage('Confirm that the equipment was tested.');
      return;
    }

    try {
      ReportStore.instance.submitRepairForVerification(
        workOrderId: widget.job.id,
        repairNote: _repairNote.text.trim(),
        completionPhoto: photo,
        equipmentTested: _equipmentTested,
      );
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      _showMessage(error.message);
    } on ArgumentError catch (error) {
      _showMessage('${error.message}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(text),
          ],
        ),
      ),
    );
  }
}

Future<String?> _askForText(
    BuildContext context, {
      required String title,
      required String label,
      required String button,
    }) {
  final formKey = GlobalKey<FormState>();
  var text = '';

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          autofocus: true,
          maxLines: 3,
          onChanged: (value) => text = value.trim(),
          validator: (value) =>
          (value ?? '').trim().isEmpty ? 'Enter a value.' : null,
          decoration: InputDecoration(labelText: label),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(dialogContext).pop(text);
            }
          },
          child: Text(button),
        ),
      ],
    ),
  );
}

String _scheduleLabel(BuildContext context, WorkOrder job) {
  if (job.blocks.isEmpty) return 'No time slot scheduled.';

  final localizations = MaterialLocalizations.of(context);
  return job.blocks.map((block) {
    final date = localizations.formatShortDate(block.start);
    final start = TimeOfDay.fromDateTime(block.start).format(context);
    final end = TimeOfDay.fromDateTime(block.end).format(context);
    return '$date · $start – $end';
  }).join('\n');
}

String _statusLabel(WorkOrderStatus status) => switch (status) {
  WorkOrderStatus.assigned => 'Assigned',
  WorkOrderStatus.inProgress => 'In Progress',
  WorkOrderStatus.onHold => 'On Hold',
  WorkOrderStatus.pendingVerification => 'Pending Verification',
  WorkOrderStatus.returnedForRework => 'Returned for Rework',
  WorkOrderStatus.resolved => 'Resolved',
};

String _screenTitle(WorkOrderStatus status) => switch (status) {
  WorkOrderStatus.inProgress => 'Repair in Progress',
  WorkOrderStatus.pendingVerification => 'Awaiting Verification',
  WorkOrderStatus.returnedForRework => 'Rework Required',
  _ => 'Work Order Details',
};

class _TechnicianHeader extends StatelessWidget implements PreferredSizeWidget {
  const _TechnicianHeader();

  @override
  Size get preferredSize => const Size.fromHeight(156);

  @override
  Widget build(BuildContext context) {
    final blue = Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF0B285C), blue]),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: preferredSize.height,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'MYREPAIR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'My Assigned Jobs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
