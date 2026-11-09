import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

class TransactionFilterHeader extends StatefulWidget {
  final String selectedCategory;
  final Function(String) onChanged;

  const TransactionFilterHeader({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  State<TransactionFilterHeader> createState() =>
      _TransactionFilterHeaderState();
}

class _TransactionFilterHeaderState extends State<TransactionFilterHeader>
    with SingleTickerProviderStateMixin {
  bool isOpen = false;
  double buttonWidth = 0;

  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotation;

  final categories = ['all', 'debit', 'credit'];

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _rotation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    if (isOpen) {
      _overlayEntry?.remove();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TransactionFilterHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      // Rebuild overlay if it's open and selected category changes from outside
      if (isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _overlayEntry?.markNeedsBuild();
        });
      }
    }
  }

  void _toggleDropdown() {
    if (isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    setState(() => isOpen = true);
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  void _closeDropdown() {
    _controller.reverse().then((_) {
      if (!mounted) return;
      setState(() => isOpen = false);
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final textTheme = context.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background dismiss region
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: buttonWidth,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 45),
              child: Material(
                color: Colors.transparent,
                child: SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: -1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        // ignore: deprecated_member_use
                        color: context.appColors.brand.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: categories.map((category) {
                          final isSelected =
                              widget.selectedCategory.toLowerCase() == category;

                          return InkWell(
                            onTap: () {
                              widget.onChanged(category);
                              _closeDropdown();
                            },
                            child: Container(
                              width: buttonWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    // ignore: deprecated_member_use
                                    ? context.appColors.brand.withOpacity(0.08)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                _categoryLabel(
                                  category: category,
                                  l10n: l10n,
                                  languageCode: languageCode,
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? context.appColors.brand
                                      : context.appColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    ///  Calculate dynamic width based on longest label
    final TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    double maxTextWidth = 0;

    for (var category in categories) {
      painter.text = TextSpan(
        text: _categoryLabel(
          category: category,
          l10n: l10n,
          languageCode: languageCode,
        ),
        style: textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      );

      painter.layout();
      if (painter.width > maxTextWidth) {
        maxTextWidth = painter.width;
      }
    }

    buttonWidth = maxTextWidth + 48;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ///  Title
          Expanded(
            child: Text(
              l10n.transactionHistory,
              style: textTheme.titleSmall?.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ///  Animated Dropdown Button
          CompositedTransformTarget(
            link: _layerLink,
            child: CustomTap(
              onTap: _toggleDropdown,
              child: AppGradientBox(
                borderWidth: 1.5,
                cornerRadius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: SizedBox(
                  width: buttonWidth - 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _categoryLabel(
                          category: widget.selectedCategory,
                          l10n: l10n,
                          languageCode: languageCode,
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textPrimary,
                        ),
                      ),

                      ///  Rotating Arrow
                      RotationTransition(
                        turns: _rotation,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel({
    required String category,
    required AppLocalizations l10n,
    required String languageCode,
  }) {
    switch (category) {
      case 'all':
        return l10n.all;
      case 'debit':
        return languageCode == 'es' ? 'Débito' : 'Debit';
      case 'credit':
        return languageCode == 'es' ? 'Crédito' : 'Credit';
      default:
        return category;
    }
  }
}
