import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Quick theme accessors on [BuildContext].
extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  Brightness get brightness => theme.brightness;
  bool get isDark => brightness == Brightness.dark;

  /// Access the app's custom semantic colors.
AppThemeColors get appColors => theme.extension<AppThemeColors>()!;
}
