import 'package:flutter/material.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/services/places_search_service.dart';

/// Shared localized guidance. Only transient failures expose another request.
class AddressSearchError extends StatelessWidget {
  final PlacesFailure failure;
  final VoidCallback onRetry;
  const AddressSearchError({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = switch (failure.messageKey) {
      'address_search_outside_region' => l10n.address_search_outside_region,
      'address_search_unavailable' => l10n.address_search_unavailable,
      'address_search_incomplete' => l10n.address_search_incomplete,
      _ => l10n.address_search_failed,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          key: ValueKey(failure.messageKey),
          textAlign: TextAlign.center,
        ),
        if (failure.retryable)
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.address_search_retry),
          ),
      ],
    );
  }
}
