// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:ride_app/shared/widgets/app_gradient_box.dart';

// class OtpInput extends StatefulWidget {
//   const OtpInput({
//     super.key,
//     this.length = 6,
//     this.onCompleted,
//     this.autoFocus = true,
//   });

//   final int length;
//   final ValueChanged<String>? onCompleted;
//   final bool autoFocus;

//   @override
//   State<OtpInput> createState() => _OtpInputState();
// }

// class _OtpInputState extends State<OtpInput> {
//   late final List<TextEditingController> _controllers;
//   late final List<FocusNode> _nodes;

//   @override
//   void initState() {
//     super.initState();
//     _controllers = List.generate(widget.length, (_) => TextEditingController());
//     _nodes = List.generate(widget.length, (i) => FocusNode());
//     if (widget.autoFocus && _nodes.isNotEmpty) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _nodes.first.requestFocus();
//       });
//     }
//   }

//   @override
//   void dispose() {
//     for (final controller in _controllers) {
//       controller.dispose();
//     }
//     for (final node in _nodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   void _handleChange(int index, String value) {
//     if (value.length == 1 && index < _nodes.length - 1) {
//       _nodes[index + 1].requestFocus();
//     }

//     final code = _controllers.map((c) => c.text).join();
//     if (code.length == widget.length) {
//       widget.onCompleted?.call(code);
//     }
//   }

//   void _handleKeyEvent(int index, RawKeyEvent event) {
//     if (event.isKeyPressed(LogicalKeyboardKey.backspace)) {
//       final currentText = _controllers[index].text;

//       if (currentText.isEmpty && index > 0) {
//         _controllers[index - 1].clear();
//         _nodes[index - 1].requestFocus();
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       spacing: 7,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(widget.length, (index) {
//         return Flexible(
//           child: AppGradientBox(
//             child: RawKeyboardListener(
//               focusNode: FocusNode(),
//               onKey: (event) => _handleKeyEvent(index, event),
//               child: TextField(
//                 controller: _controllers[index],
//                 focusNode: _nodes[index],
//                 textAlign: TextAlign.center,
//                 keyboardType: TextInputType.number,
//                 style: theme.textTheme.titleMedium,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                   LengthLimitingTextInputFormatter(1),
//                 ],
//                 onChanged: (value) => _handleChange(index, value),
//                 decoration: const InputDecoration(
//                   contentPadding: EdgeInsets.all(12),
//                   counterText: '',
//                   border: InputBorder.none,
//                 ),
//               ),
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:ride_app/core/theme/app_colors.dart';

class OtpInput extends StatelessWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.autoFocus = true,
    this.controller,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final bool autoFocus;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.12;

    final basePinTheme = PinTheme(
      width: boxSize,
      height: boxSize,
      textStyle: theme.textTheme.titleMedium,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brand, // green border
          width: .5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    return Center(
      child: Pinput(
        controller: controller,
        length: length,
        autofocus: autoFocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        defaultPinTheme: basePinTheme,
        focusedPinTheme: basePinTheme.copyWith(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brand,
              width: 2.2, // focused pe thora bold
            ),
          ),
        ),
        submittedPinTheme: basePinTheme,
        separatorBuilder: (index) => const SizedBox(width: 7),
        onCompleted: onCompleted,
      ),
    );
  }
}
