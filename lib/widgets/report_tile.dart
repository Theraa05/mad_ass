import 'package:flutter/material.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class ReportStatusChip extends StatelessWidget {
  final ReportStatus status;
  const ReportStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) => StatusChip(
        status.label,
        color: status.color,
        background: status.tint,
        icon: status.icon,
      );
}

/// One report as a card. Used in My Reports, Home and the management list.
class ReportTile extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;
  final bool showReporter;
  const ReportTile(
      {super.key, required this.report, this.onTap, this.showReporter = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(children: [
        IconBadge(report.icon,
            color: TarumtColors.accent, background: TarumtColors.accentTint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(report.id,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                if (report.urgency == Urgency.high) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.flag_rounded,
                      size: 14, color: TarumtColors.accent),
                ],
              ]),
              Text('${report.category} · ${report.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: TarumtColors.muted)),
              if (showReporter)
                Text(report.reporterEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: TarumtColors.muted)),
              Text(report.dateLabel,
                  style: const TextStyle(
                      fontSize: 11, color: TarumtColors.muted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ReportStatusChip(report.status),
      ]),
    );
  }
}
