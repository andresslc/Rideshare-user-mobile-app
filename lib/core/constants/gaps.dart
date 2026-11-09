import 'package:flutter/widgets.dart';

import '../constants/app_sizes.dart';

/// Convenient [SizedBox] gap widgets using [AppSizes] spacing tokens.
///
/// Usage: `Gap.xs` or `Gap.md` directly in your widgets.
class AppGap {
  AppGap._();

  // ── Vertical gaps ──
  static const xxs = SizedBox(height: AppSizes.xxs);
  static const xs = SizedBox(height: AppSizes.xs);
  static const sm = SizedBox(height: AppSizes.sm);
  static const md = SizedBox(height: AppSizes.md);
  static const lg = SizedBox(height: AppSizes.lg);
  static const xl = SizedBox(height: AppSizes.xl);
  static const xxl = SizedBox(height: AppSizes.xxl);

  // ── Horizontal gaps ──
  static const hxxs = SizedBox(width: AppSizes.xxs);
  static const hxs = SizedBox(width: AppSizes.xs);
  static const hsm = SizedBox(width: AppSizes.sm);
  static const hmd = SizedBox(width: AppSizes.md);
  static const hlg = SizedBox(width: AppSizes.lg);
  static const hxl = SizedBox(width: AppSizes.xl);
  static const hxxl = SizedBox(width: AppSizes.xxl);

  // ── Input Border ──
}
