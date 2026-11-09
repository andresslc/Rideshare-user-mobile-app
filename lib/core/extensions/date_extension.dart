import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:ride_app/core/extensions/context_extension.dart';

/// Date / DateTime helpers.
extension DateExtension on DateTime {
  /// "Jan 5, 2025"
  String get formatted => DateFormat.yMMMd().format(this);

  /// "3:45 PM"
  String get timeOnly => DateFormat.jm().format(this);

  /// "Jan 5, 2025 at 3:45 PM"
  String get fullFormatted => '$formatted at $timeOnly';

  /// "2 hours ago", "just now", etc.
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatted;
  }
}

extension FormatAvgTimeExtension on num {
  String formatAvgTime(BuildContext context) {
    final totalMinutes = round();

    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    if (hours == 0) {
      return '$mins ${mins == 1 ? context.l10n.min : context.l10n.min}';
    }

    final hourStr = hours == 1 ? context.l10n.hour : context.l10n.hours;
    if (mins == 0) {
      return '$hours $hourStr';
    }

    final minStr = mins == 1 ? context.l10n.min : context.l10n.mins;
    return '$hours $hourStr $mins $minStr';
  }
}

extension RideDateFormatter on DateTime {
  String formatRideDate(BuildContext context) {
    final locale = context.l10n.localeName;

    final localRideDate = toLocal();
    final now = DateTime.now().toLocal();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final rideDay = DateTime(
      localRideDate.year,
      localRideDate.month,
      localRideDate.day,
    );

    /// ✅ Handle AM/PM based on locale
    final isSpanish = locale.startsWith('es');

    final timeFormatter = DateFormat(
      'h:mm a',
      isSpanish ? 'es' : 'en',
    );

    String formattedTime = timeFormatter.format(localRideDate);

    /// Fix spacing for Spanish → "a. m." / "p. m."
    if (isSpanish) {
      formattedTime = formattedTime
          .replaceAll('AM', 'a. m.')
          .replaceAll('PM', 'p. m.')
          .replaceAll('a.m.', 'a. m.')
          .replaceAll('p.m.', 'p. m.');
    }

    if (rideDay == today) {
      return "${context.l10n.ride_date_today}, $formattedTime";
    } else if (rideDay == yesterday) {
      return "${context.l10n.ride_date_yesterday}, $formattedTime";
    } else {
      return "${DateFormat('d MMM', locale).format(localRideDate)}, $formattedTime";
    }
  }
}