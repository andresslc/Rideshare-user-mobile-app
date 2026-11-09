import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = _buildTheme(
    brightness: Brightness.light,
    colors: AppThemeColors.light,
  );

  static ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    colors: AppThemeColors.dark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeColors colors,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.brand,
      brightness: brightness,
      primary: colors.brand,
      // ignore: deprecated_member_use
      background: colors.background,
      surface: colors.surface,
      error: AppColors.error,
    );

    final textTheme = AppTextStyles.textTheme.apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    const radiusValue = 16.0;

    /// 🔥 Squircle Shape
    final squircleShape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radiusValue),
    );

    const normalBorder = InputBorder.none;

    // OutlineInputBorder(
    //   borderSide: BorderSide(color: colors.border, width: 1),
    //   borderRadius: BorderRadius.circular(radiusValue),
    // );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,

      iconTheme: IconThemeData(color: colors.textPrimary),

      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: brightness == Brightness.dark
              ? Brightness.dark
              : Brightness.light,
        ),

        iconTheme: IconThemeData(color: colors.textPrimary),
      ),

      dividerTheme: DividerThemeData(
        color: colors.border,
        space: AppSizes.p24,
        thickness: 1,
      ),

      /// ✅ Updated Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: colors.fieldFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p16,
        ),

        // Normal border
        border: normalBorder,
        enabledBorder: normalBorder,

        // 🔥 Gradient Focus Border (Squircle Feel)
        focusedBorder: InputBorder.none,
        // GradientOutlineInputBorder(
        //   gradient: AppColors.inputFieldGradient,
        //   width: 1.5,
        //   borderRadius: BorderRadius.circular(radiusValue),
        // ),

        // Error
        errorBorder: normalBorder.copyWith(
          borderSide: BorderSide(color: colors.error, width: 1.2),
        ),

        focusedErrorBorder: normalBorder.copyWith(
          borderSide: BorderSide(color: colors.error, width: 1.4),
        ),

        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        labelStyle: TextStyle(color: colors.textSecondary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: colors.onBrand,
          minimumSize: const Size(double.infinity, 52),
          shape: squircleShape,
          textStyle: textTheme.labelLarge,
        ),
      ),

      /// Buttons (unchanged but cleaned)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: colors.onBrand,
          minimumSize: const Size(double.infinity, 52),
          shape: squircleShape,
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brand,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: colors.brand),
          shape: squircleShape,
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.link,
          textStyle: textTheme.labelMedium,
        ),
      ),

      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}

// class AppTheme {
//   AppTheme._();

//   static ThemeData light = _buildTheme(
//     brightness: Brightness.light,
//     colors: AppThemeColors.light,
//   );

//   static ThemeData dark = _buildTheme(
//     brightness: Brightness.dark,
//     colors: AppThemeColors.dark,
//   );

//   static ThemeData _buildTheme({
//     required Brightness brightness,
//     required AppThemeColors colors,
//   }) {
//     final scheme = ColorScheme.fromSeed(
//       seedColor: colors.brand,
//       brightness: brightness,
//       primary: colors.brand,
//       background: colors.background,
//       surface: colors.surface,
//       error: AppColors.error,
//     );

//     final textTheme = AppTextStyles.textTheme.apply(
//       bodyColor: colors.textPrimary,
//       displayColor: colors.textPrimary,
//     );

//     final radius = BorderRadius.circular(AppSizes.radiusLarge);
//     final border = OutlineInputBorder(
//       borderRadius: radius,

//       borderSide: BorderSide(color: colors.border, width: 1),
//     );

//     return ThemeData(
//       useMaterial3: true,
//       brightness: brightness,
//       colorScheme: scheme,
//       scaffoldBackgroundColor: colors.background,
//       textTheme: textTheme,
//       iconTheme: IconThemeData(color: colors.textPrimary),
//       appBarTheme: AppBarTheme(
//         backgroundColor: Colors.transparent,
//         foregroundColor: colors.textPrimary,
//         elevation: 0,
//         centerTitle: true,
//         titleTextStyle: textTheme.titleLarge,
//         iconTheme: IconThemeData(color: colors.textPrimary),
//       ),
//       dividerTheme: DividerThemeData(
//         color: colors.border,
//         space: AppSizes.p24,
//         thickness: 1,
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: colors.fieldFill,
//         isDense: true,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: AppSizes.p16,
//           vertical: AppSizes.p16,
//         ),
//         border: border,
//         enabledBorder: border,

//         focusedBorder: GradientOutlineInputBorder(
//           gradient: AppColors.inputFieldGradient,

//           borderRadius: (Constants.kInputFieldRadius),
//           width: 1.5,
//         ),
//         //  border.copyWith(
//         //   borderSide: BorderSide(color: colors.brand, width: 1.4),
//         // ),
//         errorBorder: border.copyWith(
//           borderSide: const BorderSide(color: AppColors.error, width: 1.2),
//         ),
//         focusedErrorBorder: border.copyWith(
//           borderSide: const BorderSide(color: AppColors.error, width: 1.4),
//         ),
//         hintStyle: TextStyle(color: colors.textSecondary),
//         labelStyle: TextStyle(color: colors.textSecondary),
//       ),
//       filledButtonTheme: FilledButtonThemeData(
//         style: FilledButton.styleFrom(
//           backgroundColor: colors.brand,
//           foregroundColor: colors.onBrand,
//           disabledBackgroundColor: scheme.onSurface.withOpacity(0.12),
//           disabledForegroundColor: scheme.onSurface.withOpacity(0.38),
//           minimumSize: const Size(double.infinity, 52),
//           shape: RoundedRectangleBorder(borderRadius: radius),
//           textStyle: textTheme.labelLarge,
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: colors.brand,
//           minimumSize: const Size(double.infinity, 52),
//           side: BorderSide(color: colors.brand),
//           shape: RoundedRectangleBorder(borderRadius: radius),
//           textStyle: textTheme.labelLarge,
//         ),
//       ),
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(
//           foregroundColor: colors.link,
//           textStyle: textTheme.labelMedium,
//         ),
//       ),
//       extensions: <ThemeExtension<dynamic>>[colors],
//     );
//   }
// }
