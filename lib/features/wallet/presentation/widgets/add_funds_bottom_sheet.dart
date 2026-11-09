import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/core/navigation/routes.dart';
import 'package:ride_app/core/utils/stripe_helper.dart';
import 'package:ride_app/core/utils/validators.dart';
import 'package:ride_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:ride_app/shared/entities/card_entity.dart';
import 'package:ride_app/shared/screens/success_screen.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_text_field.dart';

import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/bottom_sheets/draggable_sheet_widget.dart';

class AddFundsBottomSheet extends ConsumerStatefulWidget {
  const AddFundsBottomSheet({super.key});

  @override
  ConsumerState<AddFundsBottomSheet> createState() =>
      _AddFundsBottomSheetState();
}

class _AddFundsBottomSheetState extends ConsumerState<AddFundsBottomSheet> {
  static const int _amountMaxLength = 10;
  static const double _maxAddFundsAmount = 10000;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  BankCardEntity? _selectedCard;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(walletProvider.notifier).fetchCards());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addFunds(double balance) async {
    if (_selectedCard == null) {
      context.showErrorToast(context.l10n.please_select_a_card);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(_amountController.text);
    final result = await ref
        .read(walletProvider.notifier)
        .addFunds(amount: amount!, cardId: _selectedCard!.id!);

    if (result == null) return;

    if (result.requiresAction) {
      final String? clientSecret = result.clientSecret;
      final String? paymentMethodId = _selectedCard?.paymentMethodId;
      if (clientSecret == null || clientSecret.isEmpty) {
        if (mounted) {
          context.showErrorToast(context.l10n.threeDSMissingClientSecret);
        }
        return;
      }
      if (paymentMethodId == null || paymentMethodId.isEmpty) {
        if (mounted) {
          context.showErrorToast(context.l10n.threeDSMissingPaymentMethod);
        }
        return;
      }

      String? failureMessage;
      await StripeHelper.confirmWalletTopUp(
        clientSecret: clientSecret,
        paymentMethodId: paymentMethodId,
        onSuccess: () async {
          await ref
              .read(walletProvider.notifier)
              .fetchTransactionHistory(refresh: true);
        },
        onFailure: (String error) {
          failureMessage = error;
        },
      );

      if (failureMessage != null) {
        if (mounted) {
          context.showErrorToast(
            failureMessage ?? context.l10n.threeDSVerificationFailed,
          );
        }
        return;
      }
    }

    if (mounted) {
      context.pop();
      context.pushNamed(
        Routes.success.name,
        extra: const SuccessArgs(
          type: SuccessType.fundsAdded,
          usePopOnRedirect: true,
        ),
      );
    }
  }

  String? _validateAmount(String? value) {
    final baseValidation = Validators.amountValidator(value);
    if (baseValidation != null) return baseValidation;

    final amount = double.tryParse(value?.trim() ?? '');
    if (amount != null && amount > _maxAddFundsAmount) {
      return 'Maximum amount is \$10,000';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final bool hasCards = state.cards.isNotEmpty;

    return DraggableSheetWidget(
      sizeToContent: true,
      isButtonAvailable: false,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.add_funds,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            Text(
              context.l10n.attached_cards,
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSizes.p8),
            if (state.isFetchingCards)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.cards.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.no_cards_available,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  AppButton(
                    text: context.l10n.addCard,
                    onPressed: () {
                      context.pop();
                      context.pushNamed(Routes.addCard.name);
                    },
                  ),
                ],
              )
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.cards.length,
                  separatorBuilder: (context, index) => const Gap(AppSizes.p12),
                  itemBuilder: (context, index) {
                    final card = state.cards[index];
                    final isSelected = _selectedCard?.id == card.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCard = card),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(AppSizes.p12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              // ignore: deprecated_member_use
                              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppSizes.p12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.brand?.toUpperCase() ??
                                  context.l10n.card_label.toUpperCase(),
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Gap(AppSizes.p4),
                            Text(
                              context.l10n.masked_card_number(
                                card.last4 ?? '----',
                              ),
                              style: textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (hasCards) ...[
              Divider(color: context.colorScheme.outline),

              /// Balance
              Row(
                children: [
                  Text(
                    context.l10n.available_balance,
                    style: context.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    "\$${state.balance.toStringAsFixed(2)}",
                    style: context.textTheme.titleSmall,
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.p20),
              Text(
                context.l10n.enter_amount,
                style: context.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.p8),
              AppTextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                hintText: context.l10n.enter_amount,
                maxLength: _amountMaxLength,
                inputFormatters: const [
                  _MaxAmountInputFormatter(maxAmount: _maxAddFundsAmount),
                ],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: AppSizes.p16),
              AppButton(
                text: context.l10n.add_funds,
                isDisable: state.isFetchingCards || state.isAddingFunds,
                onPressed: state.isFetchingCards || state.isAddingFunds
                    ? null
                    : () => _addFunds(state.balance),
                child: state.isAddingFunds
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showAddFundsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddFundsBottomSheet(),
  );
}

class _MaxAmountInputFormatter extends TextInputFormatter {
  const _MaxAmountInputFormatter({required this.maxAmount});

  final double maxAmount;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.trim();

    if (text.isEmpty) return newValue;

    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(text)) {
      return oldValue;
    }

    final amount = double.tryParse(text);
    if (amount == null || amount > maxAmount) {
      return oldValue;
    }

    return newValue;
  }
}
