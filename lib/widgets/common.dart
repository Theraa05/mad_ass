import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Logo extends StatelessWidget {
  final bool light;
  const Logo({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: light ? Colors.white : TarumtColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.build_rounded,
            size: 16, color: light ? TarumtColors.primary : Colors.white),
      ),
      const SizedBox(width: 8),
      Text('MYREPAIR',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: light ? Colors.white : TarumtColors.primary,
          )),
    ]);
  }
}

/// Blue gradient header with an optional campus photo behind it.
/// Put a photo at assets/images/campus.jpg (see README note) and pass
/// imageAsset. If the file is missing it quietly falls back to the gradient.
class HeroHeader extends StatelessWidget {
  final Widget child;
  final String? imageAsset;
  final EdgeInsets padding;
  const HeroHeader({
    super.key,
    required this.child,
    this.imageAsset,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
  });

  Widget _circle(double size) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0x14FFFFFF)),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(children: [
        const Positioned.fill(
          child: DecoratedBox(
              decoration: BoxDecoration(gradient: TarumtColors.heroGradient)),
        ),
        if (imageAsset != null) ...[
          Positioned.fill(
            child: Image.asset(imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          const Positioned.fill(
              child: ColoredBox(color: Color(0xB3082B66))),
        ],
        Positioned(right: -40, top: -40, child: _circle(150)),
        Positioned(left: -30, bottom: -50, child: _circle(120)),
        SafeArea(
          bottom: false,
          child: Padding(padding: padding, child: child),
        ),
      ]),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: TarumtColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  const IconBadge(
    this.icon, {
    super.key,
    this.color = TarumtColors.primary,
    this.background = TarumtColors.primaryTint,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}

class ScreenTitle extends StatelessWidget {
  final String text;
  const ScreenTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 26, fontWeight: FontWeight.w800, color: TarumtColors.ink));
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TarumtColors.ink)),
      );
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 16),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      );
}

/// Segmented progress bar + "Step x of y" + big title.
class StepHeader extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  const StepHeader(
      {super.key, required this.step, required this.total, required this.title});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            for (var i = 0; i < total; i++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i < step ? TarumtColors.primary : TarumtColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          Text('Step $step of $total',
              style: const TextStyle(fontSize: 12, color: TarumtColors.muted)),
          const SizedBox(height: 4),
          ScreenTitle(title),
        ],
      );
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;
  const StatusChip(
    this.label, {
    super.key,
    this.color = TarumtColors.accent,
    this.background = TarumtColors.accentTint,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ]),
      );
}

/// A tappable list row with an icon badge. Use inside an AppCard(padding: zero).
class MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const MenuRow(this.icon, this.title, {super.key, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            IconBadge(icon, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: TarumtColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: TarumtColors.muted),
          ]),
        ),
      );
}

/// Vertical progress timeline. `done` = how many steps are completed.
class StatusTimeline extends StatelessWidget {
  final List<String> steps;
  final int done;
  const StatusTimeline({super.key, required this.steps, required this.done});

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < steps.length; i++)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done ? TarumtColors.primary : TarumtColors.border,
                ),
                child: i < done
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
              if (i < steps.length - 1)
                Container(
                  width: 2,
                  height: 24,
                  color: i < done - 1
                      ? TarumtColors.primary
                      : TarumtColors.border,
                ),
            ]),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(steps[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i < done ? FontWeight.w700 : FontWeight.w400,
                    color: i < done ? TarumtColors.ink : TarumtColors.muted,
                  )),
            ),
          ]),
      ]);
}
