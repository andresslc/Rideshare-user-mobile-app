import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// 🔹 Job Status Card
class JobStatusCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const JobStatusCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(title, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
