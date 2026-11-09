import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

/// Single option for [AppGradientOverlayDropdown].
class GradientDropdownItem<T> {
  const GradientDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Wallet-style dropdown: gradient trigger, animated overlay menu with brand border.
class AppGradientOverlayDropdown<T> extends StatefulWidget {
  const AppGradientOverlayDropdown({
    super.key,
    required this.items,
    required this.onSelected,
    this.selected,
    this.placeholder,
    this.expandTriggerWidth = false,
    this.overlayVerticalOffset = 45,
    this.enabled = true,
  });

  final T? selected;
  final List<GradientDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final String? placeholder;
  final bool expandTriggerWidth;
  final double overlayVerticalOffset;
  final bool enabled;

  @override
  State<AppGradientOverlayDropdown<T>> createState() =>
      _AppGradientOverlayDropdownState<T>();
}

class _AppGradientOverlayDropdownState<T>
    extends State<AppGradientOverlayDropdown<T>>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  double _buttonWidth = 0;

  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotation;

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
    if (_isOpen) {
      _overlayEntry?.remove();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppGradientOverlayDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && _isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlayEntry?.markNeedsBuild();
      });
    }
  }

  void _toggle() {
    if (!widget.enabled || widget.items.isEmpty) return;
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    setState(() => _isOpen = true);
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  void _close() {
    _controller.reverse().then((_) {
      if (!mounted) return;
      setState(() => _isOpen = false);
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  String _selectedLabel() {
    for (final item in widget.items) {
      if (item.value == widget.selected) return item.label;
    }
    return widget.placeholder ?? '';
  }

  OverlayEntry _createOverlayEntry() {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: _buttonWidth,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, widget.overlayVerticalOffset),
              child: Material(
                color: Colors.transparent,
                child: SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: -1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                        color: colors.brand.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.items.map((item) {
                          final isSelected = item.value == widget.selected;
                          return InkWell(
                            onTap: () {
                              widget.onSelected(item.value);
                              _close();
                            },
                            child: Container(
                              width: _buttonWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    // ignore: deprecated_member_use
                                    ? colors.brand.withOpacity(0.08)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                item.label,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? colors.brand
                                      : colors.textPrimary,
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

  double _computeIntrinsicWidth(TextStyle? style) {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    double maxW = 0;
    for (final item in widget.items) {
      painter.text = TextSpan(text: item.label, style: style);
      painter.layout();
      if (painter.width > maxW) maxW = painter.width;
    }
    if (widget.placeholder != null) {
      painter.text = TextSpan(text: widget.placeholder, style: style);
      painter.layout();
      if (painter.width > maxW) maxW = painter.width;
    }
    return maxW + 48;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.appColors;
    final labelStyle = textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );
    final displayLabel = _selectedLabel();
    final showPlaceholder =
        widget.selected == null &&
        widget.placeholder != null &&
        displayLabel == widget.placeholder;

    Widget buildTrigger(double width) {
      _buttonWidth = width;
      final innerMaxWidth = (width - 28).clamp(0.0, double.infinity);
      return CompositedTransformTarget(
        link: _layerLink,
        child: CustomTap(
          onTap: _toggle,
          radius: 16,
          child: AppGradientBox(
            borderWidth: 1.5,
            cornerRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
              width: widget.expandTriggerWidth ? null : innerMaxWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: widget.expandTriggerWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  if (widget.expandTriggerWidth)
                    Expanded(
                      child: Text(
                        displayLabel.isEmpty ? ' ' : displayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: showPlaceholder
                              ? colors.textSecondary
                              : colors.textPrimary,
                        ),
                      ),
                    )
                  else
                    Text(
                      displayLabel.isEmpty ? ' ' : displayLabel,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: showPlaceholder
                            ? colors.textSecondary
                            : colors.textPrimary,
                      ),
                    ),
                  RotationTransition(
                    turns: _rotation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.expandTriggerWidth) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 200.0;
          return SizedBox(width: w, child: buildTrigger(w));
        },
      );
    }

    _buttonWidth = _computeIntrinsicWidth(labelStyle);
    return buildTrigger(_buttonWidth);
  }
}
