import 'package:flutter/material.dart';
import 'package:ride_app/core/core.dart';

class UserDriverTabSwitcher extends StatefulWidget {
  final List<String> tabs;
  final double height;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Function(int)? onTabChanged;

  const UserDriverTabSwitcher({
    super.key,
    this.tabs = const ["By User", "By Driver", "Carpool"],
    this.height = 50,
    this.selectedColor,
    this.unselectedColor,
    this.onTabChanged,
  });

  @override
  State<UserDriverTabSwitcher> createState() => _UserDriverTabSwitcherState();
}

class _UserDriverTabSwitcherState extends State<UserDriverTabSwitcher>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        widget.onTabChanged?.call(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          splashFactory: NoSplash.splashFactory,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 1.5, color: context.appColors.brand),
          ),
          labelColor: context.appColors.brand,
          unselectedLabelColor: widget.unselectedColor,
          labelStyle: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: context.textTheme.bodyLarge?.copyWith(),

          tabs: widget.tabs
              .map((tab) => SizedBox(height: 27, child: Text(tab)))
              .toList(),
        ),
      ],
    );
  }
}
