import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/report.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/report_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'management_schedule_screen.dart';
import 'planned_maintenance_screen.dart';
import 'verify_repairs_screen.dart';

enum _QueueOrder {
  oldest,
  newest,
  urgency,
}

class ManagementDashboardScreen extends StatefulWidget {
  const ManagementDashboardScreen({super.key});

  @override
  State<ManagementDashboardScreen> createState() =>
      _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState
    extends State<ManagementDashboardScreen> {
  final _search = TextEditingController();

  ReportStatus? _status = ReportStatus.submitted;
  String _category = '';
  _QueueOrder _order = _QueueOrder.oldest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _signOut() {
    AuthService.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.signIn,
          (route) => false,
    );
  }

  void _openRepairFeedback(ReportStore store) {
    final pending = store.pendingRepairFeedbacks;
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No repair feedback is awaiting review.')),
      );
      return;
    }
    final report = store.reportForFeedback(pending.first);
    if (report == null) return;
    Navigator.pushNamed(context, AppRoutes.manageReport, arguments: report.id);
  }

  void _clearFilters() {
    setState(() {
      _search.clear();
      _category = '';
      _status = null;
      _order = _QueueOrder.oldest;
    });
  }

  bool _matchesSearch(Report report) {
    final words = _search.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'));

    final text = [
      report.id,
      report.category,
      report.equipmentId,
      report.location,
      report.description,
      report.impact,
      report.reporterEmail,
    ].join(' ').toLowerCase();

    return words.every(text.contains);
  }

  int _compare(Report a, Report b) {
    if (_order == _QueueOrder.urgency) {
      final urgency = b.urgency.index.compareTo(
        a.urgency.index,
      );

      if (urgency != 0) {
        return urgency;
      }
    }

    final created = _order == _QueueOrder.newest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt);

    return created != 0
        ? created
        : a.id.compareTo(b.id);
  }

  String get _orderHint {
    return switch (_order) {
      _QueueOrder.oldest =>
      'Earlier submissions appear first (FIFO).',
      _QueueOrder.newest =>
      'Most recent submissions appear first.',
      _QueueOrder.urgency =>
      'Reporter urgency: High, Medium, Low. '
          'Equal urgency uses FIFO. '
          'Confirm the repair priority during review.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: ReportStore.instance,
        builder: (context, _) {
          final store = ReportStore.instance;
          final all = store.all;

          final matching = all.where((report) {
            return (_category.isEmpty ||
                report.category == _category) &&
                _matchesSearch(report);
          }).toList();

          final shown = matching.where((report) {
            return _status == null ||
                report.status == _status;
          }).toList()
            ..sort(_compare);

          final categories = {
            for (final category in repairCategories)
              category.label,
            for (final report in all)
              report.category,
          }.toList()
            ..sort();

          int count(ReportStatus status) {
            return all
                .where((report) => report.status == status)
                .length;
          }

          int matchingCount(ReportStatus status) {
            return matching
                .where((report) => report.status == status)
                .length;
          }

          return CustomScrollView(
            key: const PageStorageKey(
              'incoming-requests-scroll',
            ),
            slivers: [
              SliverToBoxAdapter(
                child: HeroHeader(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1040,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  crossAxisAlignment:
                                  WrapCrossAlignment.center,
                                  children: [
                                    const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                      Alignment.centerLeft,
                                      child: Logo(
                                        light: true,
                                      ),
                                    ),
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0x33FFFFFF,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(
                                          20,
                                        ),
                                      ),
                                      child: const Text(
                                        'Coordinator',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Sign out',
                                onPressed: _signOut,
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Incoming Requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            AuthService.current?.email ?? '',
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // View confirmed jobs.
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                              TarumtColors.primary,
                              minimumSize:
                              const Size.fromHeight(52),
                            ),
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                  const ManagementScheduleScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                            ),
                            label: const Text(
                              'View Repair Schedule',
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Create preventive maintenance.
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                              TarumtColors.primary,
                              minimumSize:
                              const Size.fromHeight(52),
                            ),
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                  const PlannedMaintenanceScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.build_circle_outlined,
                            ),
                            label: const Text(
                              'Plan Maintenance',
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Inspect submitted completion evidence.
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                              TarumtColors.primary,
                              minimumSize:
                              const Size.fromHeight(52),
                            ),
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                  const VerifyRepairsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.fact_check_outlined,
                            ),
                            label: Text(
                              'Verify Repairs '
                                  '(${store.pendingVerifications.length})',
                            ),
                          ),

                          const SizedBox(height: 16),

                          FilledButton.icon(
                            key: const ValueKey('review-repair-feedback'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: TarumtColors.primary,
                              minimumSize: const Size.fromHeight(52),
                            ),
                            onPressed: () => _openRepairFeedback(store),
                            icon: const Icon(Icons.rate_review_outlined),
                            label: Text(
                              'Repair Feedback '
                              '(${store.pendingRepairFeedbacks.length})',
                            ),
                          ),

                          const SizedBox(height: 16),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact =
                                  constraints.maxWidth < 600;

                              final width =
                                  (constraints.maxWidth - 24) / 4;

                              final summaries = [
                                _QueueSummary(
                                  value: all.length,
                                  label: 'Total reports',
                                  icon: Icons.inbox_outlined,
                                  color: TarumtColors.primary,
                                  compact: compact,
                                ),
                                _QueueSummary(
                                  value: count(
                                    ReportStatus.submitted,
                                  ),
                                  label: 'New requests',
                                  icon:
                                  Icons.fiber_new_outlined,
                                  color: TarumtColors.primary,
                                  compact: compact,
                                ),
                                _QueueSummary(
                                  value: count(
                                    ReportStatus.needsInfo,
                                  ),
                                  label: 'Needs information',
                                  icon: Icons
                                      .question_answer_outlined,
                                  color: TarumtColors.warning,
                                  compact: compact,
                                ),
                                _QueueSummary(
                                  value: all.where((report) {
                                    return report.urgency ==
                                        Urgency.high &&
                                        report.status !=
                                            ReportStatus.resolved;
                                  }).length,
                                  label: 'High urgency',
                                  icon: Icons.flag_outlined,
                                  color: TarumtColors.accent,
                                  compact: compact,
                                ),
                              ];

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final summary
                                  in summaries)
                                    if (compact)
                                      summary
                                    else
                                      SizedBox(
                                        width: width,
                                        child: summary,
                                      ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _QueueWidth(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),

                      TextField(
                        key: const ValueKey(
                          'incoming-search',
                        ),
                        controller: _search,
                        onChanged: (_) {
                          setState(() {});
                        },
                        textInputAction:
                        TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Search requests',
                          hintText:
                          'Report ID, equipment, '
                              'location or reporter',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                          ),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              setState(
                                _search.clear,
                              );
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding:
                              const EdgeInsets.only(
                                right: 8,
                              ),
                              child: ChoiceChip(
                                key: const ValueKey(
                                  'status-all',
                                ),
                                label: Text(
                                  'All (${matching.length})',
                                ),
                                selected: _status == null,
                                selectedColor:
                                TarumtColors.primaryTint,
                                onSelected: (_) {
                                  setState(() {
                                    _status = null;
                                  });
                                },
                              ),
                            ),

                            for (final status in [
                              ReportStatus.submitted,
                              ReportStatus.underReview,
                              ReportStatus.needsInfo,
                              ReportStatus.assigned,
                              ReportStatus.inProgress,
                              ReportStatus.pendingVerification,
                              ReportStatus.returnedForRework,
                              ReportStatus.resolved,
                            ])
                              Padding(
                                padding:
                                const EdgeInsets.only(
                                  right: 8,
                                ),
                                child: ChoiceChip(
                                  key: ValueKey(
                                    'status-${status.name}',
                                  ),
                                  label: Text(
                                    '${_queueStatusLabel(status)} '
                                        '(${matchingCount(status)})',
                                  ),
                                  selected:
                                  _status == status,
                                  selectedColor:
                                  status.tint,
                                  onSelected: (_) {
                                    setState(() {
                                      _status = status;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final category =
                          _QueueSelect<String>(
                            fieldKey: const ValueKey(
                              'incoming-category',
                            ),
                            label: 'Category',
                            value: _category,
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text(
                                  'All categories',
                                ),
                              ),
                              for (final category
                              in categories)
                                DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _category = value;
                              });
                            },
                          );

                          final order =
                          _QueueSelect<_QueueOrder>(
                            fieldKey: const ValueKey(
                              'incoming-order',
                            ),
                            label: 'Queue order',
                            value: _order,
                            items: const [
                              DropdownMenuItem<_QueueOrder>(
                                value: _QueueOrder.oldest,
                                child: Text(
                                  'Oldest first (FIFO)',
                                ),
                              ),
                              DropdownMenuItem<_QueueOrder>(
                                value: _QueueOrder.newest,
                                child: Text(
                                  'Newest first',
                                ),
                              ),
                              DropdownMenuItem<_QueueOrder>(
                                value: _QueueOrder.urgency,
                                child: Text(
                                  'Reporter urgency first',
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _order = value;
                              });
                            },
                          );

                          if (constraints.maxWidth < 340) {
                            return Column(
                              children: [
                                category,
                                const SizedBox(
                                  height: 12,
                                ),
                                order,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: category,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: order,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _orderHint,
                        style: const TextStyle(
                          color: TarumtColors.muted,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment:
                          WrapAlignment.spaceBetween,
                          crossAxisAlignment:
                          WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              '${shown.length} '
                                  '${shown.length == 1 ? 'request' : 'requests'}',
                              key: const ValueKey(
                                'incoming-result-count',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                            TextButton(
                              key: const ValueKey(
                                'incoming-clear-filters',
                              ),
                              onPressed: _clearFilters,
                              child: const Text(
                                'Clear filters',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),

              if (shown.isEmpty)
                SliverToBoxAdapter(
                  child: _QueueWidth(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const IconBadge(
                            Icons.inbox_outlined,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            all.isEmpty
                                ? 'No requests yet'
                                : 'No matching requests',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            all.isEmpty
                                ? 'New campus reports '
                                'will appear here.'
                                : 'Try another search, '
                                'category or status. '
                                'Clear filters to '
                                'see all reports.',
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final report = shown[index];

                      return _QueueWidth(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _RequestCard(
                            key: ValueKey(
                              'request-${report.id}',
                            ),
                            report: report,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.manageReport,
                                arguments: report.id,
                              );
                            },
                          ),
                        ),
                      );
                    },
                    childCount: shown.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _queueStatusLabel(ReportStatus status) {
  return switch (status) {
    ReportStatus.submitted => 'New',
    ReportStatus.needsInfo => 'Needs information',
    _ => status.label,
  };
}

class _QueueWidth extends StatelessWidget {
  final Widget child;

  const _QueueWidth({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1072,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _QueueSummary extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final bool compact;

  const _QueueSummary({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: TarumtColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$value ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TarumtColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: TarumtColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueSelect<T> extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const _QueueSelect({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: fieldKey,
          value: value,
          isExpanded: true,
          isDense: true,
          itemHeight: null,
          items: items,
          selectedItemBuilder: (context) {
            return [
              for (final item in items)
                Align(
                  alignment: Alignment.centerLeft,
                  child: DefaultTextStyle.merge(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: item.child,
                  ),
                ),
            ];
          },
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _RequestCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(
      TimeOfDay.fromDateTime(report.createdAt),
      alwaysUse24HourFormat: true,
    );

    final urgencyColor = switch (report.urgency) {
      Urgency.high => TarumtColors.accent,
      Urgency.medium => TarumtColors.warning,
      Urgency.low => TarumtColors.success,
    };

    return Semantics(
      button: true,
      label: 'Review request ${report.id}',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment:
              WrapCrossAlignment.center,
              children: [
                Text(
                  report.id,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                StatusChip(
                  _queueStatusLabel(report.status),
                  color: report.status.color,
                  background: report.status.tint,
                  icon: report.status.icon,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                IconBadge(
                  report.icon,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _RequestDetail(
              Icons.location_on_outlined,
              report.location,
            ),

            if (report.equipmentId.isNotEmpty)
              _RequestDetail(
                Icons.qr_code_rounded,
                report.equipmentId,
              ),

            _RequestDetail(
              Icons.schedule_rounded,
              'Submitted ${report.dateLabel} · $time',
            ),

            _RequestDetail(
              Icons.person_outline_rounded,
              report.reporterEmail,
            ),

            const SizedBox(height: 6),

            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (report.coordinatorPriority != null) ...[
              const SizedBox(height: 8),
              Text(
                'Priority: '
                    '${report.coordinatorPriority!.label} · '
                    '${report.estimatedMinutes} min estimate',
              ),
            ],

            if (report.workOrderId != null)
              Text(
                'Work order: ${report.workOrderId}',
              ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment:
              WrapCrossAlignment.center,
              children: [
                Text(
                  'Reported urgency: '
                      '${report.urgency.label}',
                  style: TextStyle(
                    color: urgencyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (report.hasPhoto)
                  const Text(
                    'Photo attached',
                    style: TextStyle(
                      color: TarumtColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Review request',
                    style: TextStyle(
                      color: TarumtColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: TarumtColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RequestDetail(
      this.icon,
      this.text,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: TarumtColors.muted,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: TarumtColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}