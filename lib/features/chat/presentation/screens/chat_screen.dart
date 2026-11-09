import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/chat/data/datasources/chat_datasource.dart';
import 'package:ride_app/features/chat/data/models/chat_message_model.dart';
import 'package:ride_app/features/chat/data/models/message_delivery_status.dart';
import 'package:ride_app/features/chat/presentation/chat_screen_args.dart';
import 'package:ride_app/features/chat/presentation/widgets/report_user_bottom_sheet.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_socket_datasource.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/widgets/circular_profile.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/loader.dart';

import '../../../../core/params/report_params.dart';
import '../../../reviews/presentation/providers/report_provider.dart';
import '../../../reviews/presentation/states/report_state.dart';
import '../../../ride_room/presentation/states/carpool_state.dart';

enum _ChatMenuOption { report }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.args});

  final ChatScreenArgs? args;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatDatasource _chatDatasource = locator<ChatDatasource>();
  final CustomLoader _loader = CustomLoader();
  final int _limit = 10;

  List<ChatMessageModel> _messages = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  StreamSubscription<ChatMessageModel>? _chatReceiveSub;
  StreamSubscription<ChatStatusUpdate>? _chatStatusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideRoomProvider.notifier).setChatOpen();
    });
    _scrollController.addListener(_onScroll);
    if (widget.args != null) {
      _loadFirstPage();
      _registerSocketListener();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    ref.read(rideRoomProvider.notifier).setChatClose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    unawaited(_chatReceiveSub?.cancel());
    unawaited(_chatStatusSub?.cancel());
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || widget.args == null) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 100) _loadMore();
  }

  @override
  void deactivate() {
    super.deactivate();
    // if (!mounted) return;

    // ref.read(rideRoomProvider.notifier).setChatClose();
  }

  Future<void> _loadFirstPage() async {
    final args = widget.args;
    if (args == null) return;
    setState(() => _isLoading = true);
    final result = await _chatDatasource.getHistory(
      rideId: args.rideId,
      page: 1,
      limit: _limit,
    );
    if (!mounted) return;
    result.fold(
      (f) {
        context.showErrorToast(f.message);
        setState(() {
          _messages = [];
          _isLoading = false;
          _hasMore = false;
        });
      },
      (list) {
        setState(() {
          _messages = list.reversed.toList();
          _page = 1;
          _hasMore = list.length >= _limit;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadMore() async {
    final args = widget.args;
    if (args == null || !_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _page + 1;
    final result = await _chatDatasource.getHistory(
      rideId: args.rideId,
      page: nextPage,
      limit: _limit,
    );
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _isLoadingMore = false);
        context.showErrorToast(f.message);
      },
      (list) {
        setState(() {
          _messages = [...list.reversed, ..._messages];
          _page = nextPage;
          _hasMore = list.length >= _limit;
          _isLoadingMore = false;
        });
      },
    );
  }

  /// Live messages flow through [RideSocketListener] + [RideSocketDataSource]
  /// (same socket session as `ride:resume`), not a raw `SocketService.on`.
  void _registerSocketListener() {
    if (widget.args == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final datasource = locator<RideSocketDataSource>();
      final socketService = locator<SocketService>();

      /// Avoid tearing down a healthy ride socket on every chat open. Only force a
      /// full reconnect (and listener re-bind) when there is no active connection,
      /// e.g. after backgrounding or network loss.
      if (!socketService.isConnected) {
        try {
          await datasource.connect(forceReconnect: true);
        } catch (e, st) {
          debugPrint('[chat] force reconnect failed: $e\n$st');
          await datasource.connect();
        }
      } else {
        await datasource.connect();
      }

      if (!mounted) return;

      await _chatReceiveSub?.cancel();
      await _chatStatusSub?.cancel();

      _chatReceiveSub = datasource.chatReceiveUpdates().listen(
        (ChatMessageModel msg) {
          if (!mounted) return;
          setState(() {
            _messages = _upsertMessage(_messages, msg);
          });

          // Backend only marks read on history fetch; live exchanges need
          // an explicit `chat:read` while the user is viewing this chat.
          _markIncomingReadIfNeeded(msg);
        },
        onError: (e, st) {
          debugPrint('[chat:receive] stream error: $e\n$st');
        },
      );

      _chatStatusSub = datasource.chatStatusUpdates().listen(
        (ChatStatusUpdate update) {
          if (!mounted) return;
          setState(() {
            _messages = _applyStatusUpdate(
              _messages,
              update,
              currentUserId:
                  ref.read(userProfileProvider).profile?.user.id ?? '',
              driverId: widget.args?.driverId ?? '',
            );
          });
        },
        onError: (e, st) {
          debugPrint('[chat:status_updated] stream error: $e\n$st');
        },
      );

      debugPrint('[chat] subscribed receive + status via RideSocketDataSource');
    });
  }

  void _markIncomingReadIfNeeded(ChatMessageModel msg) {
    final args = widget.args;
    if (args == null) return;

    final String myUserId =
        ref.read(userProfileProvider).profile?.user.id ?? '';
    final bool isIncoming = !msg.isOutgoingFromUser(myUserId, args.driverId);
    if (!isIncoming) return;

    final String conversationId = (msg.conversationId ?? '').trim();
    if (conversationId.isEmpty) return;

    final String contextId = (msg.contextId ?? '').trim().toLowerCase();
    final String rideId = args.rideId.trim().toLowerCase();
    if (contextId.isNotEmpty &&
        rideId.isNotEmpty &&
        contextId != rideId &&
        conversationId.toLowerCase() != rideId) {
      return;
    }

    unawaited(
      locator<RideSocketDataSource>().markConversationRead(conversationId),
    );
  }

  static List<ChatMessageModel> _upsertMessage(
    List<ChatMessageModel> messages,
    ChatMessageModel incoming,
  ) {
    final String id = incoming.id.trim().toLowerCase();
    if (id.isEmpty) {
      return [...messages, incoming];
    }
    final int idx = messages.indexWhere((m) => m.id.trim().toLowerCase() == id);
    if (idx < 0) {
      return [...messages, incoming];
    }
    final ChatMessageModel existing = messages[idx];
    final MessageDeliveryStatus status = MessageDeliveryStatus.upgrade(
      existing.status,
      incoming.status,
    );
    final List<ChatMessageModel> next = List<ChatMessageModel>.from(messages);
    next[idx] = existing.copyWith(
      status: status,
      conversationId: incoming.conversationId ?? existing.conversationId,
      contextId: incoming.contextId ?? existing.contextId,
    );
    return next;
  }

  static List<ChatMessageModel> _applyStatusUpdate(
    List<ChatMessageModel> messages,
    ChatStatusUpdate update, {
    required String currentUserId,
    required String driverId,
  }) {
    final String conv = update.conversationId.trim().toLowerCase();
    if (conv.isEmpty) return messages;

    final String? msgId = update.messageId?.trim().toLowerCase();
    final String? updatedBy = update.updatedBy?.trim().toLowerCase();
    bool changed = false;

    final List<ChatMessageModel> next = messages.map((m) {
      final String mConv = (m.conversationId ?? '').trim().toLowerCase();
      if (mConv != conv) return m;

      if (msgId != null &&
          msgId.isNotEmpty &&
          m.id.trim().toLowerCase() != msgId) {
        return m;
      }

      if (updatedBy != null &&
          updatedBy.isNotEmpty &&
          m.senderId.trim().toLowerCase() == updatedBy) {
        return m;
      }

      // Only upgrade receipts on our outbound bubbles.
      if (!m.isOutgoingFromUser(currentUserId, driverId)) {
        return m;
      }

      final MessageDeliveryStatus status = MessageDeliveryStatus.upgrade(
        m.status,
        update.status,
      );
      if (status == m.status) return m;
      changed = true;
      return m.copyWith(status: status);
    }).toList();

    return changed ? next : messages;
  }

  Future<void> _sendMessage() async {
    final args = widget.args;
    if (args == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final contextType = args.isCarpool == 'true' ? 'CarpoolBooking' : 'Ride';
    final result = await _chatDatasource.sendMessage(
      receiverId: args.driverId,
      message: text,
      contextId: args.rideId,
      contextType: contextType,
    );
    if (!mounted) return;
    result.fold((f) => context.showErrorToast(f.message), (msg) {
      if (msg != null) {
        setState(() => _messages = _upsertMessage(_messages, msg));
      }
    });
  }

  void _openReportBottomSheet(BuildContext context) {
    showReportUserBottomSheet(
      context,
      onSubmit: (reasonId, reasonLabel) {
        if (!context.mounted) return;
        final args = widget.args;
        if (args == null ||
            args.driverId.trim().isEmpty ||
            args.rideId.trim().isEmpty) {
          context.showErrorToast(context.l10n.somethingWentWrong);
          return;
        }
        final params = ReportParam(
          entityId: args.driverId,
          entityType: "Driver",
          reason: reasonLabel,
          // description: reasonLabel,
          supportingEntityId: args.rideId,
          supportingEntityType: args.isCarpool == 'true'
              ? "CarpoolRoute"
              : "Ride",
        );
        ref.read(reportProvider.notifier).reportsubmit(params);
      },
    );
  }

  void _showReportSuccessDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GradientSideDialog(
        title: context.l10n.report_submitted,
        subtitle: context.l10n.subtitle_dialgue,
        imagePath: AppIcons.tick,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) context.pop();
    });
  }

  // void _showBlockConfirmation(BuildContext context) {
  //   final l10n = context.l10n;
  //   final colors = context.appColors;
  //   showDialog<void>(
  //     context: context,
  //     builder: (dialogContext) => GradientSideDialog(
  //       title: l10n.block_user,
  //       subtitle: l10n.block_user_confirmation,
  //       icon: Icons.warning_rounded,
  //       iconColor: colors.error,
  //       buttons: [
  //         AppButton(
  //           text: l10n.don_t_block,
  //           fontColor: colors.brand,
  //           backgroundColor: colors.border,
  //           onPressed: () => Navigator.of(dialogContext).pop(),
  //         ),
  //         AppButton(
  //           text: l10n.block_now,
  //           onPressed: () {
  //             Navigator.of(dialogContext).pop();
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReportState>(reportProvider, (previous, next) {
      if (next is ReportLoading) {
        _loader.showLoader(context);
      } else if (next is ReportError) {
        _loader.hideLoader();
        context.showErrorToast(next.message);
      } else if (next is ReportSuccess) {
        _loader.hideLoader();
        _showReportSuccessDialog(context);
      }
    });

    ref.listen<CarpoolState>(carpoolProvider, (previous, next) {
      final args = widget.args;
      if (args?.isCarpool != 'true') return;

      final bool carpoolWasActive =
          previous?.hasRequestedRide == true ||
          previous?.isAccepted == true ||
          previous?.isInProgress == true;
      final bool carpoolWasCancelled =
          carpoolWasActive &&
          !next.hasRequestedRide &&
          !next.isAccepted &&
          !next.isInProgress &&
          (next.actionMessage?.trim().isNotEmpty ?? false);
      if (!carpoolWasCancelled) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(rideRoomProvider.notifier).setChatClose();
        if (context.canPop()) {
          context.pop();
        }
      });
    });

    final profileState = ref.watch(userProfileProvider);
    final String currentUserId = profileState.profile?.user.id ?? '';

    final colors = context.appColors;
    final textTheme = context.textTheme;
    final args = widget.args;
    final driverName = args?.driverName ?? 'Driver';
    final driverImage = args?.driverProfileImage;

    return PopScope(
      onPopInvokedWithResult: (condition, item) {
        if (!mounted) return;

        ref.read(rideRoomProvider.notifier).setChatClose();
      },
      child: AppScaffold(
        padding: EdgeInsets.zero,
        scrollable: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: colors.border),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: colors.textPrimary,
              size: AppSizes.iconMedium,
            ),
            onPressed: () {
              ref.read(rideRoomProvider.notifier).setChatClose();
              context.pop();
            },
          ),
          title: Row(
            children: [
              CircularProfile(image: driverImage, size: 36),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  driverName,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          titleSpacing: 0,
          actions: [
            PopupMenuButton<_ChatMenuOption>(
              icon: Icon(
                Icons.more_vert,
                color: colors.textPrimary,
                size: AppSizes.iconMedium,
              ),
              position: PopupMenuPosition.under,

              offset: const Offset(-AppSizes.p20, 0),
              color: colors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusMedium),
                  bottomLeft: Radius.circular(AppSizes.radiusMedium),
                  topRight: Radius.circular(0),
                  bottomRight: Radius.circular(AppSizes.radiusMedium),
                ),
                side: BorderSide(color: AppColors.genericBorder, width: 0.4),
              ),
              padding: EdgeInsets.zero,
              menuPadding: EdgeInsets.zero,
              itemBuilder: (menuContext) => [
                PopupMenuItem<_ChatMenuOption>(
                  value: _ChatMenuOption.report,
                  child: Text(
                    context.l10n.chat_report,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
              onSelected: (option) {
                if (option == _ChatMenuOption.report) {
                  _openReportBottomSheet(context);
                }
              },
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : args == null
                  ? Center(
                      child: Text(
                        context.l10n.something_went_wrong,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : (!_isLoading && _messages.isEmpty)
                  ? Center(child: Text(context.l10n.chat_no_messages_yet))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p16,
                        vertical: AppSizes.p16,
                      ),
                      itemCount: (_isLoadingMore ? 1 : 0) + _messages.length,
                      itemBuilder: (context, index) {
                        if (_isLoadingMore && index == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.p12,
                            ),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        final msgIndex = index - (_isLoadingMore ? 1 : 0);
                        final msg = _messages[_messages.length - 1 - msgIndex];
                        final bool isOutgoing = msg.isOutgoingFromUser(
                          currentUserId,
                          args.driverId,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.p12),
                          child: _ChatBubble(
                            text: msg.message,
                            // time: msg.createdAt.timeOnly,
                            time: msg.createdAt.toLocal().timeOnly,
                            isOutgoing: isOutgoing,
                            status: isOutgoing ? msg.status : null,
                          ),
                        );
                      },
                    ),
            ),
            _ChatInput(
              messageController: _messageController,
              colors: colors,
              textTheme: textTheme,
              onSend: args != null ? _sendMessage : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.time,
    required this.isOutgoing,
    this.status,
  });

  final String text;
  final String time;
  final bool isOutgoing;
  final MessageDeliveryStatus? status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    final bubbleColor = isOutgoing
        ? colors.brand
        : Color.lerp(colors.brand, colors.surface, 0.5) ?? colors.surface;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.78),
        child: Column(
          crossAxisAlignment: isOutgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p12,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSizes.radiusMedium),
                  topRight: const Radius.circular(AppSizes.radiusMedium),
                  bottomLeft: Radius.circular(
                    isOutgoing ? AppSizes.radiusMedium : 4,
                  ),
                  bottomRight: Radius.circular(
                    isOutgoing ? 4 : AppSizes.radiusMedium,
                  ),
                ),
              ),
              child: Text(
                text,
                style: textTheme.bodyMedium?.copyWith(color: colors.onBrand),
              ),
            ),
            const SizedBox(height: AppSizes.p4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (isOutgoing && status != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      status!.isDoubleTick ? Icons.done_all : Icons.done,
                      size: 14,
                      color: status!.isRead
                          ? const Color(0xFF34B7F1)
                          : colors.textSecondary,
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

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.messageController,
    required this.colors,
    required this.textTheme,
    this.onSend,
  });

  final TextEditingController messageController;
  final AppThemeColors colors;
  final TextTheme textTheme;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p12,
        AppSizes.p8,
        AppSizes.p16,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        top: false,
        child: AppTextField(
          controller: messageController,
          hintText: context.l10n.chat_message_hint,
          maxlines: 1,
          textInputAction: TextInputAction.send,
          radius: AppSizes.radiusRound,
          onFieldSubmitted: (_) => onSend?.call(),
          suffixIcon: Container(
            margin: const EdgeInsets.all(10),
            child: Material(
              color: colors.brand,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onSend,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p8),
                  child: Image.asset(
                    AppIcons.send,
                    height: 20,
                    width: 20,
                    color: colors.onBrand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
