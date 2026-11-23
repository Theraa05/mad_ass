import '../models/report.dart';
import '../models/work_order.dart';

class RepairScheduler {
  static DateTime day(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  static DateTime ceilSlot(DateTime value) {
    final local = value.toLocal();
    var minutes = local.hour * 60 + local.minute;

    if (local.second != 0 ||
        local.millisecond != 0 ||
        local.microsecond != 0) {
      minutes++;
    }

    return DateTime(
      local.year,
      local.month,
      local.day,
      0,
      ((minutes + 14) ~/ 15) * 15,
    );
  }

  static bool validBlock(RepairBlock block) {
    final start = block.start.toLocal();
    final end = block.end.toLocal();

    if (start.weekday > DateTime.friday ||
        day(start) != day(end) ||
        !end.isAfter(start) ||
        start.minute % 15 != 0 ||
        end.minute % 15 != 0 ||
        start.second != 0 ||
        end.second != 0 ||
        start.millisecond != 0 ||
        end.millisecond != 0 ||
        start.microsecond != 0 ||
        end.microsecond != 0) {
      return false;
    }

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return (startMinutes >= 540 && endMinutes <= 780) ||
        (startMinutes >= 840 && endMinutes <= 1020);
  }

  static List<PlannedAssignment> plan({
    required List<Report> requests,
    required List<RepairBlock> booked,
    required DateTime fromDate,
    required DateTime now,
  }) {
    if (requests.any(
          (report) =>
      report.coordinatorPriority == null ||
          report.estimatedMinutes == null ||
          report.estimatedMinutes! < 15 ||
          report.estimatedMinutes! > 480 ||
          report.estimatedMinutes! % 15 != 0,
    )) {
      throw ArgumentError(
        'Every request needs a valid saved priority/estimate.',
      );
    }

    if (requests.map((r) => r.id).toSet().length !=
        requests.length) {
      throw ArgumentError(
        'Duplicate requests are not allowed.',
      );
    }

    final ordered = [...requests]
      ..sort((a, b) {
        // High before Medium before Low.
        final priority = b.coordinatorPriority!.index.compareTo(
          a.coordinatorPriority!.index,
        );

        if (priority != 0) return priority;

        // FIFO within the same priority.
        final submitted = a.createdAt.compareTo(b.createdAt);

        if (submitted != 0) return submitted;

        return a.id.compareTo(b.id);
      });

    final selectedDay = day(fromDate);
    final nextSlot = ceilSlot(now);

    final anchor = selectedDay.isAfter(nextSlot)
        ? selectedDay
        : nextSlot;

    final occupied = [...booked];
    final result = <PlannedAssignment>[];

    for (final report in ordered) {
      final blocks = _allocate(
        report.estimatedMinutes!,
        anchor,
        occupied,
      );

      occupied.addAll(blocks);

      result.add(
        PlannedAssignment(
          reportId: report.id,
          priority: report.coordinatorPriority!,
          estimatedMinutes: report.estimatedMinutes!,
          submittedAt: report.createdAt,
          blocks: blocks,
        ),
      );
    }

    return result;
  }

  static List<RepairBlock> blocksFrom({
    required int minutes,
    required DateTime start,
    required List<RepairBlock> booked,
  }) {
    if (minutes < 15 ||
        minutes > 480 ||
        minutes % 15 != 0) {
      throw ArgumentError(
        'Use 15–480 minutes, in 15-minute steps.',
      );
    }

    final local = start.toLocal();

    final firstSlot = RepairBlock(
      local,
      local.add(
        const Duration(minutes: 15),
      ),
    );

    if (!validBlock(firstSlot)) {
      throw ArgumentError(
        'Choose a weekday start time within working hours, '
            'in 15-minute steps.',
      );
    }

    final blocks = _allocate(
      minutes,
      local,
      booked,
    );

    if (blocks.first.start != local) {
      throw StateError(
        'The technician or equipment is busy '
            'at that start time.',
      );
    }

    return List.unmodifiable(blocks);
  }


  static List<RepairBlock> _allocate(
      int requiredMinutes,
      DateTime anchor,
      List<RepairBlock> occupied,
      ) {
    var remaining = requiredMinutes;
    final result = <RepairBlock>[];

    final sorted = [...occupied]
      ..sort((a, b) => a.start.compareTo(b.start));

    var date = day(anchor);

    for (var days = 0; days < 90; days++) {
      if (date.weekday <= DateTime.friday) {
        // Morning: 09:00–13:00
        // Afternoon: 14:00–17:00
        for (final hours in [(9, 13), (14, 17)]) {
          final start = DateTime(
            date.year,
            date.month,
            date.day,
            hours.$1,
          );

          final end = DateTime(
            date.year,
            date.month,
            date.day,
            hours.$2,
          );

          var cursor = anchor.isAfter(start) ? anchor : start;

          void reserveUntil(DateTime limit) {
            final available =
                limit.difference(cursor).inMinutes ~/ 15 * 15;

            if (available <= 0 || remaining <= 0) return;

            final take = available < remaining
                ? available
                : remaining;

            final finish = cursor.add(
              Duration(minutes: take),
            );

            result.add(RepairBlock(cursor, finish));
            cursor = finish;
            remaining -= take;
          }

          if (!cursor.isBefore(end)) continue;

          for (final busy in sorted) {
            if (!busy.end.isAfter(cursor)) continue;
            if (!busy.start.isBefore(end)) break;

            if (busy.start.isAfter(cursor)) {
              reserveUntil(busy.start);
            }

            if (remaining == 0) return result;

            if (busy.end.isAfter(cursor)) {
              cursor = ceilSlot(busy.end);
            }

            if (!cursor.isBefore(end)) break;
          }

          if (cursor.isBefore(end)) {
            reserveUntil(end);
          }

          if (remaining == 0) return result;
        }
      }

      date = DateTime(
        date.year,
        date.month,
        date.day + 1,
      );
    }

    throw StateError(
      'No capacity within 90 days. '
          'Choose another technician/date.',
    );
  }
}