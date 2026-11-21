import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../theme/app_theme.dart';

/// 3-column grid of repair categories with icons.
/// `selected` is null on Home (just tappable) and an index on Issue details.
class CategoryGrid extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelected;
  const CategoryGrid({super.key, this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < repairCategories.length; i++) _tile(i),
      ],
    );
  }

  Widget _tile(int i) {
    final cat = repairCategories[i];
    final isSelected = selected == i;
    return Material(
      color: isSelected ? TarumtColors.primaryTint : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? TarumtColors.primary : TarumtColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        onTap: () => onSelected(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon,
                size: 28,
                color: isSelected ? TarumtColors.primary : TarumtColors.accent),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(cat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? TarumtColors.primary : TarumtColors.ink,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
