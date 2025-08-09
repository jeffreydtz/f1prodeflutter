/// Custom Button Widget
///
/// Legacy wrapper around F1 button components for backward compatibility.
/// New code should use F1PrimaryButton, F1SecondaryButton, or F1TextButton directly.

import 'package:flutter/material.dart';
import 'f1_widgets.dart';

@Deprecated('Use F1PrimaryButton, F1SecondaryButton, or F1TextButton instead')
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final ButtonStyle style;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
    this.icon,
    this.isLoading = false,
    this.style = ButtonStyle.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case ButtonStyle.primary:
        return F1PrimaryButton(
          text: text,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
        );
      case ButtonStyle.secondary:
        return F1SecondaryButton(
          text: text,
          onPressed: onPressed,
          icon: icon,
          isLoading: isLoading,
          color: color,
        );
      case ButtonStyle.text:
        return F1TextButton(
          text: text,
          onPressed: onPressed,
          icon: icon,
          color: color,
        );
    }
  }
}

enum ButtonStyle {
  primary,
  secondary,
  text,
}
