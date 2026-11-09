import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/card/presentation/providers/card_provider.dart';
import 'package:ride_app/features/card/presentation/states/card_state.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_scaffold.dart';
import 'package:ride_app/shared/widgets/loader.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final cardFieldController = CardFormEditController();
  final CustomLoader loader = CustomLoader();

  @override
  void dispose() {
    cardFieldController.dispose();
    super.dispose();
  }

  void handleAddCard() async {
    final controller = ref.read(paymentProvider.notifier);
    final cardDetails = cardFieldController.details;

    await controller.createPaymentMethod(cardDetails);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentProvider, (previous, next) {
      if (next.status == PaymentStatus.loading) {
        loader.showLoader(context);
        return;
      } else {
        loader.hideLoader();
      }

      if (next.status == PaymentStatus.error) {
        context.showErrorToast(next.message ?? "");
        return;
      }

      if (next.action == PaymentAction.createPaymentMethod &&
          next.status == PaymentStatus.success) {
        final paymentMethodId = next.paymentMethodId;
        if (paymentMethodId != null) {
          ref.read(paymentProvider.notifier).addCard(paymentMethodId);
        }
      }

      if (next.action == PaymentAction.addCard &&
          next.status == PaymentStatus.success) {
        context.showToast(context.l10n.cardAddedSuccessfully);
        Navigator.pop(context, true);
      }
    });

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: AppBar(title: Text(context.l10n.add_card)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CardFormField(
                controller: cardFieldController,
                style: CardFormStyle(
                  borderColor: Colors.grey,
                  borderWidth: 1,
                  // cursorColor: Colors.white,
                  backgroundColor: isDarkMode
                      ? ((Platform.isIOS)
                            ? AppColors.brand
                            : Colors.transparent)
                      : Colors.white,
                  textColor: isDarkMode ? Colors.white : Colors.black,
                  placeholderColor: Colors.grey,

                  borderRadius: 12,
                ),
                countryCode: 'US',
              ),
              const Gap(24),
              AppButton(text: context.l10n.add_card, onPressed: handleAddCard),
            ],
          ),
        ),
      ),
    );
  }
}
