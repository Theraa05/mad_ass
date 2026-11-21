import 'package:flutter/material.dart';

class RepairCategory {
  final String label;
  final IconData icon;
  const RepairCategory(this.label, this.icon);
}

/// Add or rename categories here. They show up on Home and in Issue details.
const repairCategories = [
  RepairCategory('Air Conditioning', Icons.ac_unit_rounded),
  RepairCategory('Electrical', Icons.bolt_rounded),
  RepairCategory('Plumbing', Icons.water_drop_outlined),
  RepairCategory('Furniture', Icons.chair_alt_outlined),
  RepairCategory('Network', Icons.wifi_rounded),
  RepairCategory('Lighting', Icons.lightbulb_outline_rounded),
];
