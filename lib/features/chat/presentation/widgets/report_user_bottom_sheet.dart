import 'package:flutter/material.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/shared.dart';

/// Report reason id and localized label.
class ReportReason {
  const ReportReason(this.id, this.label);
  final String id;
  final String label;
}

void showReportUserBottomSheet(
  BuildContext context, {
  required void Function(String reasonId, String reasonLabel) onSubmit,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReportUserBottomSheetBody(onSubmit: onSubmit),
  );
}

class _ReportUserBottomSheetBody extends StatefulWidget {
  const _ReportUserBottomSheetBody({
    required this.onSubmit,
  });

  final void Function(String reasonId, String reasonLabel) onSubmit;

  @override
  State<_ReportUserBottomSheetBody> createState() =>
      _ReportUserBottomSheetBodyState();
}

class _ReportUserBottomSheetBodyState extends State<_ReportUserBottomSheetBody> {
  String? _selectedId;

  List<ReportReason> _reasons(BuildContext context) {
    final l10n = context.l10n;
    return [
      ReportReason('unprofessional', l10n.report_reason_unprofessional),
      ReportReason('poor_communication', l10n.report_reason_poor_communication),
      ReportReason('fake_account', l10n.report_reason_fake_account),
      ReportReason('harassment', l10n.report_reason_harassment),
      ReportReason('abuse', l10n.report_reason_abuse),
      ReportReason('violation_policies', l10n.report_reason_violation_policies),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final reasons = _reasons(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p16,
            left: AppSizes.p16,
            right: AppSizes.p16,
            top: AppSizes.p20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                ),
              ),
              const SizedBox(height: AppSizes.p20),
              Text(
                context.l10n.report_user,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.p24),
              ...reasons.map((r) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedId = r.id),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusSmall),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: r.id,
                          // ignore: deprecated_member_use
                          groupValue: _selectedId,
                          // ignore: deprecated_member_use
                          onChanged: (v) =>
                              setState(() => _selectedId = v),
                          activeColor: colors.brand,
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return colors.brand;
                            }
                            return colors.border;
                          }),
                        ),
                        Expanded(
                          child: Text(
                            r.label,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSizes.p24),
              AppButton(
                text: context.l10n.submit,
                onPressed: _selectedId == null
                    ? null
                    : () {
                        ReportReason? r;
                        for (final e in reasons) {
                          if (e.id == _selectedId) {
                            r = e;
                            break;
                          }
                        }
                        if (r != null) {
                          Navigator.of(context).pop();
                          widget.onSubmit(r.id, r.label);
                        }
                      },
                isDisable: _selectedId == null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
