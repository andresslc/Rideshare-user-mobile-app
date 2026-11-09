import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/reviews/presentation/states/feedback_state.dart';
import 'package:ride_app/shared/shared.dart';

import '../../../auth/presentation/widgets/profile_header.dart';
import '../../../auth/presentation/widgets/ride_history_count_widget.dart';
import '../../../ride_history/presentation/widgets/review_widget.dart';
import '../../domain/entities/review_entity.dart';
import '../providers/feedback_provider.dart';
import '../widgets/review_shimmer.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key, required this.driverId});
  final String driverId;

  @override
  ConsumerState<DriverProfileScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<DriverProfileScreen> {
  final ScrollController _controller = ScrollController();
  @override
  void initState() {
    super.initState();

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedbackProvider.notifier).fetchReviews(widget.driverId);
    });

    // Pagination listener
    _controller.addListener(() {
      final provider = ref.read(feedbackProvider.notifier);
      final state = ref.read(feedbackProvider);

      if (_controller.position.pixels >=
              _controller.position.maxScrollExtent - 200 &&
          state is ReviewsSuccess &&
          state.hasMore &&
          !state.isLoadingMore) {
        provider.loadMore(widget.driverId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(feedbackProvider);
    String driverName = "";
    String? driverImage;
    double driverRating = 0;
    int completedRides = 0;

    /// Static Localized Reviews Data
    List<ReviewEntity> reviews = [];
    String? errorMessage;
    bool isInitialLoading = false;
    bool isLoadingMore = false;
    if (state is FeedbackLoading) {
      isInitialLoading = true;
    } else if (state is FeedbackError) {
      errorMessage = state.message;
    } else if (state is ReviewsSuccess) {
      reviews = state.reviews;
      isLoadingMore = state.isLoadingMore;
      driverName = state.driver.fullName;
      driverImage = state.driver.profilePicture;
      driverRating = state.driver.rating;
      completedRides = state.completedRides;
    }

    // final totalReviews = reviews.length;
    // final double averageRating = totalReviews == 0
    //     ? 0
    //     : reviews.map((r) => r.stars).reduce((a, b) => a + b) / totalReviews;

    // int getCount(int star) => reviews.where((r) => r.stars == star).length;

    // return AppScaffold(
    //   appBar: AppBar(title: Text(l10n.reviews)),
    //   child: Padding(
    //     padding: const EdgeInsets.symmetric(
    //       horizontal: AppSizes.p16,
    //     ).copyWith(top: AppSizes.p4),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         const Gap(AppSizes.p12),

    //         /// 🔹 Title
    //         Text(l10n.customer_reviews, style: context.textTheme.titleMedium),

    //         const Gap(AppSizes.p8),

    //         /// ⭐ Average Rating Row
    //         Row(
    //           children: [
    //             ...List.generate(5, (index) {
    //               if (index < averageRating.floor()) {
    //                 return Icon(
    //                   Icons.star,
    //                   color: colors.brand,
    //                   size: AppSizes.p12,
    //                 );
    //               } else if (index < averageRating) {
    //                 return Icon(
    //                   Icons.star_half,
    //                   color: colors.brand,
    //                   size: AppSizes.p12,
    //                 );
    //               } else {
    //                 return Icon(
    //                   Icons.star_border,
    //                   color: colors.brand,
    //                   size: AppSizes.p12,
    //                 );
    //               }
    //             }),
    //             const Gap(AppSizes.p8),
    //             Text(
    //               "(${averageRating.toStringAsFixed(1)})",
    //               style: context.textTheme.titleMedium?.copyWith(
    //                 fontSize: AppSizes.p12,
    //               ),
    //             ),
    //             const Gap(AppSizes.p4),
    //             Text(
    //               l10n.total_reviews(totalReviews),
    //               style: context.textTheme.titleMedium?.copyWith(
    //                 fontSize: AppSizes.p12,
    //               ),
    //             ),
    //           ],
    //         ),

    //         const Gap(AppSizes.p12),

    //         /// ⭐ Rating Breakdown
    //         Column(
    //           children: List.generate(5, (index) {
    //             int starValue = 5 - index;
    //             int count = getCount(starValue);

    //             return Padding(
    //               padding: const EdgeInsets.only(bottom: AppSizes.p8),
    //               child: Row(
    //                 children: [
    //                   Text(
    //                     l10n.star_count(starValue),
    //                     style: context.textTheme.titleMedium?.copyWith(
    //                       fontSize: AppSizes.p14,
    //                     ),
    //                   ),
    //                   const Gap(AppSizes.p8),
    //                   Expanded(
    //                     child: ClipRRect(
    //                       borderRadius: BorderRadius.circular(AppSizes.p16),
    //                       child: LinearProgressIndicator(
    //                         value: totalReviews == 0 ? 0 : count / totalReviews,
    //                         backgroundColor: colors.brand,
    //                         color: colors.textPrimary,
    //                         minHeight: AppSizes.p8,
    //                       ),
    //                     ),
    //                   ),
    //                   const Gap(AppSizes.p8),
    //                   Text("$count", style: context.textTheme.bodySmall),
    //                 ],
    //               ),
    //             );
    //           }),
    //         ),

    //         const Gap(AppSizes.p20),

    //         /// 📋 Reviews List
    //         Expanded(
    //           child: ListView.builder(
    //             itemCount: reviews.length,
    //             itemBuilder: (context, index) {
    //               final review = reviews[index];

    //               return const Padding(
    //                 padding: EdgeInsets.only(bottom: AppSizes.p12),
    //                 //  child:
    //                 //  ReviewWidget(
    //                 //   review: review,
    //                 //   showStars: true,
    //                 //   showDate: true,
    //                 //   backgroundColor: colors.white,
    //                 //   roundedCorners: true,
    //                 // ),
    //               );
    //             },
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.driver_profile)),
      child: isInitialLoading
          ? ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
              itemCount: 5,
              itemBuilder: (context, index) => const ReviewShimmer(),
            )
          : errorMessage != null
          ? Center(child: Text(errorMessage))
          : CustomScrollView(
              controller: _controller,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Gap(AppSizes.p12),

                      // const Gap(20),

                      /// 🔹 Driver Profile Center
                      ProfileHeaderWidget(
                        imageUrl: driverImage ?? "",
                        name: driverName.titleCase,
                        // rating: ,
                        email: "",
                        phone: "",
                      ),

                      /// 🔹 Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: JobStatusCard(
                              title: l10n.ride_completed,
                              count: completedRides.toString(),
                              color: context.appColors.brand,
                            ),
                          ),

                          const Gap(12),

                          Expanded(
                            child: JobStatusCard(
                              title: l10n.rating,
                              count: driverRating.toStringAsFixed(1),
                              color: context.appColors.brand,
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),

                /// 📋 Reviews List
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final review = reviews[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p4,
                      ),
                      child: ReviewWidget(
                        showDriverInfo: true,
                        reviewerImage: review.reviewerImage,
                        reviewerName: review.reviewerName,
                        title: false,
                        showline: false,
                        // showline: false,
                        reviewText: review.description,
                        rating: review.stars,
                      ),
                    );
                  }, childCount: reviews.length),
                ),

                /// 🔹 Bottom Pagination Loader
                if (isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
              ],
            ),
    );
  }
}
