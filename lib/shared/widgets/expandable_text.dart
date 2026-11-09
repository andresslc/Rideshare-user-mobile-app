import 'package:flutter/material.dart';
import 'package:ride_app/core/core.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;

  const ExpandableText({super.key, required this.text, this.trimLines = 2});

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      style: context.textTheme.bodyMedium,
      maxLines: isExpanded ? null : widget.trimLines,
      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget,
        if (widget.text.length > 100)
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                isExpanded ? 'See Less' : 'See More',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.brand,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
