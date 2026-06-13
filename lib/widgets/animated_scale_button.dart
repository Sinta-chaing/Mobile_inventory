import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final FutureOr<void> Function() onTap;
  final double scaleFactor;
  final Color? loadingColor;

  const AnimatedScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.92,
    this.loadingColor,
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isLoading = false;

  double get _currentScale {
    if (_isLoading) return 1.0;
    if (_isPressed) return widget.scaleFactor;
    if (_isHovered) return 1.03;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final spinnerColor = widget.loadingColor ?? Colors.white;

    return MouseRegion(
      cursor: _isLoading ? SystemMouseCursors.wait : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _isLoading
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: _isLoading
            ? null
            : (_) async {
                setState(() => _isPressed = false);
                
                final result = widget.onTap();
                if (result is Future) {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    await result;
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                }
              },
        onTapCancel: _isLoading
            ? null
            : () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _currentScale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _isLoading ? 0.3 : 1.0,
                child: widget.child,
              ),
              if (_isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

