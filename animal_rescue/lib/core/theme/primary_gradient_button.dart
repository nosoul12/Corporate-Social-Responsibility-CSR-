import 'package:flutter/material.dart';
import 'package:animal_rescue_app/core/theme/app_theme.dart';

class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    this.borderRadius = AppTheme.cornerRadius,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double borderRadius;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withOpacity(0.12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryButtonGradient,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Opacity(
            opacity: isDisabled ? 0.6 : 1,
            child: Container(
              width: expand ? double.infinity : null,
              padding: padding,
              alignment: Alignment.center,
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
