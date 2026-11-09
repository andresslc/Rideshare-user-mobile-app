import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

class InputDialog extends StatefulWidget {
  final String subtitle;
  final String title;
  final int maxLines;
  final String? hintText;
  final String buttonText;
  final String? fieldLabel;
  final bool showFieldLabel;
  final bool isRequired;
  final int maxLength;
  final void Function(String description)? onSubmit;
  final void Function(String description)? onChange;
  final bool isLoading;
  final TextCapitalization textCapitalization;
  final String? errorMessage;
  final String? prefilText;
  final List<TextInputFormatter>? inputFormatters;

  const InputDialog({
    super.key,
    this.isRequired = true,
    required this.subtitle,
    this.onSubmit,
    this.hintText,
    this.buttonText = "Submit",
    this.fieldLabel,
    this.showFieldLabel = false,
    this.textCapitalization = TextCapitalization.characters,
    required this.title,
    this.prefilText,
    this.maxLines = 3,
    this.maxLength = 250,
    this.isLoading = false,
    this.errorMessage,
    this.onChange,
    this.inputFormatters,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.prefilText?.isNotEmpty ?? false) {
      descriptionController.text = widget.prefilText!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool isDisabled =
        descriptionController.text.trim().isEmpty || widget.isLoading;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AppGradientBox(
        isPlain: context.theme.brightness == Brightness.light,
        padding: const EdgeInsets.all(16).copyWith(top: 14),
        cornerRadius: 11,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title + Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: context.textTheme.titleSmall?.copyWith(fontSize: 20),
                ),
                CustomTap(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.close),
                ),
              ],
            ),

            // Subtitle
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),

            // Field label
            if (widget.showFieldLabel && widget.fieldLabel != null) ...[
              Row(
                children: [
                  Image.asset(AppIcons.discount, width: 16, height: 16),
                  const SizedBox(width: 8),
                  Text(widget.fieldLabel!, style: context.textTheme.titleSmall),
                ],
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
            ],

            // Input
            AppTextField(
              radius: 10,
              hintText: widget.hintText?.isNotEmpty == true
                  ? widget.hintText!
                  : "Reason",
              inputFormatters: widget.inputFormatters,
              maxLength: widget.maxLength,
              controller: descriptionController,
              validator: (value) {
                final text = (value ?? '').trim();
                if (!widget.isRequired) return null;
                if (text.isEmpty) return l10n.field_required;
                return null;
              },
              maxlines: widget.maxLines,
              isPlain: true,
              textCapitalization: widget.textCapitalization,
              onChanged: (value) {
                setState(() {});
                widget.onChange?.call(value);
              },
              enabled: !widget.isLoading,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),

            if (descriptionController.text.isNotEmpty &&
                widget.errorMessage != null &&
                widget.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.errorMessage!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.appColors.error,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Button
            Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    text: widget.buttonText,
                    isDisable: isDisabled,
                    isLoading: widget.isLoading,
                    onPressed: isDisabled
                        ? null
                        : () {
                            widget.onSubmit?.call(
                              descriptionController.text.trim(),
                            );
                          },
                  ),
                )
                .animate()
                .scale(duration: 250.ms, curve: Curves.easeOutBack)
                .fadeIn(),
          ],
        ),
      ),
    );
  }
}
