import 'package:flutter/material.dart';

import '../models/report.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';

/// Dashboard for management / maintenance staff.
class ManagementDashboardScreen extends StatefulWidget {
  const ManagementDashboardScreen({super.key});
  @override
  State<ManagementDashboardScreen> createState() =>
      _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState
    extends State<ManagementDashboardScreen> {
  ReportStatus? _filter;

  void _signOut() {
    AuthService.signOut();
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.signIn, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.current;

    return Scaffold(
      body: ListenableBuilder(
        listenable: ReportStore.instance,
        builder: (context, _) {
          final all = ReportStore.instance.all;
          int count(Set<ReportStatus> s) =>
              all.where((r) => s.contains(r.status)).length;
          final shown = _filter == null
              ? all
              : all.where((r) => r.status == _filter).toList();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              HeroHeader(
                imageAsset: 'assets/images/campus.jpg',
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Logo(light: true),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(children: [
                          Icon(Icons.admin_panel_settings_outlined,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Management',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    const Text('Maintenance dashboard',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    Text(user?.email ?? '',
                        style: const TextStyle(
                            color: Color(0xCCFFFFFF), fontSize: 12)),
                    const SizedBox(height: 18),
                    Row(children: [
                      _StatTile('${all.length}', 'Total',
                          Icons.inbox_rounded, TarumtColors.primary),
                      const SizedBox(width: 8),
                      _StatTile(
                          '${count({ReportStatus.submitted})}',
                          'New',
                          Icons.fiber_new_rounded,
                          TarumtColors.accent),
                      const SizedBox(width: 8),
                      _StatTile(
                          '${count({
                            ReportStatus.underReview,
                            ReportStatus.inProgress,
                            ReportStatus.needsInfo
                          })}',
                          'Active',
                          Icons.engineering_rounded,
                          TarumtColors.warning),
                      const SizedBox(width: 8),
                      _StatTile(
                          '${count({ReportStatus.resolved})}',
                          'Resolved',
                          Icons.check_circle_rounded,
                          TarumtColors.success),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Reports'),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('All (${all.length})'),
                              selected: _filter == null,
                              selectedColor: TarumtColors.primaryTint,
                              onSelected: (_) =>
                                  setState(() => _filter = null),
                            ),
                          ),
                          for (final s in ReportStatus.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(s.icon, size: 16, color: s.color),
                                label: Text('${s.label} (${count({s})})'),
                                selected: _filter == s,
                                selectedColor: s.tint,
                                onSelected: (_) =>
                                    setState(() => _filter = s),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (shown.isEmpty)
                      const AppCard(
                        child: Row(children: [
                          IconBadge(Icons.inbox_outlined),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text('No reports with this status.')),
                        ]),
                      ),
                    for (final r in shown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReportTile(
                          report: r,
                          showReporter: true,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.manageReport,
                              arguments: r.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatTile(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 10, color: TarumtColors.muted)),
            ],
          ),
        ),
      );
}
