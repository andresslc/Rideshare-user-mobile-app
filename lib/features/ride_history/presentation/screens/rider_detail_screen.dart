import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ride_app/core/constants/app_colors.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/extensions/date_extension.dart';
import 'package:ride_app/features/ride_history/presentation/states/ride_history_states.dart';
import 'package:ride_app/features/ride_history/presentation/widgets/review_widget.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../core/extensions/string_extension.dart';
import '../../../../core/extensions/theme_extension.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/params/feedback_params.dart';
import '../../../../core/params/ride_history_detail_params.dart';
import '../../../../shared/screens/success_screen.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_gradient_box.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/widgets/ride_driver_info.dart';
import '../../../../shared/widgets/special_request_widget.dart'
    show SpecialRequest;
import '../../../../shared/widgets/verticle_location_stepper.dart';
import '../../../reviews/presentation/providers/feedback_provider.dart';
import '../../../reviews/presentation/states/feedback_state.dart';
import '../../domain/enitities/ride_history_detail_entities.dart';
import '../providers/ride_history_provider.dart';

class RiderDetailScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String driverId;
  final String rideLabel;
  final String? specialRequest;
  final String? cancellationReason;
  final String? cancelledBy;
  final String? rideStatus;

  const RiderDetailScreen({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.rideLabel,
    this.specialRequest,
    this.cancellationReason,
    this.cancelledBy,
    this.rideStatus,
  });

  @override
  ConsumerState<RiderDetailScreen> createState() => _RiderDetailScreenState();
}

class _RiderDetailScreenState extends ConsumerState<RiderDetailScreen> {
  final TextEditingController reviewController = TextEditingController();
  final CustomLoader loader = CustomLoader();

  int rating = 0;

  @override
  void initState() {
    super.initState();

    /// Screen open hote hi ride detail API hit hogi
    Future.microtask(() {
      ref
          .read(rideDetailProvider.notifier)
          .fetchRideDetail(RideHistoryDetailParams(id: widget.rideId));
    });
  }

  String formatTime(DateTime date) {
    return DateFormat('h:mm a', 'en').format(date.toLocal());
  }

  void submitmethod() {
    final l10n = context.l10n;
    final state = ref.read(rideDetailProvider);

    if (state is! RideDetailSuccess) {
      context.showToast(l10n.somethingWentWrong);
      return;
    }

    final ride = state.ride;
    final receiverId = ride.driver.id;
    const receiverType = "Driver";

    if (receiverId.trim().isEmpty || widget.rideId.trim().isEmpty) {
      context.showToast(l10n.somethingWentWrong);
      return;
    }

    if (rating == 0) {
      context.showToast(l10n.please_select_rating);
      return;
    }

    if (reviewController.text.trim().isEmpty) {
      context.showToast(l10n.description_valid);
      return;
    }
    final param = FeedbackParam(
      receiverId: receiverId,
      receiverType: receiverType,
      stars: rating,
      description: reviewController.text.trim(),
      rideId: widget.rideId,
    );

    ref.read(feedbackProvider.notifier).submitFeedback(param);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideDetailProvider);
    final l10n = context.l10n;

    ref.listen<FeedbackState>(feedbackProvider, (previous, next) {
      if (next is FeedbackLoading) {
        loader.showLoader(context);
      } else if (next is FeedbackError) {
        loader.hideLoader();
        context.showToast(next.message);
      } else if (next is FeedbackSuccess) {
        loader.hideLoader();
        context.goNamed(
          Routes.success.name,
          extra: SuccessArgs(
            type: SuccessType.feedbackSubmitted,
            redirectRouteName: Routes.home.name,
          ),
        );
      }
    });

    return AppScaffold(
      padding: EdgeInsets.zero,
      scrollable: false,
      appBar: AppBar(
        title: Text(widget.rideLabel, style: context.textTheme.titleMedium)
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
        centerTitle: true,
      ),

      child: Builder(
        builder: (_) {
          /// Loading
          if (state is RideHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          /// Error
          if (state is RideHistoryError) {
            return Center(child: Text(state.message));
          }

          /// Success
          if (state is RideDetailSuccess) {
            final ride = state.ride;
            final currentUserId = ride.user.id;
            ReviewHistoryEntity? myReview;
            for (final review in ride.reviews) {
              final isUserReview =
                  review.reviewer == currentUserId ||
                  review.reviewerType.toLowerCase() == 'user';
              if (isUserReview) {
                myReview = review;
                break;
              }
            }
            final hasMyReview = myReview != null;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Driver Info
                    DriverInfoSection(
                      driverId: ride.driver.id,
                      profileImage: ride.driver.profilePicture,
                      userName: ride.driver.fullName.titleCase,
                      rating: ride.driver.rating,
                      carImage: AppImages.sedan,
                      carMake:
                          "${ride.driver.vehicleDetails.make} ${ride.driver.vehicleDetails.vehicleType}",
                      plateNo:
                          "${ride.driver.vehicleDetails.licensePlateNumber}-${ride.driver.vehicleDetails.model}",
                      showTopBorder: false,
                      showCarInfo: true,
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                    const Gap(AppSizes.p12),

                    /// Ride Details
                    PlainBackgroundWidget(
                      isAllRounded: true,

                      isPlain: Theme.of(context).brightness == Brightness.dark,
                      padding: const EdgeInsets.all(16),
                      radius: 12,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.rideDetails,
                            style: context.textTheme.headlineMedium,
                          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                          const Gap(AppSizes.p8),

                          /// Pickup & Drop
                          VerticleLocationStepper(
                            locationList: [
                              ride.pickupPoint.placeName,
                              ride.dropOffPointRequested.placeName,
                            ],
                            startTime: formatTime(ride.createdAt),
                            endTime: formatTime(ride.updatedAt),
                          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15),

                          const Gap(AppSizes.p12),

                          /// Special Request
                          if (widget.specialRequest != null &&
                              widget.specialRequest!.isNotEmpty)
                            Column(
                              children: [
                                SpecialRequest(
                                  title: l10n.special_request,
                                  description: widget.specialRequest!,
                                ),
                                const Gap(AppSizes.p12),
                              ],
                            ),

                          /// Payment Label
                          Text(
                            l10n.paymentMethod,
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

                          const Gap(AppSizes.p8),

                          SizedBox(
                            width: double.infinity,
                            child: AppGradientBox(
                              isPlain:
                                  Theme.of(context).brightness ==
                                  Brightness.light,
                              cornerRadius: 12,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ///  TEXT
                                    Text(
                                      (ride.paymentMethod == "attached_card" &&
                                              (ride
                                                  .transaction
                                                  .card
                                                  .last4
                                                  .isNotEmpty))
                                          ? "*** *** **${ride.transaction.card.last4}"
                                          : (ride.paymentMethod ==
                                                "attached_card")
                                          ? context.l10n.via_card
                                          : context.l10n.via_wallet,
                                      style: context.textTheme.bodyMedium,
                                    ),

                                    ///  ICON
                                    Image.asset(
                                      (ride.paymentMethod == "attached_card")
                                          ? AppIcons.creditcard
                                          : AppIcons.wallet,
                                      height: 25,
                                      width: 25,
                                      color:
                                          (ride.paymentMethod ==
                                              "attached_card")
                                          ? null
                                          : Theme.of(context).brightness ==
                                                Brightness.dark
                                          ? Colors.white
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                          const Gap(8),

                          /// Ride Stats
                          RideStatsRow(
                            totalTime: (ride.averageTime).formatAvgTime(
                              context,
                            ),
                            totalDistance:
                                "${ride.rideDistance.toStringAsFixed(2)} ${l10n.miles}",
                            estimateFare:
                                "\$${ride.rideFare.toStringAsFixed(2)}",
                          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.15),

                          const Gap(AppSizes.p12),

                          /// Review Section
                          if (ride.rideStatus == "completed") ...[
                            if (hasMyReview)
                              ReviewWidget(
                                reviewText: myReview.description,
                                rating: myReview.stars,
                              )
                            else
                              Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.review,
                                        style: context.textTheme.titleSmall,
                                      ),

                                      const Gap(10),

                                      AppGradientBox(
                                        isPlain:
                                            Theme.of(context).brightness ==
                                            Brightness.light,
                                        cornerRadius: 12,
                                        padding: const EdgeInsets.all(8),

                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RatingBar.builder(
                                              initialRating: rating.toDouble(),
                                              minRating: 1,
                                              allowHalfRating: false,
                                              itemCount: 5,
                                              itemSize: 25,
                                              itemBuilder: (context, _) =>
                                                  const Icon(
                                                    Icons.star_rounded,
                                                    color: AppColors.star,
                                                  ),
                                              onRatingUpdate: (value) {
                                                setState(() {
                                                  rating = value.toInt();
                                                });
                                              },
                                            ),
                                            TextField(
                                              controller: reviewController,
                                              maxLines: 4,
                                              maxLength: 200,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              decoration: InputDecoration(
                                                hintText: l10n.addReviewHere,
                                                border: InputBorder.none,
                                                counterText: '',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Gap(8),

                                      AppButton(
                                        text: l10n.submitReview,
                                        onPressed: submitmethod,
                                      ),
                                    ],
                                  )
                                  .animate()
                                  .fadeIn(delay: 300.ms)
                                  .slideY(begin: 0.2),
                          ],
                        ],
                      ),
                    ),

                    const Gap(8),

                    /// Cancellation Reason
                    if (ride.rideStatus == 'cancelled' &&
                        widget.cancellationReason != null &&
                        widget.cancellationReason!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cancellationReason,
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Gap(6),

                          SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.15,
                            child: AppGradientBox(
                              cornerRadius: 8,
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                widget.cancellationReason ??
                                    l10n.noReasonProvided,
                              ),
                            ),
                          ),

                          const Gap(AppSizes.p12),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
