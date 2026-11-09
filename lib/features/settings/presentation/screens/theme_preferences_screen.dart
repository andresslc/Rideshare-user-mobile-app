import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/theme/theme_notifier.dart';
import 'package:ride_app/features/settings/presentation/widgets/theme_preference_widget.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/shared.dart';

class ThemePreferencesScreen extends StatefulWidget {
  const ThemePreferencesScreen({super.key});

  @override
  State<ThemePreferencesScreen> createState() => _ThemePreferencesScreenState();
}

class _ThemePreferencesScreenState extends State<ThemePreferencesScreen> {
  late String selectedTheme;

  @override
  void initState() {
    super.initState();
    selectedTheme = locator<ThemeNotifier>().selectedTheme;
  }

  void _onThemeChanged(String? val) {
    if (val == null) return;
    setState(() {
      selectedTheme = val;
    });

    final notifier = locator<ThemeNotifier>();
    switch (val) {
      case 'light':
        notifier.setLight();
      case 'dark':
        notifier.setDark();
      case 'automatic':
        notifier.setAutomatic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.themePreferences)
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
      ),
      child: Column(
        children: [
          ThemePreferencesWidget(
                title: l10n.themeAutomatic,
                subtitle: l10n.themeAutomaticSubtitle,
                value: 'automatic',
                groupValue: selectedTheme,
                onChanged: _onThemeChanged,
              )
              .animate(delay: 300.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.2, end: 0),

          const Gap(AppSizes.p12),
          ThemePreferencesWidget(
            title: l10n.themeDark,
            subtitle: l10n.themeDarkSubtitle,
            value: 'dark',
            groupValue: selectedTheme,
            onChanged: _onThemeChanged,
          ).animate(delay: 400.ms).fade(duration: 250.ms).slideY(begin: 0.2),
          const Gap(AppSizes.p12),
          ThemePreferencesWidget(
            title: l10n.themeLight,
            subtitle: l10n.themeLightSubtitle,
            value: 'light',
            groupValue: selectedTheme,
            onChanged: _onThemeChanged,
          ).animate(delay: 500.ms).fade(duration: 250.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}

// import 'package:ride_app/core/constants/app_sizes.dart';
// import 'package:ride_app/core/di/service_locator.dart';
// import 'package:ride_app/core/theme/theme_notifier.dart';
// import 'package:ride_app/features/settings/presentation/widgets/theme_preference_widget.dart';
// import 'package:ride_app/l10n/app_localizations.dart';
// import 'package:ride_app/shared/shared.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:gap/gap.dart';

// class ThemePreferencesScreen extends StatefulWidget {
//   const ThemePreferencesScreen({super.key});

//   @override
//   State<ThemePreferencesScreen> createState() => _ThemePreferencesScreenState();
// }

// class _ThemePreferencesScreenState extends State<ThemePreferencesScreen> {
//   late String selectedTheme;

//   @override
//   void initState() {
//     super.initState();
//     selectedTheme = locator<ThemeNotifier>().selectedTheme;
//   }

//   void _onThemeChanged(String? val) {
//     if (val == null) return;

//     setState(() {
//       selectedTheme = val;
//     });

//     final notifier = locator<ThemeNotifier>();

//     switch (val) {
//       case 'light':
//         notifier.setLight();
//         break;
//       case 'dark':
//         notifier.setDark();
//         break;
//       case 'automatic':
//         notifier.setAutomatic();
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;

//     final themes = [
//       {
//         'title': l10n.themeAutomatic,
//         'subtitle': l10n.themeAutomaticSubtitle,
//         'value': 'automatic',
//       },
//       {
//         'title': l10n.themeDark,
//         'subtitle': l10n.themeDarkSubtitle,
//         'value': 'dark',
//       },
//       {
//         'title': l10n.themeLight,
//         'subtitle': l10n.themeLightSubtitle,
//         'value': 'light',
//       },
//     ];

//     return AppScaffold(
//       appBar: AppBar(
//         title: Text(l10n.themePreferences)
//             .animate()
//             .fadeIn(duration: 400.ms)
//             .scale(
//               begin: const Offset(0.85, 0.85),
//               end: const Offset(1, 1),
//               curve: Curves.easeOutBack,
//             ),
//       ),
//       child: Column(
//         children: List.generate(themes.length, (index) {
//           final item = themes[index];

//           return Column(
//             children: [
//               ThemePreferencesWidget(
//                     title: item['title']!,
//                     subtitle: item['subtitle']!,
//                     value: item['value']!,
//                     groupValue: selectedTheme,
//                     onChanged: _onThemeChanged,
//                   )
//                   .animate(delay: (120 * index).ms)
//                   .fadeIn(duration: 350.ms)
//                   .slideY(begin: 0.15, end: 0),

//               const Gap(AppSizes.p12),
//             ],
//           );
//         }),
//       ),
//     );
//   }
// }
