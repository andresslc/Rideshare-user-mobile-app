import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ride_app/core/core.dart';

/// Themed Cupertino DOB picker; [maximumDate] is today (no future dates).
/// Returns a normalized local calendar [DateTime], or `null` if cancelled.
Future<DateTime?> showDateOfBirthPickerSheet(
  BuildContext context, {
  DateTime? selectedDate,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final minDate = DateTime(now.year - 120, 1, 1);
  DateTime rolling =
      selectedDate ?? DateTime(now.year - 25, now.month, now.day);
  if (rolling.isAfter(today)) rolling = today;
  if (rolling.isBefore(minDate)) rolling = minDate;

  return showCupertinoModalPopup<DateTime?>(
    context: context,
    builder: (BuildContext modalContext) {
      final colors = modalContext.appColors;
      final l10n = modalContext.l10n;
      final brightness = Theme.of(modalContext).brightness;
      DateTime picked = rolling;

      return Material(
        color: colors.surface,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 280,
            child: Column(
              children: [
                Container(
                  color: colors.fieldFill,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () =>
                            Navigator.of(modalContext).pop(null),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () {
                          final d = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                          Navigator.of(modalContext).pop<DateTime?>(d);
                        },
                        child: Text(
                          l10n.done,
                          style: TextStyle(
                            color: colors.link,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: brightness,
                      primaryColor: colors.brand,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: rolling,
                      minimumDate: minDate,
                      maximumDate: today,
                      onDateTimeChanged: (DateTime value) => picked = value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
