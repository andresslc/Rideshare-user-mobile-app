import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/card/presentation/providers/card_provider.dart';
import 'package:ride_app/features/card/presentation/states/card_state.dart';
import 'package:ride_app/features/card/presentation/widgets/card_widget.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/loader.dart';

class CardListScreen extends ConsumerStatefulWidget {
  const CardListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CardListScreenState();
}

class _CardListScreenState extends ConsumerState<CardListScreen> {
  final CustomLoader loader = CustomLoader();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(paymentProvider.notifier).getCards());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(paymentProvider);

    // Side effects listener
    ref.listen<PaymentState>(paymentProvider, (previous, next) {
      if (next.status == PaymentStatus.loading) {
        loader.showLoader(context);
      } else {
        loader.hideLoader();
      }

      if (next.status == PaymentStatus.error) {
        context.showErrorToast(next.message ?? l10n.somethingWentWrong);
      }

      if (next.action == PaymentAction.deleteCard &&
          next.status == PaymentStatus.success) {
        context.showToast(l10n.cardDeletedSuccessfully);
      }

      if (next.action == PaymentAction.addCard &&
          next.status == PaymentStatus.success) {
        context.showToast(l10n.cardAddedSuccessfully);
      }

      if (next.action == PaymentAction.setDefaultCard &&
          next.status == PaymentStatus.success) {
        context.showToast(l10n.defaultCardUpdated);
      }
    });

    final cards = state.cards;

    return AppScaffold(
      scrollable: false,
      appBar: AppBar(title: Text(l10n.payment_method), centerTitle: true),
      floatingActionButton: cards.isEmpty
          ? FloatingActionButton(
              backgroundColor: context.appColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              onPressed: () => context.pushNamed(Routes.addCard.name),
              tooltip: l10n.addCard,
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: cards.isEmpty
          ? Center(child: Text(l10n.noCardsFound))
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(paymentProvider.notifier).getCards();
              },
              child: ListView.builder(
                itemCount: cards.length + 1,
                itemBuilder: (context, index) {
                  if (index == cards.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: GestureDetector(
                        onTap: () => context.pushNamed(Routes.addCard.name),
                        child: Text(
                          "+ ${l10n.attachAnotherCard}",
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.appColors.brand,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    );
                  }

                  final card = cards[index];

                  return CardWidget(
                    card: card,
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => GradientSideDialog(
                          title: l10n.delete_card,
                          subtitle: l10n.delete_card_confirmation,
                          icon: Icons.warning,
                          iconColor: context.appColors.error,
                          buttons: [
                            AppButton(
                              text: l10n.cancel,
                              backgroundColor: context.appColors.lightButton,
                              fontColor: context.brightness == Brightness.light
                                  ? context.appColors.textPrimary
                                  : context.appColors.brand,

                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                            ),
                            AppButton(
                              text: l10n.confirm,
                              fontColor: AppColors.darkBackground,
                              backgroundColor: context.appColors.brand,
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref
                            .read(paymentProvider.notifier)
                            .deleteCard(card.id ?? "");
                      }
                    },

                    onTap: () async {
                      await ref
                          .read(paymentProvider.notifier)
                          .setDefaultCard(card.id ?? "");
                    },
                  );
                },
              ),
            ),
    );
  }
}
