import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/email_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';

/// Management view of one report: read the details, change the status,
/// add a note, and email the reporter when it is resolved.
class ManagementReportScreen extends StatefulWidget {
  const ManagementReportScreen({super.key});
  @override
  State<ManagementReportScreen> createState() =>
      _ManagementReportScreenState();
}

class _ManagementReportScreenState extends State<ManagementReportScreen> {
  Report? _report;
  late ReportStatus _selected;
  bool _notify = true;
  bool _saving = false;
  final _note = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_report == null) {
      final id = ModalRoute.of(context)!.settings.arguments as String;
      final r = ReportStore.instance.byId(id);
      _report = r;
      if (r != null) {
        _selected = r.status;
        _notify = r.notifiedAt == null; // don't email twice by default
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final report = _report!;
    final store = ReportStore.instance;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final note = _note.text.trim();
    final wantsEmail = _selected == ReportStatus.resolved && _notify;

    setState(() => _saving = true);
    store.updateStatus(report.id, _selected, note: note);

    var emailed = false;
    if (wantsEmail) {
      emailed = await EmailService.send(
          EmailService.resolvedNotice(report, note: note));
      if (emailed) store.markNotified(report.id);
    }

    final String message;
    if (wantsEmail && emailed) {
      message = '${report.id} resolved. Email sent to ${report.reporterEmail}';
    } else if (wantsEmail) {
      message = 'Status saved, but the email could not be sent';
    } else {
      message = '${report.id} updated to ${_selected.label}';
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('Report not found')),
      );
    }
    final resolving = _selected == ReportStatus.resolved;
    final preview =
        EmailService.resolvedNotice(report, note: _note.text.trim());

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(report.id, style: const TextStyle(fontSize: 14)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconBadge(report.icon,
                        color: TarumtColors.accent,
                        background: TarumtColors.accentTint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.category,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(report.equipmentId,
                              style: const TextStyle(
                                  fontSize: 12, color: TarumtColors.muted)),
                        ],
                      ),
                    ),
                    ReportStatusChip(report.status),
                  ]),
                  const Divider(height: 26),
                  _DetailRow(Icons.location_on_outlined, report.location),
                  _DetailRow(Icons.person_outline_rounded, report.reporterEmail),
                  _DetailRow(Icons.calendar_today_outlined,
                      'Submitted ${report.dateLabel}'),
                  _DetailRow(Icons.flag_outlined,
                      '${report.urgency.label} urgency'),
                  const SizedBox(height: 6),
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TarumtColors.muted)),
                  Text(report.description),
                  const SizedBox(height: 10),
                  const Text('Impact',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TarumtColors.muted)),
                  Text(report.impact.isEmpty ? '-' : report.impact),
                  if (report.hasPhoto) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TarumtColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(children: [
                        Icon(Icons.image_outlined,
                            size: 18, color: TarumtColors.primary),
                        SizedBox(width: 8),
                        Text('Photo attached', style: TextStyle(fontSize: 12)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            const SectionTitle('Update status'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in ReportStatus.values)
                ChoiceChip(
                  avatar: Icon(s.icon, size: 16, color: s.color),
                  label: Text(s.label),
                  selected: _selected == s,
                  selectedColor: s.tint,
                  onSelected: (_) => setState(() => _selected = s),
                ),
            ]),
            const FieldLabel('Note to reporter (optional)'),
            TextField(
              controller: _note,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: report.managerNote ?? 'e.g. Technician replaced the filter.',
              ),
            ),
            if (resolving) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const IconBadge(Icons.mark_email_read_outlined,
                          color: TarumtColors.success,
                          background: TarumtColors.successTint),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email the reporter',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            Text('Notify ${report.reporterEmail}',
                                style: const TextStyle(
                                    fontSize: 12, color: TarumtColors.muted)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _notify,
                        onChanged: (v) => setState(() => _notify = v),
                      ),
                    ]),
                    if (_notify) ...[
                      const Divider(height: 24),
                      Text('Subject: ${preview.subject}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                    if (report.notifiedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                          'A notification was already sent on ${formatDate(report.notifiedAt!)}.',
                          style: const TextStyle(
                              fontSize: 11, color: TarumtColors.muted)),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(resolving && _notify
                      ? Icons.send_rounded
                      : Icons.save_outlined),
              label: Text(resolving && _notify
                  ? 'Resolve & notify reporter'
                  : 'Save status'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: TarumtColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );
}
