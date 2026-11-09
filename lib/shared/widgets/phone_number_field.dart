import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

import '../../core/extensions/theme_extension.dart';

// class PhoneNumberField extends StatelessWidget {
//   const PhoneNumberField({
//     super.key,
//     required this.controller,
//     this.countryCode = ' +1',
//     this.onCountryTap,
//     this.errorText,
//     this.hintText = 'Add phone number',
//     this.enabled = true,
//   });

//   final TextEditingController controller;
//   final String countryCode;
//   final VoidCallback? onCountryTap;
//   final String? errorText;
//   final String hintText;
//   final bool enabled;

//   static String normalizeUsNumberForDisplay(String rawPhone) {
//     final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
//     if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
//       return digitsOnly.substring(1);
//     }
//     if (digitsOnly.length > 10) {
//       return digitsOnly.substring(digitsOnly.length - 10);
//     }
//     return digitsOnly;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomTap(
//           onTap: onCountryTap,
//           child: AppGradientBox(
//             isPlain: true,
//             borderWidth: 1.0,
//             cornerRadius: 20,
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Image.asset(AppIcons.usFlag, height: 30, width: 30),
//                 Text(
//                   countryCode,
//                   style: !enabled
//                       ? context.textTheme.bodyLarge?.copyWith(
//                           color: Colors.grey.withValues(alpha: .6),
//                         )
//                       : context.textTheme.bodyMedium,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: AppTextField(
//             controller: controller,
//             enabled: enabled,
//             hintText: hintText,
//             hintMaxLines: 1,
//             hintOverflow: TextOverflow.ellipsis,
//             // autoFocus: true,
//             maxLength: null,
//             isGreishText: true,

//             keyboardType: TextInputType.phone,
//             inputFormatters: [
//               MaskTextInputFormatter(
//                 mask: '(###) ###-####',
//                 filter: {"#": RegExp(r'[0-9]')},
//                 type: MaskAutoCompletionType.lazy,
//               ),
//             ],
//             errorText: errorText,
//             // validator: enabled ? Validators.validateUSPhoneNumber : null, //
//           ),
//         ),
//       ],
//     );
//   }
// }

class PhoneNumberField extends StatefulWidget {

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.focusNode,
    this.countryCode = '+1',
    this.onCountryTap,
    this.hintText = 'Add phone number',
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.errorText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String countryCode;
  final VoidCallback? onCountryTap;
  final String hintText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final String? errorText;
  final bool autofocus;

  static String normalizeUsNumberForDisplay(String rawPhone) {
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      return digitsOnly.substring(1);
    }

    if (digitsOnly.length > 10) {
      return digitsOnly.substring(digitsOnly.length - 10);
    }

    return digitsOnly;
  }

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late final MaskTextInputFormatter _formatter;

  @override
  void initState() {
    super.initState();

    _formatter = MaskTextInputFormatter(
      mask: '(###) ###-####',
      filter: {'#': RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTap(
          onTap: widget.onCountryTap,
          child: AppGradientBox(
            isPlain: true,
            borderWidth: 1,
            cornerRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppIcons.usFlag, height: 30, width: 30),
                const SizedBox(width:  8),
                Text(
                  widget.countryCode,
                  style: widget.enabled
                      ? context.textTheme.bodyMedium
                      : context.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.withValues(alpha: .6),
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: AppGradientBox(
            isPlain: true,
            borderWidth: 1,
            cornerRadius: 16,
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: widget.validator,
              inputFormatters: [_formatter],
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onFieldSubmitted,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: widget.enabled
                  ? context.textTheme.bodyLarge
                  : context.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.withValues(alpha: .6),
                    ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                errorText: widget.errorText,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
