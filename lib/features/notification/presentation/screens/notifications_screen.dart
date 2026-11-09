import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/extensions/theme_extension.dart';
import '../../../../core/params/notification_params.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/shared.dart';
import '../../../../shared/widgets/custom_dialogue.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';
import '../states/notification_state.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const int _initialLimit = 15;
  static const int _paginationLimit = 10;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchNotifications({int page = 1}) {
    return ref
        .read(notificationProvider.notifier)
        .getNotifications(
          params: NotificationParams(
            limit: page == 1 ? _initialLimit : _paginationLimit,
            page: page,
          ),
        );
  }

  Future<void> _refreshNotifications() => _fetchNotifications();

  Future<bool> _confirmDeleteAllNotifications() async {
    final result = await ref
        .read(notificationProvider.notifier)
        .deleteAllNotifications();

    if (!mounted) return false;

    if (!result.success) {
      if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
        context.showErrorToast(result.errorMessage!);
      }
      return false;
    }

    context.showToast('All notifications deleted');
    return true;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final state = ref.read(notificationProvider);
    final position = _scrollController.position;

    if (position.extentAfter < 240 && !state.isLoadingMore && state.hasMore) {
      _fetchNotifications(page: state.page + 1);
    }
  }

  Future<bool> _confirmDeleteNotification(
    NotificationEntity notification,
  ) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .deleteNotification(notification.id);

    if (!mounted) return false;

    if (!result.success) {
      if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
        context.showErrorToast(result.errorMessage!);
      }
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final colors = context.appColors;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          if (state.notifications.isNotEmpty)
            IconButton(
              onPressed: state.isDeleting
                  ? null
                  : () async {
                      final isConfirmed =
                          await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => GradientSideDialog(
                              title: context.l10n.delete_all_notifications,
                              subtitle: context
                                  .l10n
                                  .delete_all_notifications_confirmation,
                              icon: Icons.warning,
                              iconColor: AppColors.error,
                              buttons: [
                                AppButton(
                                  text: context.l10n.cancel,
                                  fontColor:
                                      context.brightness == Brightness.light
                                      ? context.appColors.textPrimary
                                      : context.appColors.brand,
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  backgroundColor:
                                      context.appColors.lightButton,
                                ),
                                AppButton(
                                  text: context.l10n.confirm,
                                  fontColor: AppColors.darkBackground,
                                  backgroundColor: context.appColors.brand,
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (isConfirmed) {
                        await _confirmDeleteAllNotifications();
                      }
                    },
              icon: state.isDeleting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.brand,
                      ),
                    )
                  : Image.asset(
                      AppIcons.trash,
                      width: 20,
                      height: 20,
                      color: Colors.red,
                    ),
              tooltip: context.l10n.delete_all_notifications,
            ),
        ],
      ),
      child: _buildBody(state, colors),
    );
  }

  Widget _buildBody(NotificationState state, AppThemeColors colors) {
    final hasNotifications = state.notifications.isNotEmpty;
    final isInitialLoad =
        !hasNotifications &&
        (state.getNotifStatus == NotificationStatus.initial ||
            state.getNotifStatus == NotificationStatus.loading);

    if (isInitialLoad) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 2.6, color: colors.brand),
      );
    }

    if (!hasNotifications) {
      return RefreshIndicator.adaptive(
        onRefresh: _refreshNotifications,
        color: colors.brand,
        backgroundColor: colors.surface,
        child: CustomScrollView(
          key: const PageStorageKey<String>('notifications_scroll_view'),
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _NotificationStatusPane(
                  icon: state.getNotifStatus == NotificationStatus.error
                      ? Icons.cloud_off_rounded
                      : Icons.notifications_none_rounded,
                  title: state.getNotifStatus == NotificationStatus.error
                      ? context.l10n.something_went_wrong
                      : context.l10n.notification_center,
                  message: state.message,
                  actionLabel: state.getNotifStatus == NotificationStatus.error
                      ? context.l10n.retry
                      : null,
                  onAction: state.getNotifStatus == NotificationStatus.error
                      ? _refreshNotifications
                      : null,
                  colors: colors,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: _refreshNotifications,
      color: colors.brand,
      backgroundColor: colors.surface,
      child: CustomScrollView(
        key: const PageStorageKey<String>('notifications_scroll_view'),
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (state.getNotifStatus == NotificationStatus.error)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _InlineErrorBanner(
                  message: state.message ?? context.l10n.something_went_wrong,
                  onRetry: _refreshNotifications,
                  colors: colors,
                ),
              ),
            ),
          if (hasNotifications)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == state.notifications.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: colors.brand,
                          ),
                        ),
                      );
                    }

                    final notification = state.notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey('notification-${notification.id}'),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) async =>
                            _confirmDeleteNotification(notification),
                        background: _NotificationDeleteBackground(
                          colors: colors,
                          alignLeft: true,
                        ),
                        secondaryBackground: _NotificationDeleteBackground(
                          colors: colors,
                          alignLeft: false,
                        ),
                        child: _AnimatedNotificationTile(
                          key: ValueKey('notification-tile-${notification.id}'),
                          index: index,
                          child: _NotificationCard(
                            notification: notification,
                            colors: colors,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount:
                      state.notifications.length +
                      (state.isLoadingMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.colors});

  final NotificationEntity notification;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final content = notification.notificationContent;
    final title = (content.title ?? '').trim();
    final description = (content.description ?? '').trim();
    final timestamp =
        (notification.updatedAt ?? notification.createdAt).timeAgo;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notification.isRead
              ? colors.border.withValues(alpha: 0.85)
              : colors.brand.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? colors.fieldFill
                    : colors.brand.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                notification.isRead
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_rounded,
                size: 20,
                color: notification.isRead
                    ? colors.textSecondary
                    : colors.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title.isEmpty ? context.l10n.notifications : title,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        timestamp,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
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
}

class _NotificationStatusPane extends StatelessWidget {
  const _NotificationStatusPane({
    required this.icon,
    required this.title,
    required this.colors,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: colors.fieldFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: colors.textSecondary, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (message != null && message!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.brand,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({
    required this.message,
    required this.onRetry,
    required this.colors,
  });

  final String message;
  final Future<void> Function() onRetry;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.error.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colors.error,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDeleteBackground extends StatelessWidget {
  const _NotificationDeleteBackground({
    required this.colors,
    required this.alignLeft,
  });

  final AppThemeColors colors;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.error.withValues(alpha: 0.18)),
      ),
      child: Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: alignLeft
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              if (alignLeft) ...[
                Icon(Icons.delete_outline_rounded, color: colors.error),
                const SizedBox(width: 8),
                Text(
                  context.l10n.delete,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                Text(
                  context.l10n.delete,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.delete_outline_rounded, color: colors.error),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedNotificationTile extends StatefulWidget {
  const _AnimatedNotificationTile({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedNotificationTile> createState() =>
      _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState extends State<_AnimatedNotificationTile> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      Duration(milliseconds: 60 * (widget.index > 6 ? 6 : widget.index)),
      () {
        if (!mounted) return;
        setState(() => _isVisible = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _isVisible ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
