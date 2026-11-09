import 'package:flutter/material.dart';

/// Centralized design tokens for colors and gradients.
class AppColors {
  AppColors._();
  // Brand

  static const Color brand = Color(0xFF61CB08);
  static const Color brandLight = Color(0x2661CB08);
  static const Color star = Colors.amber;

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F8F7);
  static const Color lightField = Color(0xFFF2F3F2);
  static const Color lightBorder = Color(0xFFE2E4E2);
  static const Color thinborder = Color(0xFFFFFFFF);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0B1208);
  static const Color darkbutton = Color(0xFF000B00);
  static const Color darkSurface = Color(0xFF0E180B);
  static const Color darkField = Color(0xFF0F1B0C);
  static const Color darkBorder = Color(0xFF1B2A1B);

  // Text
  static const Color lightTextPrimary = Color(0xFF0F1210);
  static const Color lightTextSecondary = Color(0xFF6B706C);
  static const Color darkTextPrimary = Color(0xFFF5F7F5);
  static const Color darkTextSecondary = Color(0xFFB4B9B5);
  static const Color subtitledialogue = Color(0xFFA2A2A2);
  static const Color genericBorder = Color(0x6661CB08);

  // static const Color darkTextSecondary = Color(0xFF808080);

  // Status
  static const Color error = Color.fromARGB(255, 241, 17, 17);
  static const Color success = Color(0xFF2FBF71);

  // Effects
  static const Color shadow = Color(0xff000000);
  static const Color lightButton = Color(0xff081A01);

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1308), Color(0xFF0B1908), Color(0xFF091007)],
  );

  static const LinearGradient inputFieldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromRGBO(97, 203, 8, 0.32),
      Color.fromRGBO(97, 203, 8, 0.10),
      Color.fromRGBO(97, 203, 8, 0.16),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromRGBO(97, 203, 8, 0.12),
      Color.fromRGBO(97, 203, 8, 0.04),
      Color.fromRGBO(97, 203, 8, 0.07),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}

/// Semantic, theme-aware colors that adapt to light/dark mode.
/// Access via `Theme.of(context).extension<AppThemeColors>()!`
/// or the shortcut `context.appColors`.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color brand;
  final Color onBrand;
  final Color background;
  final Color surface;
  final Color fieldFill;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color link;
  final Color shadow;
  final Color button;
  final Color lightButton;
  final Color error;
  final Gradient? backgroundGradient;

  const AppThemeColors({
    required this.button,
    required this.lightButton,
    required this.brand,
    required this.onBrand,
    required this.background,
    required this.surface,
    required this.fieldFill,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.link,
    required this.shadow,
    required this.error,
    this.backgroundGradient,
  });

  static const AppThemeColors light = AppThemeColors(
    brand: AppColors.brand,
    onBrand: Color(0xFF0B1607),
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    fieldFill: AppColors.lightField,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    link: AppColors.brand,
    shadow: AppColors.shadow,
    error: Color(0xFFE5484D),
    backgroundGradient: null,
    button: AppColors.lightButton,
    lightButton: AppColors.brandLight,
  );

  static const AppThemeColors dark = AppThemeColors(
    brand: AppColors.brand,
    onBrand: Color(0xFFFFFFFF),
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    fieldFill: AppColors.darkField,
    border: AppColors.darkBorder,
    button: AppColors.darkbutton,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    link: AppColors.brand,
    shadow: Color(0x33000000),
    error: Color(0xFFFF6B6B),
    backgroundGradient: AppColors.darkBackgroundGradient,
    lightButton: AppColors.lightButton,
  );

  @override
  AppThemeColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? background,
    Color? surface,
    Color? fieldFill,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? link,
    Color? shadow,
    Color? error,
    Gradient? backgroundGradient,
  }) {
    return AppThemeColors(
      button: button,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      fieldFill: fieldFill ?? this.fieldFill,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      link: link ?? this.link,
      shadow: shadow ?? this.shadow,
      error: error ?? this.error,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      lightButton: lightButton,
    );
  }

  @override
  AppThemeColors lerp(covariant AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      button: Color.lerp(button, other.button, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      link: Color.lerp(link, other.link, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      error: Color.lerp(error, other.error, t)!,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      lightButton: lightButton,
    );
  }
}
