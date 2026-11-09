import 'package:flutter/material.dart';

import '../../core/extensions/theme_extension.dart';

/// A generic loading indicator widget.
class AppLoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const AppLoadingWidget({super.key, this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: color),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: context.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
