import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_colors.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/navigation/routes.dart';
import 'package:ride_app/core/params/carpool_detail_params.dart';
import 'package:ride_app/core/params/feedback_params.dart';
import 'package:ride_app/features/reviews/presentation/providers/feedback_provider.dart';
import 'package:ride_app/features/reviews/presentation/states/feedback_state.dart';
import 'package:ride_app/features/ride_history/presentation/providers/ride_history_provider.dart';
import 'package:ride_app/features/ride_history/presentation/states/ride_history_states.dart';
import 'package:ride_app/features/ride_history/presentation/widgets/review_widget.dart';
import 'package:ride_app/shared/screens/success_screen.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/app_scaffold.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';
import 'package:ride_app/shared/widgets/verticle_location_stepper.dart';

import '../../../../core/extensions/string_extension.dart';
import '../../../../core/extensions/theme_extension.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/widgets/ride_driver_info.dart';

class RideDetailCarpoolScreen extends ConsumerStatefulWidget {
  final String rideLabel;
  final String carpoolId;
  final String profilepicture;
  final String carImage;
  final String carMake;
  final String plateNo;
  final String time;

  const RideDetailCarpoolScreen({
    super.key,
    required this.rideLabel,
    required this.profilepicture,
    required this.carpoolId,
    required this.carImage,
    required this.carMake,
    required this.plateNo,
    required this.time,
  });

  @override
  ConsumerState<RideDetailCarpoolScreen> createState() =>
      _RideDetailCarpoolScreenState();
}

class _RideDetailCarpoolScreenState
    extends ConsumerState<RideDetailCarpoolScreen> {
  final CustomLoader loader = CustomLoader();
  final TextEditingController reviewController = TextEditingController();
  int rating = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(carpoolDetailProvider.notifier)
          .fetchCarpoolDetail(CarpoolDetailParams(id: widget.carpoolId));
    });
  }

  void submitFeedback(
    String receiverId,
    String receiverType,
    int rating,
    String? description,
  ) {
    final carpoolId = widget.carpoolId;

    if (receiverId.trim().isEmpty || carpoolId.trim().isEmpty) {
      // context.showToast(context.l10n.somethingWentWrong);
      context.showToast(context.l10n.unable_to_submit);

      return;
    }

    if (rating == 0) {
      context.showToast(context.l10n.please_select_rating);
      return;
    }

    if (receiverType == "Driver" &&
        (description == null || description.isEmpty)) {
      context.showToast(context.l10n.description_valid);
      return;
    }

    final param = FeedbackParam(
      receiverId: receiverId,
      receiverType: receiverType,
      stars: rating,
      description: description!.trim(),
      carpoolId: carpoolId,
    );

    ref.read(feedbackProvider.notifier).submitFeedback(param);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carpoolDetailProvider);
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
          if (state is CarpoolDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CarpoolDetailError) {
            return Center(child: Text(state.message));
          }

          if (state is CarpoolDetailSuccess) {
            final carpool = state.carpool;
            final driver = carpool.driver;
            final hasMyReview = carpool.review != null;

            final status = carpool.status.trim().toLowerCase();
            final isCompleted = status == "completed";

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Driver Info
                    DriverInfoSection(
                          driverId: driver.id,
                          profileImage: widget.profilepicture,
                          userName: driver.fullName.titleCase,
                          rating: driver.rating,
                          carImage: AppImages.sedan,
                          carMake: widget.carMake,
                          plateNo: widget.plateNo,
                          showTopBorder: false,
                          showCarInfo: true,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    const Gap(16),

                    /// Ride Details Card
                    PlainBackgroundWidget(
                      isAllRounded: true,
                      radius: 12,
                      isPlain: Theme.of(context).brightness == Brightness.dark,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.rideDetails,
                            style: context.textTheme.headlineMedium,
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15),
                          const Gap(12),

                          /// Stops
                          VerticleLocationStepper(
                            locationList: carpool.stops
                                .map((s) => s.placeName)
                                .toList(),
                            startTime: l10n.start_label,
                            endTime: l10n.end_label,
                          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15),

                          const Gap(10),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: context.appColors.border,
                                  width: 1,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 180.ms),
                          const Gap(13),

                          Text(
                            l10n.total_seats_booked,
                            style: context.textTheme.titleSmall,
                          ).animate().fadeIn(delay: 260.ms),
                          const SizedBox(height: 8),
                          Text(
                            "${carpool.totalSeatsBooked} ${l10n.seat_booked}",
                            style: context.textTheme.bodyMedium,
                          ).animate().fadeIn(delay: 220.ms),

                          if (isCompleted) ...[
                            const SizedBox(height: 16),

                            /// Payment Method
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: context.appColors.border,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 250.ms),
                            const SizedBox(height: 13),
                            Text(
                              l10n.paymentMethod,
                              style: context.textTheme.titleSmall,
                            ).animate().fadeIn(delay: 260.ms),
                            const Gap(8),
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
                                        (carpool.paymentMethod ==
                                                    'attached_card' &&
                                                (carpool
                                                        .transaction
                                                        ?.card
                                                        ?.last4
                                                        .isNotEmpty ??
                                                    false))
                                            ? "*** *** **${carpool.transaction!.card!.last4}"
                                            : l10n.via_wallet,
                                        style: context.textTheme.bodyMedium,
                                      ),

                                      ///  ICON
                                      Image.asset(
                                        (carpool.paymentMethod ==
                                                'attached_card')
                                            ? AppIcons.creditcard
                                            : AppIcons.wallet,
                                        height: 25,
                                        width: 25,
                                        color:
                                            (carpool.paymentMethod ==
                                                'attached_card')
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
                            ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),

                            const Gap(12),

                            /// Ride Stats
                            RideStatsRow(
                              totalTime:
                                  "${carpool.avgTime.toStringAsFixed(0)} ${l10n.min}",
                              totalDistance:
                                  "${carpool.distance.toStringAsFixed(2)} ${l10n.miles}",
                              estimateFare:
                                  (carpool.requiredSeats > 0 &&
                                      carpool.requiredSeats < 100)
                                  ? '\$${(carpool.fareCharged / carpool.requiredSeats).toStringAsFixed(2)}'
                                  : '\$${carpool.fareCharged.toStringAsFixed(2)}',
                              totalAmountSuffix: context.l10n.persen,

                              // estimateFare:
                              //     "\$${carpool.fareCharged.toStringAsFixed(2)}",
                            ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.15),

                            const Gap(12),

                            /// Review Section
                            if (hasMyReview)
                              ReviewWidget(
                                reviewText: carpool.review!.description,
                                rating: carpool.review!.stars.toInt(),
                              ).animate().fadeIn(delay: 350.ms).scale()
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.review,
                                    style: context.textTheme.titleSmall,
                                  ).animate().fadeIn(delay: 350.ms),
                                  const Gap(10),
                                  AppGradientBox(
                                    isPlain:
                                        Theme.of(context).brightness ==
                                        Brightness.light,
                                    cornerRadius: 10,
                                    padding: const EdgeInsets.only(
                                      top: 5,
                                      left: 4,
                                    ),
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
                                        ).animate().fadeIn(delay: 380.ms),
                                        TextField(
                                          controller: reviewController,
                                          minLines: 3,
                                          maxLines: 5,
                                          // maxLength: 800,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          decoration: InputDecoration(
                                            hintText: l10n.addReviewHere,
                                            border: InputBorder.none,
                                            counterText: '',
                                          ),
                                        ).animate().fadeIn(delay: 400.ms),
                                      ],
                                    ),
                                  ),
                                  const Gap(8),
                                  AppButton(
                                    text: l10n.submitReview,
                                    onPressed: () {
                                      submitFeedback(
                                        driver.id,
                                        "Driver",
                                        rating,
                                        reviewController.text,
                                      );
                                    },
                                  ).animate().fadeIn(delay: 450.ms).scale(),
                                ],
                              ),
                          ],
                        ],
                      ),
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
