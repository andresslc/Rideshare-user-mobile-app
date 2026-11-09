import 'package:flutter/material.dart';

class DragHandlerWidget extends StatelessWidget {
  final DraggableScrollableController controller;
  final double minChildSize;
  final double maxChildSize;
  const DragHandlerWidget({
    super.key,
    required this.controller,
    required this.minChildSize,
    required this.maxChildSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          final height = MediaQuery.of(context).size.height;

          final newSize = controller.size - (details.primaryDelta! / height);

          controller.jumpTo(newSize.clamp(minChildSize, maxChildSize));
        },
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 2,
              width: 21,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
