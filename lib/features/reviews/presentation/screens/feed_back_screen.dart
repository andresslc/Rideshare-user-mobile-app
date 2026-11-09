import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/core/navigation/routes.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/shared/screens/success_screen.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/app_scaffold.dart';
import 'package:ride_app/shared/widgets/app_text_field.dart';
import 'package:ride_app/shared/widgets/input_dialogue.dart';
import 'package:ride_app/shared/widgets/ride_driver_info.dart';

import '../../../../core/extensions/string_extension.dart';
import '../../../../core/params/feedback_params.dart';
import '../../../../core/params/report_params.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../ride_room/domain/entities/ride_entity.dart';
import '../providers/feedback_provider.dart';
import '../providers/report_provider.dart';
import '../states/feedback_state.dart';

class FeedBackScreen extends ConsumerStatefulWidget {
  final RideUserEntity driver;
  final String rideId;
  final String? carpoolId;
  const FeedBackScreen({
    super.key,
    required this.driver,
    required this.rideId,
    this.carpoolId,
  });

  @override
  ConsumerState<FeedBackScreen> createState() => _FeedBackScreenState();
}

class _FeedBackScreenState extends ConsumerState<FeedBackScreen> {
  int rating = 0;
  final _feedbackController = TextEditingController();
  final CustomLoader loader = CustomLoader();
  void showReportDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (_) => InputDialog(
        title: l10n.report_driver,
        subtitle: l10n.we_appreciate_issue,
        hintText: l10n.reason,
        buttonText: l10n.submit,
        onSubmit: (description) {
          context.pop();
          submitReport(description);
          // showDialog(
          //   context: context,
          //   builder: (_) => const GradientSideDialog(
          //     title: "Report Submitted",
          //     subtitle:
          //         "Your report has been submitted We'll investigate the issue!",
          //     imagePath: AppIcons.tick,
          //   ),
          // );
          //debugPrint('User reported with reason: $reason');
        },
      ),
    );
  }

  void submitReport(String description) {
    final String trimmedDescription = description.trim();
    if (widget.driver.id.trim().isEmpty ||
        (widget.rideId.trim().isEmpty &&
            (widget.carpoolId?.trim().isEmpty ?? true))) {
      context.showToast(context.l10n.somethingWentWrong);
      return;
    }
    if (trimmedDescription.isEmpty) {
      context.showToast(context.l10n.please_reason);
      return;
    }

    final param = ReportParam(
      entityId: widget.driver.id,
      entityType: "Driver",
      reason: trimmedDescription,
      supportingEntityId: (widget.carpoolId?.isNotEmpty ?? false)
          ? widget.carpoolId!
          : widget.rideId,
      supportingEntityType: (widget.carpoolId?.isNotEmpty ?? false)
          ? "CarpoolRoute"
          : "Ride",
    );

    ref.read(reportProvider.notifier).reportsubmit(param);
  }

  void submitmethod() {
    final l10n = context.l10n;

    if (widget.driver.id.trim().isEmpty ||
        (widget.rideId.trim().isEmpty &&
            (widget.carpoolId?.trim().isEmpty ?? true))) {
      context.showToast(l10n.unable_to_submit);
      return;
    }

    if (rating == 0) {
      context.showToast(l10n.please_select_rating);
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      context.showToast(l10n.description_valid);
      return;
    }

    final param = FeedbackParam(
      receiverId: widget.driver.id,
      receiverType: "Driver",
      stars: rating,
      description: _feedbackController.text.trim(),
      rideId: (widget.carpoolId?.trim().isEmpty ?? true) ? widget.rideId : null,
      carpoolId: (widget.carpoolId?.trim().isNotEmpty ?? false)
          ? widget.carpoolId
          : null,
    );

    ref.read(feedbackProvider.notifier).submitFeedback(param);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _resetRideRoomForHome() {
    ref.read(carpoolProvider.notifier).clearCompletedRide();
    ref.read(mapProvider.notifier).clearDropOffLocation();
    ref.read(mapProvider.notifier).clearPickupLocation();
    ref
        .read(rideRoomProvider.notifier)
        .updateCurrentSheet(RideSheetsType.whereToGoSheet);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen<FeedbackState>(feedbackProvider, (previous, next) {
      if (next is FeedbackLoading) {
        loader.showLoader(context);
      } else if (next is FeedbackError) {
        loader.hideLoader();
        context.showToast(next.message);
      } else if (next is FeedbackSuccess) {
        loader.hideLoader();
        _resetRideRoomForHome();
        context.goNamed(
          Routes.success.name,
          extra: SuccessArgs(
            type: SuccessType.feedbackSubmitted,
            redirectRouteName: Routes.home.name,
          ),
        );
      } else if (next is FeedbackInitial) {
        // do nothing
      }
    });

    return AppScaffold(
      resizeToAvoidBottomInset: true,
      padding: EdgeInsets.zero,
      scrollable: true,
      reverseScroll: true,
      appBar: AppBar(
        title: Text(l10n.feed_back)
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            top: 12,
          ),
          child: AppButton(text: l10n.submit, onPressed: submitmethod),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Text(
              l10n.how_was_the_driver,
              style: context.textTheme.titleSmall?.copyWith(fontSize: 16),
            ).animate().fadeIn().slideX(begin: -0.1),

            const Gap(AppSizes.p8),

            ///Subtitle (5 lines)
            Text(
              l10n.subtitle_description,
              style: context.textTheme.bodyMedium,
            ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1),
            const Gap(AppSizes.p16),

            DriverInfoSection(
              profileImage: widget.driver.profilePicture,
              driverId: widget.driver.id,
              userName: widget.driver.fullName.titleCase,
              rating: widget.driver.rating.toDouble(),
              carImage: AppImages.sedan,
              // carName: widget.driver. ?? '',
              // city: widget.driver.plateNumber ?? '',
              carMake: "Honda",
              plateNo: "No city",
              showCarInfo: false,
            ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),
            const Gap(AppSizes.p18),
            // line grey
            Container(
              height: 1,
              color: context.appColors.border,
            ).animate(delay: 200.ms).fadeIn(),
            const Gap(AppSizes.p18),

            /// Rating Title
            Text(
              l10n.your_rating,
              style: context.textTheme.bodyMedium,
            ).animate(delay: 250.ms).fadeIn(),
            const Gap(AppSizes.p11),

            /// Star Rating
            RatingBar.builder(
              initialRating: rating.toDouble(),
              minRating: 1,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 35,
              itemPadding: const EdgeInsets.symmetric(horizontal: 2),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (value) {
                setState(() {
                  rating = value.toInt(); // live update
                });
              },
            ).animate(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),

            const Gap(AppSizes.p16),
            AppGradientBox(
              isPlain: context.theme.brightness == Brightness.light,
              cornerRadius: 10,
              child: AppTextField(
                radius: 10,
                controller: _feedbackController,
                hintText: l10n.hint_description,
                maxlines: 4,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
              ),
            ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
