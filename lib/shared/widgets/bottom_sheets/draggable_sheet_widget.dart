import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/shared.dart';

class DraggableSheetWidget extends StatefulWidget {
  final String title;
  final String buttonText;
  final Widget? child;
  final bool isButtonAvailable;
  final double heightFactor;
  final bool sizeToContent;
  final EdgeInsetsGeometry? padding;

  final Function()? onSubmit;

  const DraggableSheetWidget({
    super.key,
    this.title = '',
    this.child,
    this.onSubmit,
    this.buttonText = '',
    this.isButtonAvailable = true,
    this.heightFactor = 0.7,
    this.sizeToContent = false,
    this.padding,
    this.expandOnFocusNodes,
  });

  final List<FocusNode>? expandOnFocusNodes;

  @override
  State<DraggableSheetWidget> createState() => _DraggableSheetWidgetState();
}

class _DraggableSheetWidgetState extends State<DraggableSheetWidget> {
  double _sheetHeightFactor = 0.7;
  final double _minFactor = 0.6;
  final double _maxFactor = 0.95;

  @override
  void initState() {
    super.initState();
    _sheetHeightFactor = widget.heightFactor;
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    if (!widget.sizeToContent && widget.expandOnFocusNodes != null) {
      for (final node in widget.expandOnFocusNodes!) {
        node.addListener(_handleFocusChange);
      }
    }
  }

  void _removeFocusListeners() {
    if (!widget.sizeToContent && widget.expandOnFocusNodes != null) {
      for (final node in widget.expandOnFocusNodes!) {
        node.removeListener(_handleFocusChange);
      }
    }
  }

  void _handleFocusChange() {
    final anyFocused = widget.expandOnFocusNodes!.any((node) => node.hasFocus);
    if (anyFocused && _sheetHeightFactor < _maxFactor) {
      setState(() {
        _sheetHeightFactor = _maxFactor;
      });
    }
  }

  @override
  void dispose() {
    _removeFocusListeners();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DraggableSheetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heightFactor != widget.heightFactor) {
      setState(() {
        _sheetHeightFactor = widget.heightFactor;
      });
    }
    if (oldWidget.expandOnFocusNodes != widget.expandOnFocusNodes ||
        oldWidget.sizeToContent != widget.sizeToContent) {
      _removeFocusListeners();
      _setupFocusListeners();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _sheetHeightFactor -=
          details.primaryDelta! / MediaQuery.of(context).size.height;
      _sheetHeightFactor = _sheetHeightFactor.clamp(_minFactor, _maxFactor);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final double midPoint = (_minFactor + _maxFactor) / 2;
    if (_sheetHeightFactor <= _minFactor + 0.02) {
      context.pop();
    } else {
      setState(() {
        if (_sheetHeightFactor < midPoint) {
          _sheetHeightFactor = _minFactor;
        } else {
          _sheetHeightFactor = _maxFactor;
        }
      });
    }
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final sheetContent = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      child: Stack(
        children: [
          if (context.colorScheme.brightness == Brightness.dark) ...[
            Positioned.fill(
              child: Image.asset(
                AppImages.bgThree,
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                // ignore: deprecated_member_use
                child: Container(color: Colors.white.withOpacity(0.05)),
              ),
            ),
          ],
          Focus(
            onFocusChange: (hasFocus) {
              if (!widget.sizeToContent &&
                  widget.expandOnFocusNodes == null &&
                  hasFocus &&
                  _sheetHeightFactor < _maxFactor) {
                setState(() {
                  _sheetHeightFactor = _maxFactor;
                });
              }
            },
            child: Container(
              width: double.infinity,
              color: context.colorScheme.brightness == Brightness.dark
                  ? Colors.transparent
                  : Colors.white,
              padding:
                  widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: widget.sizeToContent
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          if (widget.child != null) widget.child!,
                          const SizedBox(height: 16),
                          if (widget.isButtonAvailable)
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: widget.buttonText,
                                onPressed: widget.onSubmit,
                              ),
                            ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildHeader(),
                        if (widget.child != null) Expanded(child: widget.child!),
                        const SizedBox(height: 16),
                        if (widget.isButtonAvailable)
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              text: widget.buttonText,
                              onPressed: widget.onSubmit,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );

    if (widget.sizeToContent) {
      return SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * _maxFactor,
              ),
              child: sheetContent,
            ),
          ),
        ),
      );
    }

    return FractionallySizedBox(
      heightFactor: _sheetHeightFactor,
      child: sheetContent,
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: widget.sizeToContent ? null : _onDragUpdate,
      onVerticalDragEnd: widget.sizeToContent ? null : _onDragEnd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (widget.title.isNotEmpty)
            Center(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
