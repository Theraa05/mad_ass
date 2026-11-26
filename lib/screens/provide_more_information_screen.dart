import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/reporter_photo_input.dart';

class ProvideMoreInformationScreen extends StatefulWidget {
  const ProvideMoreInformationScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ProvideMoreInformationScreen> createState() =>
      _ProvideMoreInformationScreenState();
}

class _ProvideMoreInformationScreenState
    extends State<ProvideMoreInformationScreen> {
  final _reply = TextEditingController();
  Uint8List? _photo;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    final text = _reply.text.trim();
    final request = ReportStore.instance.pendingClarification(widget.reportId);
    if (text.isEmpty) {
      _message('Enter the requested information.');
      return;
    }
    if (request?.photoRequested == true && _photo == null) {
      _message('Attach the requested photo before replying.');
      return;
    }
    try {
      ReportStore.instance.submitClarificationReply(
        widget.reportId,
        reply: text,
        photo: _photo,
      );
      if (mounted) {
        _message('Reply sent. The Coordinator can continue the review.');
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
        title: const Text('Provide More Information'),
      ),
      body: ListenableBuilder(
        listenable: ReportStore.instance,
        builder: (context, _) {
          final report = ReportStore.instance.byId(widget.reportId);
          final request = report == null
              ? null
              : ReportStore.instance.pendingClarification(report.id);
          if (report == null || request == null) {
            return const Center(
              child: Text('No clarification is awaiting a reply.'),
            );
          }
          if (AuthService.current?.email != report.reporterEmail) {
            return const Center(child: Text('Reporter access is required.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              const ScreenTitle('Provide More Information'),
              const SizedBox(height: 8),
              Text(
                '${report.id} · ${report.location}',
                style: const TextStyle(color: TarumtColors.muted),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coordinator question',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(request.text),
                    if (request.photoRequested) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'A clear equipment photo is required for this reply.',
                        style: TextStyle(
                          color: TarumtColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('clarification-reply'),
                controller: _reply,
                minLines: 4,
                maxLines: 7,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Your reply *',
                  hintText: 'AC-D203H.101, nearest the whiteboard.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              ReporterPhotoInput(
                key: const ValueKey('clarification-photo-input'),
                requiredPhoto: request.photoRequested,
                onChanged: (photo) => _photo = photo,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('submit-clarification-reply'),
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send Reply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
