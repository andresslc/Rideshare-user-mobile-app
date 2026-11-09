import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/features/settings/presentation/providers/change_language_provider.dart';
import 'package:ride_app/features/settings/presentation/widgets/language_selection_widget.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/shared.dart';

import '../../../../l10n/language_change_notifier.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    selectedLanguage = _mapLocaleToSelection(appLanguageNotifier.value);
  }

  String _mapLocaleToSelection(Locale locale) {
    return locale.languageCode == 'es' ? 'spanish' : 'english';
  }

  Locale _mapSelectionToLocale(String selection) {
    return selection == 'spanish'
        ? const Locale('es')
        : const Locale('en', 'US');
  }

  Future<void> _saveLanguage() async {
    final l10n = AppLocalizations.of(context)!;

    if (selectedLanguage == _mapLocaleToSelection(appLanguageNotifier.value)) {
      context.showToast(l10n.language_already_selected);
      return;
    }

    // Update locally
    final locale = _mapSelectionToLocale(selectedLanguage);
    await appLanguageNotifier.changeLanguage(locale);

    final languageCode = selectedLanguage == 'spanish' ? 'es' : 'en';
    await ref
        .read(changeLanguageProvider.notifier)
        .changeLanguage(languageCode);

    if (!mounted) return;
    context.showSuccessToast(l10n.language_updated_message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      scrollable: false,
      appBar: AppBar(
        title: Text(l10n.select_language)
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
      ),
      child: Column(
        children: [
          LanguageSelection(
                title: l10n.english,
                value: 'english',
                groupValue: selectedLanguage,
                onChanged: (val) {
                  setState(() {
                    selectedLanguage = val ?? 'english';
                  });
                },
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
          const Gap(AppSizes.p12),
          LanguageSelection(
                title: l10n.spanish,
                value: 'spanish',
                groupValue: selectedLanguage,
                onChanged: (val) {
                  setState(() {
                    selectedLanguage = val ?? 'spanish';
                  });
                },
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
          const Spacer(),
          AppButton(text: l10n.save, onPressed: _saveLanguage)
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
          const Gap(AppSizes.p16),
        ],
      ),
    );
  }
}
