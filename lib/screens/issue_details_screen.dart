import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../routes.dart';
import '../services/report_store.dart';
import '../widgets/category_grid.dart';
import '../widgets/common.dart';

class IssueDetailsScreen extends StatefulWidget {
  const IssueDetailsScreen({super.key});
  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  static const _buildings = ['Block A', 'Block B', 'Block C', 'Block D'];
  static const _rooms = ['201H', '202H', '203H'];

  final _draft = ReportStore.instance.draft;
  late String _building = _buildings.contains(_draft.building)
      ? _draft.building
      : _buildings.first;
  late String _room =
      _rooms.contains(_draft.room) ? _draft.room : _rooms.first;
  late int _category = _initialCategory();
  late final _equipment = TextEditingController(text: _draft.equipmentId);
  late final _description = TextEditingController(text: _draft.description);

  int _initialCategory() {
    final i = repairCategories.indexWhere((c) => c.label == _draft.category);
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    _equipment.dispose();
    _description.dispose();
    super.dispose();
  }

  void _next() {
    if (_equipment.text.trim().isEmpty || _description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill in the equipment ID and description')));
      return;
    }
    _draft
      ..category = repairCategories[_category].label
      ..building = _building
      ..room = _room
      ..equipmentId = _equipment.text.trim()
      ..description = _description.text.trim();
    Navigator.pushNamed(context, AppRoutes.impact);
  }

  Widget _dropdown(IconData icon, String value, List<String> items,
          ValueChanged<String> onChanged) =>
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(prefixIcon: Icon(icon, size: 20)),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Report an Issue', style: TextStyle(fontSize: 14)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const StepHeader(step: 1, total: 2, title: 'Issue details'),
            const FieldLabel('Building *'),
            _dropdown(Icons.apartment_rounded, _building, _buildings,
                (v) => setState(() => _building = v)),
            const FieldLabel('Room / Area *'),
            _dropdown(Icons.meeting_room_outlined, _room, _rooms,
                (v) => setState(() => _room = v)),
            const FieldLabel('Category *'),
            CategoryGrid(
              selected: _category,
              onSelected: (i) => setState(() => _category = i),
            ),
            const FieldLabel('Equipment ID *'),
            TextField(
              controller: _equipment,
              decoration: const InputDecoration(
                hintText: 'AC-D203H-101',
                prefixIcon: Icon(Icons.qr_code_2_rounded, size: 20),
              ),
            ),
            const FieldLabel('Description *'),
            TextField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'Air conditioner keeps warm air coming out.'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
