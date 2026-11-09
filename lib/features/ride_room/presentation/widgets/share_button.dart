import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../core/extensions/theme_extension.dart';
import '../providers/carpool_provider.dart';
import '../providers/ride_room_provider.dart';

class ShareButton extends ConsumerStatefulWidget {
  const ShareButton({super.key});

  @override
  ConsumerState<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends ConsumerState<ShareButton> {
  bool _isShareLoading = false;

  Future<void> _onShareRideTap() async {
    if (_isShareLoading) return;
    setState(() {
      _isShareLoading = true;
    });

    final carpoolState = ref.read(carpoolProvider);
    final bool isActiveCarpoolRide =
        carpoolState.isAccepted || carpoolState.isInProgress;
    final String? shareUrl = isActiveCarpoolRide
        ? await ref.read(rideRoomProvider.notifier).getShareCarpoolRideUrl(
            carpoolState.requestedRide?.id ?? carpoolState.currentCarpoolId,
          )
        : await ref.read(rideRoomProvider.notifier).getShareRideUrl();
    if (!mounted) return;
    if (shareUrl == null || shareUrl.isEmpty) {
      context.showErrorToast('Unable to share ride right now.');
      setState(() {
        _isShareLoading = false;
      });
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareUrl,
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isShareLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 96,
          maxWidth: context.screenWidth * 0.32,
          minHeight: 40,
        ),
        child: Material(
          color: context.appColors.brand,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _isShareLoading ? null : _onShareRideTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _isShareLoading
                    ? SizedBox(
                        key: const ValueKey('share_loading'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.appColors.border,
                        ),
                      )
                    : Row(
                        key: const ValueKey('share_label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            AppIcons.share,
                            height: 16,
                            color: context.appColors.border,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.share_ride,
                              maxLines: 1,
                              // overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.appColors.border,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
