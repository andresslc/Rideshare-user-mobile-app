import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/l10n/current_app_localizations.dart';
import 'package:ride_app/core/params/card_params.dart';
import 'package:ride_app/features/card/domain/usecase/add_card_usecase.dart';
import 'package:ride_app/features/card/domain/usecase/delete_card_usecase.dart';
import 'package:ride_app/features/card/domain/usecase/get_card_usecase.dart';
import 'package:ride_app/features/card/domain/usecase/set_default_card_usecase.dart';
import 'package:ride_app/features/card/presentation/states/card_state.dart';

final paymentProvider = NotifierProvider<PaymentController, PaymentState>(
  PaymentController.new,
);

class PaymentController extends Notifier<PaymentState> {
  late AddCardUsecase _addCard;
  late CardListUsecase _getCards;
  late SetDefaultCardUsecase _setDefaultCard;
  late DeleteCardUsecase _deleteCard;

  @override
  PaymentState build() {
    _addCard = locator<AddCardUsecase>();
    _getCards = locator<CardListUsecase>();
    _setDefaultCard = locator<SetDefaultCardUsecase>();
    _deleteCard = locator<DeleteCardUsecase>();

    return const PaymentState();
  }

  /// ------------------------------
  /// CREATE STRIPE PAYMENT METHOD
  /// ------------------------------
  Future<void> createPaymentMethod(CardFieldInputDetails cardDetails) async {
    if (!cardDetails.complete) {
      state = state.copyWith(
        status: PaymentStatus.error,
        action: PaymentAction.createPaymentMethod,
        message: currentAppLocalizations().card_details_incomplete,
      );
      return;
    }

    state = state.copyWith(
      status: PaymentStatus.loading,
      action: PaymentAction.createPaymentMethod,
    );

    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      state = state.copyWith(
        status: PaymentStatus.success,
        paymentMethodId: paymentMethod.id,
      );
    } catch (e) {
      state = state.copyWith(
        status: PaymentStatus.error,
        message: e.toString(),
      );
    }
  }

  /// ------------------------------
  /// GET ALL CARDS
  /// ------------------------------
  Future<void> getCards() async {
    state = state.copyWith(
      status: PaymentStatus.loading,
      action: PaymentAction.getCards,
    );

    final result = await _getCards();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PaymentStatus.error,
          message: failure.message,
        );
      },
      (cardsResponse) {
        state = state.copyWith(
          status: PaymentStatus.success,
          cards: cardsResponse.cards,
        );
      },
    );
  }

  /// ------------------------------
  /// ADD CARD
  /// ------------------------------
  Future<void> addCard(String paymentMethodId) async {
    state = state.copyWith(
      status: PaymentStatus.loading,
      action: PaymentAction.addCard,
    );

    final result = await _addCard(
      AddCardParams(paymentMethodId: paymentMethodId),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PaymentStatus.error,
          message: failure.message,
        );
      },
      (newCard) {
        final updatedCards = [...state.cards, newCard];

        state = state.copyWith(
          status: PaymentStatus.success,
          cards: updatedCards,
        );
      },
    );
  }

  /// ------------------------------
  /// DELETE CARD
  /// ------------------------------
  Future<void> deleteCard(String cardId) async {
    state = state.copyWith(
      status: PaymentStatus.loading,
      action: PaymentAction.deleteCard,
    );

    final result = await _deleteCard(cardId);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PaymentStatus.error,
          message: failure.message,
        );
      },
      (_) {
        final updatedCards = state.cards.where((e) => e.id != cardId).toList();

        final updatedDefault = state.defaultCard?.id == cardId
            ? null
            : state.defaultCard;

        state = state.copyWith(
          status: PaymentStatus.success,
          cards: updatedCards,
          defaultCard: updatedDefault,
        );
      },
    );
  }

  /// ------------------------------
  /// SET DEFAULT CARD
  /// ------------------------------
  Future<void> setDefaultCard(String cardId) async {
    state = state.copyWith(
      status: PaymentStatus.loading,
      action: PaymentAction.setDefaultCard,
    );

    final result = await _setDefaultCard(cardId);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: PaymentStatus.error,
          message: failure.message,
        );
      },
      (updatedCard) {
        state = state.copyWith(
          status: PaymentStatus.success,
          defaultCard: updatedCard,
        );
        getCards();
      },
    );
  }
}
