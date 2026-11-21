import 'package:flutter/material.dart';

import '../models/report.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ImpactPhotosScreen extends StatefulWidget {
  const ImpactPhotosScreen({super.key});
  @override
  State<ImpactPhotosScreen> createState() => _ImpactPhotosScreenState();
}

class _ImpactPhotosScreenState extends State<ImpactPhotosScreen> {
  int _urgency = 1;
  bool _hasPhoto = false;
  final _impact = TextEditingController();
  static const _levels = [
    ('Low', Icons.sentiment_satisfied_alt_rounded),
    ('Medium', Icons.sentiment_neutral_rounded),
    ('High', Icons.warning_amber_rounded),
  ];

  @override
  void dispose() {
    _impact.dispose();
    super.dispose();
  }

  void _submit() {
    if (_impact.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please describe how it affects the space')));
      return;
    }
    final report = ReportStore.instance.submit(
      email: AuthService.current?.email ?? 'guest@unknown',
      impact: _impact.text.trim(),
      urgency: Urgency.values[_urgency],
      hasPhoto: _hasPhoto,
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.submitted,
      (route) => route.isFirst,
      arguments: report,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ReportStore.instance.draft;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Report an Issue', style: TextStyle(fontSize: 14)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const StepHeader(step: 2, total: 2, title: 'Impact and photos'),
            const SizedBox(height: 16),
            AppCard(
              child: Row(children: [
                const IconBadge(Icons.build_rounded,
                    color: TarumtColors.accent,
                    background: TarumtColors.accentTint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(draft.equipmentId,
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                          '${draft.category} · ${draft.building} Room ${draft.room}',
                          style: const TextStyle(
                              fontSize: 12, color: TarumtColors.muted)),
                    ],
                  ),
                ),
              ]),
            ),
            const FieldLabel('How urgent is it?'),
            Wrap(spacing: 8, children: [
              for (var i = 0; i < _levels.length; i++)
                ChoiceChip(
                  avatar: Icon(_levels[i].$2, size: 18),
                  label: Text(_levels[i].$1),
                  selected: _urgency == i,
                  selectedColor: TarumtColors.primaryTint,
                  onSelected: (_) => setState(() => _urgency = i),
                ),
            ]),
            const FieldLabel('How does it affect the space? *'),
            TextField(
              controller: _impact,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Room becomes hot during classes.'),
            ),
            const FieldLabel('Photo attachments'),
            Row(children: [
              _PhotoSlot(
                icon: Icons.add_a_photo_outlined,
                label: 'Add photo',
                // TODO: open image_picker here and keep the picked file.
                onTap: () => setState(() => _hasPhoto = true),
              ),
              if (_hasPhoto) ...[
                const SizedBox(width: 10),
                _PhotoSlot(
                  icon: Icons.image_outlined,
                  label: 'Tap to remove',
                  filled: true,
                  onTap: () => setState(() => _hasPhoto = false),
                ),
              ],
            ]),
            const SizedBox(height: 6),
            const Text('Optional · JPEG or PNG · up to 5 MB',
                style: TextStyle(fontSize: 11, color: TarumtColors.muted)),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _PhotoSlot({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: filled ? TarumtColors.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: filled ? TarumtColors.primary : TarumtColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: TarumtColors.primary, size: 28),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}
