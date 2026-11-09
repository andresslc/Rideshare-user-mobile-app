import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

import '../../../core/extensions/context_extension.dart';
import '../enums/ride_enum.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10 = context.l10n;

    return Row(
      children: [
        _PaymentOption(
          label: l10.attached_cards,
          value: PaymentMethod.attached_card,
          groupValue: selected,
          onChanged: onChanged,
        ),
        const SizedBox(width: 32),
        _PaymentOption(
          label: l10.wallet,
          value: PaymentMethod.wallet,
          groupValue: selected,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final PaymentMethod value;
  final PaymentMethod groupValue;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  bool get isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CustomTap(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            width: context.screenWidth * 0.056,
            height: context.screenWidth * 0.056,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.brand, width: 1.4),
            ),
            child: isSelected
                ? Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.brand,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(label, style: context.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
