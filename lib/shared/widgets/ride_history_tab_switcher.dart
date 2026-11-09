import 'package:flutter/material.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';

class RideHistoryTabSwitcher extends StatefulWidget {
  final List<String> tabs;
  final double height;
  final double width;
  final double radius;
  final Function(int)? onTabChanged;
  final int currentIndex;

  final Color? selectedBackgroundColor;
  final Color? unselectedBackgroundColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;

  const RideHistoryTabSwitcher({
    super.key,
    required this.tabs,
    this.height = 50,
    this.width = double.infinity,
    this.radius = 10,
    this.onTabChanged,
    this.currentIndex = 0,
    this.selectedBackgroundColor,
    this.unselectedBackgroundColor,
    this.selectedTextColor,
    this.unselectedTextColor,
  });

  @override
  State<RideHistoryTabSwitcher> createState() => _RideHistoryTabSwitcherState();
}

class _RideHistoryTabSwitcherState extends State<RideHistoryTabSwitcher>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void didUpdateWidget(covariant RideHistoryTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      setState(() {
        _selectedIndex = widget.currentIndex;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBg =
        widget.selectedBackgroundColor ?? context.appColors.brand;
    final unselectedBg = widget.unselectedBackgroundColor ?? Colors.transparent;

    final selectedText =
        widget.selectedTextColor ??
        Theme.of(context).textTheme.bodyMedium!
            .copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.button,
            )
            .color!;

    final unselectedText =
        widget.unselectedTextColor ?? context.appColors.textPrimary;

    return PlainBackgroundWidget(
      isAllRounded: true,
      isPlain: true,
      radius: 20,
      padding: const EdgeInsetsGeometry.all(2),
      child: SizedBox(
        height: widget.height,
        width: widget.width,

        child: Row(
          children: List.generate(widget.tabs.length, (i) {
            final selected = _selectedIndex == i;

            BorderRadius borderRadius = BorderRadius.circular(16);

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack, // subtle bounce feel
                margin: EdgeInsets.all(selected ? 2 : 4),
                decoration: ShapeDecoration(
                  color: selected ? selectedBg : unselectedBg,
                  shape: RoundedSuperellipseBorder(borderRadius: borderRadius),
                ),
                child: CustomTap(
                  // borderRadius: borderRadius,
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    widget.onTabChanged?.call(i);
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: selected ? selectedText : unselectedText,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                      child: Text(widget.tabs[i]),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
