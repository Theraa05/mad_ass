import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/category_grid.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';

/// Dashboard for students and anyone reporting an issue.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.current;
    final name = user?.displayName ?? 'there';
    final email = user?.email ?? '';
    final store = ReportStore.instance;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeroHeader(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                Row(children: [
                  const Logo(light: true),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.settings),
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xCCFFFFFF), fontSize: 12)),
                        const Text('What needs fixing today?',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.contributions),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFFFD54F)),
                        SizedBox(width: 4),
                        Text('2 pts',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.edit_note_rounded,
                      title: 'Start Report',
                      subtitle: 'Fill in the details',
                      onTap: () {
                        store.resetDraft();
                        Navigator.pushNamed(context, AppRoutes.details);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan Equipment QR',
                      subtitle: 'Auto-fill equipment',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.scan),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Report by category'),
                CategoryGrid(
                  onSelected: (i) {
                    store.resetDraft();
                    store.draft.category = repairCategories[i].label;
                    Navigator.pushNamed(context, AppRoutes.details);
                  },
                ),
                const SectionTitle('Quick links'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    MenuRow(Icons.description_outlined, 'My Reports',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.myReports)),
                    const Divider(height: 1),
                    MenuRow(Icons.star_outline_rounded, 'My Contributions',
                        subtitle: '2 points',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.contributions)),
                    const Divider(height: 1),
                    const MenuRow(
                        Icons.engineering_outlined, 'Maintenance State'),
                    const Divider(height: 1),
                    const MenuRow(Icons.help_outline_rounded, 'Help & FAQ'),
                  ]),
                ),
                const SectionTitle('Recent report'),
                ListenableBuilder(
                  listenable: store,
                  builder: (context, _) {
                    final mine = store.forReporter(email);
                    if (mine.isEmpty) {
                      return const AppCard(
                        child: Row(children: [
                          IconBadge(Icons.inbox_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                                'No reports yet. Tap Start Report to send your first one.',
                                style: TextStyle(
                                    fontSize: 12, color: TarumtColors.muted)),
                          ),
                        ]),
                      );
                    }
                    return ReportTile(
                      report: mine.first,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.myReports),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: TarumtColors.muted)),
        ],
      ),
    );
  }
}
