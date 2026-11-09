import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/app_config/domain/entities/ride_app_config_entity.dart';
import 'package:ride_app/features/app_config/presentation/providers/ride_app_config_provider.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_status_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_upgrade_entity.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/helpers/ride_cancel_flow_helper.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/features/ride_room/screens/drag_handler.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';

import '../presentation/providers/map_provider.dart';

/// The sheet the rider watches while the backend widens its driver search.
///
/// The search is a ladder of rings (1 → 2 → 3 → 5 miles by default, one every
/// 10 s). Every number on screen comes from `ride:search:status`: the ladder is
/// configured server-side and the app has no endpoint to read it, so nothing
/// here is hardcoded. When the ladder runs out, `ride:search:exhausted` swaps
/// this sheet's body for the "no drivers" panel.
///
/// When the backend offers to search again in a higher category
/// (`ride:upgrade:offer`), the body shows the offer instead. It lives here
/// rather than in a modal so any state change (driver assigned, exhausted,
/// cancel) replaces it without leaving anything open on top.
class FindingRideSheet extends ConsumerStatefulWidget {
  const FindingRideSheet({super.key});

  /// Fraction of the screen the sheet covers when it opens. Public because the
  /// map behind it has to keep its search animation above this line.
  static const double collapsedSize = 0.62;

  /// How far the rider can drag it open.
  static const double expandedSize = 0.95;

  @override
  ConsumerState<FindingRideSheet> createState() => _FindingRideSheetState();
}

class _FindingRideSheetState extends ConsumerState<FindingRideSheet> {
  static const double childSize = FindingRideSheet.collapsedSize;
  static const double expandedChildSize = FindingRideSheet.expandedSize;

  /// Safety net only. The backend ends the search on its own once the ladder
  /// runs out, so reaching this means the event never arrived — a dropped
  /// socket, most likely — and the rider deserves a way out rather than an
  /// endless spinner. Used when the configured length is unknown.
  static const Duration _fallbackSearchWaitLimit = Duration(minutes: 2);

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  Timer? _searchTimeoutTimer;
  Timer? _nextRingTicker;
  int? _secondsToNextRing;
  int? _tickingForRing;
  bool _isDecisionDialogVisible = false;
  bool _isRetrying = false;

  /// Drives the upgrade countdown. The value shown is always recomputed from
  /// the offer's `expiresAt`, so a resumed offer shows the real time left.
  Timer? _offerTicker;
  RideUpgradeOfferEntity? _tickingForOffer;

  @override
  void initState() {
    super.initState();
    final rideState = ref.read(rideRoomProvider);
    if (!_isCarpoolFinding(rideState) && rideState.upgradeOffer == null) {
      _startSearchTimeoutTimer();
    }
  }

  @override
  void dispose() {
    _searchTimeoutTimer?.cancel();
    _nextRingTicker?.cancel();
    _offerTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideRoomProvider);
    final bool isExhausted = rideState.searchExhausted != null;
    final RideUpgradeOfferEntity? offer = isExhausted
        ? null
        : rideState.upgradeOffer;

    // The fallback timer covers a search that went silent. It has nothing to
    // guard while the rider is deciding, and a Luxury search starts its own
    // full ladder, so it pauses on the offer and restarts once it closes.
    ref.listen<bool>(
      rideRoomProvider.select((RideRoomState s) => s.upgradeOffer != null),
      (bool? wasOffering, bool isOffering) {
        if (isOffering) {
          _searchTimeoutTimer?.cancel();
        } else if (wasOffering == true &&
            ref.read(rideRoomProvider).currentRideType == RideType.requested &&
            ref.read(rideRoomProvider).searchExhausted == null) {
          _startSearchTimeoutTimer();
        }
      },
    );

    _syncNextRingCountdown(
      rideState.searchStatus,
      isExhausted: isExhausted || offer != null,
    );
    _syncOfferCountdown(offer);

    // Backing out of the offer is a "no", and has to reach the backend: closing
    // it locally would leave the ride waiting for the server-side timeout.
    return PopScope(
      canPop: offer == null,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop || offer == null) return;
        unawaited(_onUpgradeDecision(offer, RideUpgradeDecision.decline));
      },
      child: _sheet(rideState, isExhausted: isExhausted, offer: offer),
    );
  }

  Widget _sheet(
    RideRoomState rideState, {
    required bool isExhausted,
    required RideUpgradeOfferEntity? offer,
  }) {
    return DraggableScrollableSheet(
      initialChildSize: childSize,
      minChildSize: childSize,
      maxChildSize: expandedChildSize,
      snap: true,
      snapSizes: const [childSize, expandedChildSize],
      controller: _sheetController,
      builder: (context, controller) {
        return PlainBackgroundWidget(
          child: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              children: [
                DragHandlerWidget(
                  controller: _sheetController,
                  minChildSize: childSize,
                  maxChildSize: expandedChildSize,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: AppSizes.p24),
                    controller: controller,
                    children: [
                      if (isExhausted)
                        _exhaustedContent(rideState)
                      else if (offer != null)
                        _offerContent(offer)
                      else
                        _searchingContent(rideState),
                    ],
                  ),
                ),
                Padding(
                  // The top gap keeps the buttons off the last line of text.
                  // The bottom one sits inside SafeArea, which already clears
                  // the system inset, so it does not need kToolbarHeight.
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    AppSizes.p24,
                    16,
                    AppSizes.p24,
                  ),
                  child: isExhausted
                      ? _exhaustedActions()
                      : offer != null
                      ? _offerActions(offer, rideState)
                      : AppButton(
                          text: context.l10n.cancel_ride_request,
                          isDisable: rideState.status == RideRoomStatus.loading,
                          onPressed: () =>
                              _onCancelRideTap(_resolveRideId(rideState)),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- UPGRADE OFFER ----------------

  /// Same building blocks as the other two states: centered title and
  /// message, an [AppGradientBox] card, the ring card's progress bar, and the
  /// app's existing error tint for the warning.
  Widget _offerContent(RideUpgradeOfferEntity offer) {
    final l10 = context.l10n;
    final String fromName = _categoryName(offer.from.category);
    final String toName = _categoryName(offer.to.category);
    // The backend already translated this and filled in the numbers; the
    // panel can rewrite it, so it wins over the app's own sentence.
    final String message = offer.message?.trim().isNotEmpty == true
        ? offer.message!.trim()
        : l10.upgrade_offer_fallback(toName, _formatFare(offer.to.fare));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            _categoryImage(offer.to.category),
            height: 48,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            l10.upgrade_offer_title(fromName),
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            message,
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p24),
          _offerFareCard(offer, fromName: fromName, toName: toName),
          if (offer.dropsPromoCode) ...[
            const SizedBox(height: AppSizes.p12),
            _promoLostWarning(offer, toName),
          ],
          const SizedBox(height: AppSizes.p16),
        ],
      ),
    );
  }

  /// Both prices, because the rider is agreeing to pay more, and the countdown
  /// in the same bar style as the ring progress.
  Widget _offerFareCard(
    RideUpgradeOfferEntity offer, {
    required String fromName,
    required String toName,
  }) {
    final l10 = context.l10n;
    final int secondsLeft = offer.remaining().inSeconds;
    final int window = offer.decisionSeconds > 0
        ? offer.decisionSeconds
        : secondsLeft;

    return AppGradientBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fareRow(
            label: '${l10.upgrade_original_fare} · $fromName',
            fare: offer.from.fare,
            emphasize: false,
          ),
          const SizedBox(height: AppSizes.p12),
          _fareRow(
            label: '${l10.upgrade_new_fare} · $toName',
            fare: offer.to.fare,
            emphasize: true,
          ),
          const SizedBox(height: AppSizes.p16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: window <= 0
                  ? 0
                  : (secondsLeft / window).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.appColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.appColors.brand,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          Text(
            l10.upgrade_seconds_left(secondsLeft),
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _fareRow({
    required String label,
    required double fare,
    required bool emphasize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: emphasize
                ? context.textTheme.titleSmall
                : context.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Text(
          _formatFare(fare),
          style: emphasize
              ? context.textTheme.titleSmall?.copyWith(
                  color: context.appColors.brand,
                )
              : context.textTheme.bodySmall,
        ),
      ],
    );
  }

  /// The rider loses a discount they already applied: shown before they can
  /// accept, in the error tint the notifications screen already uses.
  Widget _promoLostWarning(RideUpgradeOfferEntity offer, String toName) {
    final l10 = context.l10n;
    final colors = context.appColors;
    final double? lost = offer.promoCode?.lostDiscount;
    final String text = (lost != null && lost > 0)
        ? l10.upgrade_promo_lost(toName, _formatFare(lost))
        : l10.upgrade_promo_lost_no_amount(toName);

    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(AppIcons.discount, width: 17, height: 17),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Same slot and order as the "no drivers" actions: primary on top, the
  /// outlined way out below.
  Widget _offerActions(RideUpgradeOfferEntity offer, RideRoomState rideState) {
    final l10 = context.l10n;
    final bool isDeciding = rideState.isDecidingUpgrade;
    final bool isExpired = offer.isExpired();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          text: l10.upgrade_accept(_categoryName(offer.to.category)),
          isLoading: isDeciding,
          isDisable: isDeciding || isExpired,
          onPressed: () => _onUpgradeDecision(offer, RideUpgradeDecision.accept),
        ),
        const SizedBox(height: AppSizes.p12),
        AppButton(
          text: l10.upgrade_decline,
          backgroundColor: Colors.transparent,
          needBorder: true,
          fontColor: context.appColors.brand,
          isDisable: isDeciding || isExpired,
          onPressed: () =>
              _onUpgradeDecision(offer, RideUpgradeDecision.decline),
        ),
      ],
    );
  }

  Future<void> _onUpgradeDecision(
    RideUpgradeOfferEntity offer,
    RideUpgradeDecision decision,
  ) async {
    if (ref.read(rideRoomProvider).isDecidingUpgrade) return;

    final RideUpgradeDecisionEntity? ack = await ref
        .read(rideRoomProvider.notifier)
        .decideUpgrade(decision);
    if (!mounted || ack == null || ack.success) return;

    final l10 = context.l10n;
    final String toName = _categoryName(offer.to.category);
    final String? serverMessage = ack.message?.trim().isNotEmpty == true
        ? ack.message!.trim()
        : null;

    switch (ack.reason) {
      // Already answered, beaten by the countdown, or a driver took the ride:
      // what follows arrives on its own and none of it is the rider's error.
      case RideUpgradeRefusal.offerNotPending:
      case RideUpgradeRefusal.offerExpired:
      case RideUpgradeRefusal.rideAlreadyAccepted:
      case RideUpgradeRefusal.notYourRide:
        return;
      case RideUpgradeRefusal.insufficientWalletBalance:
        context.showErrorToast(
          serverMessage ?? l10.upgrade_insufficient_wallet(toName),
        );
        unawaited(context.pushNamed(Routes.wallet.name));
        return;
      case RideUpgradeRefusal.noActiveCard:
        context.showErrorToast(
          serverMessage ?? l10.upgrade_no_active_card(toName),
        );
        unawaited(context.pushNamed(Routes.addCard.name));
        return;
      default:
        // No reason means the ack never came back (transport error); the
        // offer is still open, so the rider can tap again.
        context.showErrorToast(serverMessage ?? l10.upgrade_decision_failed);
    }
  }

  /// Rebuilds once a second while an offer is on screen. The number itself
  /// always comes from `expiresAt`.
  void _syncOfferCountdown(RideUpgradeOfferEntity? offer) {
    if (offer == null) {
      if (_offerTicker != null) {
        _offerTicker?.cancel();
        _offerTicker = null;
        _tickingForOffer = null;
      }
      return;
    }

    if (identical(_tickingForOffer, offer) && _offerTicker != null) return;

    _tickingForOffer = offer;
    _offerTicker?.cancel();
    _offerTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (offer.isExpired()) timer.cancel();
    });
  }

  String _categoryName(String category) {
    final l10 = context.l10n;
    switch (category.trim().toLowerCase()) {
      case 'economy':
        return l10.ride_type_economy;
      case 'luxury':
        return l10.ride_type_luxury;
      default:
        final String raw = category.trim();
        if (raw.isEmpty) return raw;
        return '${raw[0].toUpperCase()}${raw.substring(1)}';
    }
  }

  String _categoryImage(String category) {
    switch (category.trim().toLowerCase()) {
      case 'economy':
        return AppImages.economy;
      default:
        return AppImages.luxury;
    }
  }

  String _formatFare(num value) => '\$${value.toStringAsFixed(2)}';

  // ---------------- SEARCH IN PROGRESS ----------------

  Widget _searchingContent(RideRoomState rideState) {
    final l10 = context.l10n;
    final bool isCarpoolFinding = _isCarpoolFinding(rideState);
    final RideSearchStatusEntity? search = rideState.searchStatus;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isCarpoolFinding ? 'Finding rides' : l10.finding_driver,
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p24),
          Text(
            isCarpoolFinding
                ? 'Please wait while we find carpool options for you.'
                : _findingDriversMessage(),
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (!isCarpoolFinding && rideState.searchCategory != null) ...[
            const SizedBox(height: AppSizes.p24),
            _searchedRideCard(rideState),
          ],
          if (!isCarpoolFinding && search != null) ...[
            SizedBox(
              height: rideState.searchCategory != null
                  ? AppSizes.p12
                  : AppSizes.p24,
            ),
            _searchProgressCard(search),
          ],
          const SizedBox(height: AppSizes.p16),
        ],
      ),
    );
  }

  /// What is being searched: category and fare. After an accepted upgrade it
  /// also says this is a new search, so the ring counter starting over at 1
  /// reads as intended.
  Widget _searchedRideCard(RideRoomState rideState) {
    final l10 = context.l10n;
    final String category = rideState.searchCategory ?? '';
    final String name = _categoryName(category);
    final num? fare = rideState.searchFare;
    final bool isUpgradedSearch = rideState.upgradedFromCategory != null;

    return AppGradientBox(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset(_categoryImage(category), height: 32, fit: BoxFit.contain),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: context.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isUpgradedSearch) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10.upgrade_new_search(name),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.appColors.brand,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (fare != null && fare > 0) ...[
            const SizedBox(width: AppSizes.p12),
            Text(_formatFare(fare), style: context.textTheme.titleSmall),
          ],
        ],
      ),
    );
  }

  /// Everything in this card is read straight off the last
  /// `ride:search:status`; nothing about the ladder is assumed.
  Widget _searchProgressCard(RideSearchStatusEntity search) {
    final l10 = context.l10n;
    // The event is authoritative; the configuration only fills in what an
    // older backend leaves out.
    final int? totalRings = search.totalRings ?? _configuredTotalRings();
    final int? seconds = _secondsToNextRing;

    return AppGradientBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10.searching_within_distance(
                    _formatDistance(search.radius, search.distanceUnit),
                  ),
                  style: context.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalRings != null)
                Text(
                  l10.search_step_of(search.ring, totalRings),
                  style: context.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              // Without a ring count there is no meaningful fraction to show,
              // so the bar stays indeterminate rather than guessing one.
              value: totalRings == null
                  ? null
                  : (search.ring / totalRings).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.appColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.appColors.brand,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          // A rider staring at a spinner assumes nothing is happening. This
          // line is keyed on the ring, so it visibly swaps every time the
          // search widens.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(
              _stageMessage(search),
              key: ValueKey<int>(search.ring),
              style: context.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          Text(
            l10.drivers_notified_count(search.totalNotified),
            style: context.textTheme.bodySmall,
          ),
          // Nothing widens after the last ring — the search ends there — so the
          // countdown only runs while there is a wider ring still to come.
          // Every ring waits the same ring timeout, the last one included, so
          // the rider always sees how long this wait lasts. The last ring
          // doesn't widen; it closes the search.
          if (seconds != null) ...[
            const SizedBox(height: 4),
            Text(
              _isLastRing(search)
                  ? (seconds > 0
                        ? l10.search_ends_in_seconds(seconds)
                        : l10.search_finishing_now)
                  : (seconds > 0
                        ? l10.expanding_search_in_seconds(seconds)
                        : l10.widening_search_now),
              style: context.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  /// The wording follows the rider's position on the ladder, not a fixed list
  /// of rings: the ladder is configurable, so the message is derived from
  /// `ring` against `totalRings` and works for any shape of it.
  String _stageMessage(RideSearchStatusEntity search) {
    // The panel can rewrite this sentence, so what the backend sends wins over
    // anything the app could compose. The app's own wording is only a fallback
    // for an older backend, or for the first ring, which the request ack
    // reports without a message.
    final String? fromBackend = search.message?.trim();
    if (fromBackend != null && fromBackend.isNotEmpty) return fromBackend;

    final l10 = context.l10n;
    final String distance = _formatDistance(search.radius, search.distanceUnit);

    if (search.ring <= 1) return l10.search_stage_nearby;
    if (_isLastRing(search)) return l10.search_stage_last(distance);
    return l10.search_stage_widened(distance);
  }

  /// Unknown ring count (an older backend, or the request ack, which reports
  /// only the first ring) means we cannot claim this is the last one.
  bool _isLastRing(RideSearchStatusEntity search) {
    final int? totalRings = search.totalRings ?? _configuredTotalRings();
    return totalRings != null && search.ring >= totalRings;
  }

  int? _configuredTotalRings() {
    final int? total = ref.read(rideAppConfigProvider)?.dispatch.totalRings;
    return (total == null || total <= 0) ? null : total;
  }

  /// The request ack reports the first ring without a countdown, so the
  /// configured ring length fills that first gap.
  int? _configuredRingTimeoutSeconds() {
    final int? seconds = ref
        .read(rideAppConfigProvider)
        ?.dispatch
        .ringTimeoutSeconds;
    return (seconds == null || seconds <= 0) ? null : seconds;
  }

  /// Restarts the countdown whenever a new ring arrives, so the number on
  /// screen always belongs to the ring the backend is actually running.
  void _syncNextRingCountdown(
    RideSearchStatusEntity? search, {
    required bool isExhausted,
  }) {
    // The last ring has no "next" ring, so the backend may send 0 or nothing
    // there. It still waits a full ring timeout, which is what gets counted.
    final int? fromEvent = search?.nextRingInSeconds;
    final int? nextRingSeconds = (fromEvent != null && fromEvent > 0)
        ? fromEvent
        : _configuredRingTimeoutSeconds();

    if (search == null || isExhausted || nextRingSeconds == null) {
      if (_nextRingTicker != null) {
        _nextRingTicker?.cancel();
        _nextRingTicker = null;
        _tickingForRing = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _secondsToNextRing = null);
        });
      }
      return;
    }

    if (_tickingForRing == search.ring && _nextRingTicker != null) return;

    _tickingForRing = search.ring;
    _nextRingTicker?.cancel();
    final int start = nextRingSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _secondsToNextRing = start);
    });
    _nextRingTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int current = _secondsToNextRing ?? 0;
      if (current <= 0) {
        timer.cancel();
        return;
      }
      final int next = current - 1;
      setState(() => _secondsToNextRing = next);
      if (next <= 0) {
        timer.cancel();
        if (_isLastRing(search)) _onLastRingCountdownEnded();
      }
    });
  }

  /// The last ring's wait is over, so nobody is going to accept: show the
  /// "no drivers" panel now instead of leaving "Finishing the search..." up
  /// until the backend's exhausted event lands.
  ///
  /// Skipped when the backend may offer an upgrade at this point: closing the
  /// ride locally would cancel it before the offer arrives.
  void _onLastRingCountdownEnded() {
    if (!mounted) return;
    final RideRoomState rideState = ref.read(rideRoomProvider);
    if (_isCarpoolFinding(rideState)) return;
    if (_backendMayOfferUpgrade(rideState)) return;
    unawaited(ref.read(rideRoomProvider.notifier).expireSearchLocally());
  }

  bool _backendMayOfferUpgrade(RideRoomState rideState) {
    // The backend never chains upgrades.
    if (rideState.upgradedFromCategory != null) return false;
    final CategoryUpgradeConfigEntity? upgrade = ref
        .read(rideAppConfigProvider)
        ?.dispatch
        .categoryUpgrade;
    if (upgrade == null || !upgrade.enabled) return false;
    final String category = rideState.searchCategory?.trim().toLowerCase() ?? '';
    return upgrade.map.containsKey(category);
  }

  // ---------------- SEARCH EXHAUSTED ----------------

  Widget _exhaustedContent(RideRoomState rideState) {
    final l10 = context.l10n;
    final exhausted = rideState.searchExhausted!;
    // The backend already translated this message to the rider's language.
    final String message = exhausted.message?.trim().isNotEmpty == true
        ? exhausted.message!.trim()
        : l10.we_could_not_find;
    final double? radius =
        exhausted.radiusReached ?? exhausted.radiusReachedMiles;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(AppIcons.danger, width: 48, height: 48),
          const SizedBox(height: AppSizes.p16),
          Text(
            l10.no_drivers_near_you,
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            message,
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (radius != null && radius > 0) ...[
            const SizedBox(height: AppSizes.p12),
            Text(
              l10.searched_up_to_distance(
                _formatDistance(radius, exhausted.distanceUnit),
              ),
              style: context.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSizes.p16),
        ],
      ),
    );
  }

  Widget _exhaustedActions() {
    final l10 = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          text: l10.request_another_ride,
          isDisable: _isRetrying,
          onPressed: _onRetryTap,
        ),
        const SizedBox(height: AppSizes.p12),
        AppButton(
          text: l10.back_to_home,
          backgroundColor: Colors.transparent,
          needBorder: true,
          fontColor: context.appColors.brand,
          isDisable: _isRetrying,
          onPressed: () {
            ref.read(rideRoomProvider.notifier).dismissSearchExhausted();
          },
        ),
      ],
    );
  }

  Future<void> _onRetryTap() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    await ref.read(rideRoomProvider.notifier).retryLastRideSearch();
    if (!mounted) return;
    setState(() => _isRetrying = false);
    _startSearchTimeoutTimer();
  }

  // ---------------- SHARED ----------------

  bool _isLuxurySearch(RideRoomState rideState) =>
      rideState.searchCategory?.trim().toLowerCase() == 'luxury';

  bool _isCarpoolFinding(RideRoomState rideState) {
    final String id = rideState.rideRequestId?.toLowerCase() ?? '';
    return id.startsWith('carpool-finding');
  }

  /// The unit comes from the backend, already applied to the number. The app
  /// prints both together and converts nothing.
  String _formatDistance(double value, String unit) {
    final String amount = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    final String suffix = unit.trim();
    return suffix.isEmpty ? amount : '$amount $suffix';
  }

  /// The panel owns this sentence too; the app's string is the fallback.
  String _findingDriversMessage() {
    final RideAppConfigEntity? config = ref.read(rideAppConfigProvider);
    return config?.message(RideConfigMessageKeys.findingDrivers) ??
        context.l10n.searching_nearby_drivers;
  }

  Future<void> _onCancelRideTap(String? rideId) async {
    if (!mounted) return;
    await cancelRideWithConfirmation(
      isPendingRequestCancelled: true,
      context: context,
      ref: ref,
      rideId: rideId,
      askCancellationReason: false,
    );
  }

  String? _resolveRideId(RideRoomState rideState) {
    return rideState.rideRequestId ?? rideState.latestRideStatus?.rideId;
  }

  void _startSearchTimeoutTimer() {
    _searchTimeoutTimer?.cancel();
    _searchTimeoutTimer = Timer(_searchWaitLimit(), _showSearchTimeoutDialog);
  }

  /// Twice the configured search length, so the dialog only ever fires when
  /// the backend has clearly stopped talking — never mid-ladder, whatever
  /// shape the panel gives it. With the upgrade on, a search can run two
  /// ladders plus the decision window, and the longer length applies.
  Duration _searchWaitLimit() {
    final int seconds =
        ref.read(rideAppConfigProvider)?.dispatch.effectiveMaxSearchSeconds ??
        0;
    if (seconds <= 0) return _fallbackSearchWaitLimit;
    return Duration(seconds: seconds * 2);
  }

  Future<void> onKeepWaiting(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    _startSearchTimeoutTimer();
  }

  Future<void> onCancel(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    _searchTimeoutTimer?.cancel();
    if (!mounted) return;

    final currentRideState = ref.read(rideRoomProvider);
    final String? rideId = _resolveRideId(currentRideState);

    await ref
        .read(rideRoomProvider.notifier)
        .cancelRide(rideId: rideId, isPendingRequestCancelled: true);
    if (!mounted) return;

    final rideState = ref.read(rideRoomProvider);
    if (rideState.status == RideRoomStatus.error) {
      context.showErrorToast(
        rideState.errorMessage ?? context.l10n.somethingWentWrong,
      );
      _startSearchTimeoutTimer();
      return;
    }

    if (rideState.currentSheet == RideSheetsType.whereToGoSheet) {
      ref.read(mapProvider.notifier).clearRideMapData();
    }
  }

  Future<void> _showSearchTimeoutDialog() async {
    if (!mounted || _isDecisionDialogVisible) return;
    // The backend closes the search itself; if it already did, the exhausted
    // panel is on screen and this dialog would only get in the way.
    if (ref.read(rideRoomProvider).searchExhausted != null) return;
    // The rider is answering an upgrade offer; the search is not stalled.
    if (ref.read(rideRoomProvider).upgradeOffer != null) return;

    // A Luxury search that runs out ends on the same "no drivers" panel the
    // backend's exhausted event shows, not on the keep-waiting dialog.
    if (_isLuxurySearch(ref.read(rideRoomProvider))) {
      await ref.read(rideRoomProvider.notifier).expireSearchLocally();
      return;
    }

    _isDecisionDialogVisible = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,

      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: GradientSideDialog(
            title: context.l10n.no_drivers_available,
            subtitle: context.l10n.we_could_not_find,
            imagePath: AppIcons.danger,
            showCloseIcon: true,
            buttons: [
              AppButton(
                fontColor: context.appColors.brand,
                backgroundColor: context.appColors.border,
                text: context.l10n.cancel_ride,
                onPressed: () => onCancel(dialogContext),
              ),
              AppButton(
                text: context.l10n.keep_waiting,
                onPressed: () => onKeepWaiting(dialogContext),
              ),
            ],
          ),
        );
      },
    );

    _isDecisionDialogVisible = false;
  }
}
