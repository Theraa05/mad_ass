import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeroHeader(
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 28),
            child: Column(children: [
              const Row(children: [
                BackButton(color: Colors.white),
                Text('My Contributions',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              const Icon(Icons.star_rounded,
                  size: 44, color: Color(0xFFFFD54F)),
              const Text('10',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1.1)),
              const Text('points · 1 verified report',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Badges'),
                const Row(children: [
                  Expanded(
                      child: _Badge(Icons.emoji_events_outlined, 'Rookie',
                          earned: true)),
                  SizedBox(width: 10),
                  Expanded(child: _Badge(Icons.handyman_outlined, 'Helper')),
                  SizedBox(width: 10),
                  Expanded(
                      child: _Badge(Icons.workspace_premium_outlined,
                          'Champion')),
                ]),
                const SectionTitle('Next badge progress'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Helper',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('10 / 30 points',
                              style: TextStyle(
                                  fontSize: 12, color: TarumtColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: const LinearProgressIndicator(
                          value: 10 / 30,
                          minHeight: 10,
                          color: TarumtColors.accent,
                          backgroundColor: TarumtColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionTitle('History'),
                const AppCard(
                  child: Row(children: [
                    IconBadge(Icons.verified_rounded,
                        color: TarumtColors.success,
                        background: TarumtColors.successTint),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RPT-001',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          Text('Verified · Air Conditioning',
                              style: TextStyle(
                                  fontSize: 12, color: TarumtColors.muted)),
                        ],
                      ),
                    ),
                    StatusChip('+10 pts',
                        color: TarumtColors.success,
                        background: TarumtColors.successTint),
                  ]),
                ),
                const SizedBox(height: 14),
                const Text('Earn 10 points per verified, unique report.',
                    style: TextStyle(fontSize: 11, color: TarumtColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool earned;
  const _Badge(this.icon, this.label, {this.earned = false});

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          IconBadge(
            earned ? icon : Icons.lock_outline_rounded,
            size: 46,
            color: earned ? TarumtColors.accent : TarumtColors.muted,
            background:
                earned ? TarumtColors.accentTint : TarumtColors.surface,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: earned ? TarumtColors.ink : TarumtColors.muted,
              )),
        ]),
      );
}
