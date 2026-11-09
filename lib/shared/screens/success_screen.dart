import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/extensions/theme_extension.dart';
import '../../core/navigation/routes.dart';
import '../../l10n/app_localizations.dart';
import '../shared.dart';

enum SuccessType {
  numberVerified,
  accountDeleted,
  fundsAdded,
  languageUpdated,
  feedbackSubmitted,
}

class SuccessArgs {
  const SuccessArgs({
    this.type = SuccessType.numberVerified,
    this.redirectRouteName,
    this.autoRedirectDelay = const Duration(seconds: 2),
    this.redirectArgs,
    this.usePopOnRedirect = false,
  });

  final SuccessType type;
  final String? redirectRouteName;
  final Object? redirectArgs;
  final Duration autoRedirectDelay;

  /// When true, the auto-redirect calls [Navigator.pop] instead of [GoRouter.goNamed].
  final bool usePopOnRedirect;
}

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key, this.args = const SuccessArgs()});

  final SuccessArgs args;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _scheduleRedirect();
  }

  @override
  void didUpdateWidget(covariant SuccessScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args != widget.args) {
      _redirectTimer?.cancel();
      _scheduleRedirect();
    }
  }

  void _scheduleRedirect() {
    _redirectTimer = Timer(widget.args.autoRedirectDelay, () {
      if (!mounted) return;
      final currentRouteName = GoRouter.of(context).state.name;
      if (currentRouteName != Routes.success.name) return;

      if (widget.args.usePopOnRedirect) {
        context.pop();
      } else {
        final routeName = widget.args.redirectRouteName ?? Routes.home.name;
        context.goNamed(routeName, extra: widget.args.redirectArgs);
      }
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final content = _resolveContent(widget.args.type, l10n);

    return AppScaffold(
      scrollable: false,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: AppSizes.p64,
                width: AppSizes.p64,
                decoration: BoxDecoration(
                  color: colors.brand,
                  borderRadius: BorderRadius.circular(AppSizes.p16),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colors.onBrand,
                  size: AppSizes.iconLarge,
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              Text(
                content.title,
                style: context.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.p8),
              Text(
                content.message,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _AuthSuccessContent _resolveContent(SuccessType type, AppLocalizations l10n) {
    switch (type) {
      case SuccessType.numberVerified:
        return _AuthSuccessContent(
          title: l10n.number_verified,
          message: l10n.number_verified_message,
        );
      case SuccessType.accountDeleted:
        return _AuthSuccessContent(
          title: l10n.account_deleted_title,
          message: l10n.account_deleted_message,
        );
      case SuccessType.fundsAdded:
        return _AuthSuccessContent(
          title: l10n.funds_added_title,
          message: l10n.funds_added_message,
        );
      case SuccessType.languageUpdated:
        return _AuthSuccessContent(
          title: l10n.language_updated_title,
          message: l10n.language_updated_message,
        );
      case SuccessType.feedbackSubmitted:
        return _AuthSuccessContent(
          title: l10n.feedback_submitted_title,
          message: l10n.feedback_submitted_message,
        );
    }
  }
}

class _AuthSuccessContent {
  const _AuthSuccessContent({required this.title, required this.message});

  final String title;
  final String message;
}
