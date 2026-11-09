import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/extensions/theme_extension.dart';
import 'app_gradient_box.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.maxlines,
    this.radius,
    this.isPlain = false,
    this.textCapitalization = TextCapitalization.none,
    this.controller,
    this.focusNode,

    this.hintText = '',
    this.hintMaxLines,
    this.hintStyle,
    this.hintOverflow,
    this.labelText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onFieldSubmitted,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.maxLength,
    this.autofillHints,
    this.inputFormatters,
    this.readOnly = false,
    this.autoFocus = false,
    this.prefixPadding,
    this.prefixColor,
    this.isGreishText = false,
    this.showErrorOnlyWhenNotEmpty = false,
  });
  final int? maxlines;
  final num? radius;
  final bool isPlain;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final bool showErrorOnlyWhenNotEmpty;
  final FocusNode? focusNode;
  final String hintText;
  final int? hintMaxLines;
  final TextStyle? hintStyle;
  final TextOverflow? hintOverflow;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final bool autoFocus;
  final EdgeInsetsGeometry? prefixPadding;
  final Color? prefixColor;
  final bool isGreishText;

  TextStyle? _resolvedHintStyle(BuildContext context) {
    final themeHintStyle = Theme.of(context).inputDecorationTheme.hintStyle;
    final baseStyle = hintStyle ?? themeHintStyle;
    if (hintOverflow == null) return baseStyle;
    return (baseStyle ?? const TextStyle()).copyWith(overflow: hintOverflow);
  }

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    widget.controller?.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      _fieldKey.currentState?.didChange(widget.controller?.text);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderWidth = 1.0;
    final num cornerRadius = widget.radius ?? 16;

    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.controller?.text,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label
            if (widget.labelText != null && widget.labelText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  widget.labelText!,
                  style: context.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),

            AppGradientBox(
              isPlain: true,
              borderWidth: borderWidth,
              cornerRadius: cornerRadius.toDouble(),
              child: TextFormField(
                autofocus: widget.autoFocus,
                focusNode: widget.focusNode,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                maxLines: widget.maxlines,
                obscureText: _obscure,
                // validator: widget.validator,
                onChanged: (value) {
                  state.didChange(value);
                  widget.onChanged?.call(value);
                },
                onTap: widget.onTap,
                onFieldSubmitted: widget.onFieldSubmitted,
                enabled: widget.enabled,
                maxLength: widget.maxLength,
                autofillHints: widget.autofillHints,
                textCapitalization: widget.textCapitalization,
                inputFormatters: widget.inputFormatters,
                readOnly: widget.readOnly,
                style: !widget.enabled && widget.isGreishText
                    ? context.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.withValues(alpha: 0.6),
                      )
                    : context.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintMaxLines: widget.hintMaxLines,
                  hintStyle: widget._resolvedHintStyle(context),
                  // hintText: '',
                  // labelText: widget.labelText,
                  errorText: widget.errorText,
                  helperText: widget.helperText,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      cornerRadius.toDouble(),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,

                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),

                  prefixIcon: widget.prefixIcon != null
                      ? Padding(
                          padding:
                              widget.prefixPadding ??
                              const EdgeInsets.only(left: 16, right: 8),
                          child: Image.asset(
                            widget.prefixIcon!,
                            height: 20,
                            width: 20,
                            color: widget.prefixColor,
                          ),
                        )
                      : null,
                  suffixIcon: widget.obscureText
                      ? IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )
                      : widget.suffixIcon,
                ),
              ),
            ),

            if (state.errorText != null)
              // if (state.errorText != null && (state.value?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
