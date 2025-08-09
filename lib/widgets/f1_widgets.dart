/// F1 Prode Widget Library
///
/// A collection of reusable widgets that implement the F1 design system.
/// Provides consistent UI components with built-in responsive behavior
/// and Formula 1 aesthetic principles.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/f1_theme.dart';

// =============================================================================
// BUTTONS
// =============================================================================

/// Primary F1 styled button with gradient background and racing aesthetics
class F1PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const F1PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      decoration: BoxDecoration(
        gradient: F1Theme.f1RedGradient,
        borderRadius: BorderRadius.circular(F1Theme.radiusM),
        boxShadow: F1Theme.coloredShadow(F1Theme.f1Red),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: F1Theme.l,
                vertical: F1Theme.m,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(F1Theme.radiusM),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: F1Theme.s),
                  ],
                  Text(
                    text,
                    style: F1Theme.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary F1 styled button with outline design
class F1SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final Color? color;

  const F1SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? F1Theme.f1Red;

    Widget button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        side: BorderSide(color: buttonColor, width: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: F1Theme.l,
          vertical: F1Theme.m,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(F1Theme.radiusM),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: buttonColor,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: F1Theme.s),
                ],
                Text(
                  text,
                  style: F1Theme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Ghost/Text button with F1 styling
class F1TextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const F1TextButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? F1Theme.f1Red;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(
          horizontal: F1Theme.m,
          vertical: F1Theme.s,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: F1Theme.s),
          ],
          Text(
            text,
            style: F1Theme.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CARDS
// =============================================================================

/// Base F1 card component with consistent styling
class F1Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double? elevation;
  final bool hasBorder;

  const F1Card({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.elevation,
    this.hasBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(F1Theme.s),
      child: Material(
        color: context.colors.surface,
        elevation: elevation ?? F1Theme.elevation2,
        borderRadius: BorderRadius.circular(F1Theme.radiusL),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(F1Theme.radiusL),
          child: Container(
            padding: padding ?? const EdgeInsets.all(F1Theme.m),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(F1Theme.radiusL),
              border: hasBorder
                  ? Border.all(
                      color: borderColor ?? F1Theme.borderGrey,
                      width: 1,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Racing-themed card with checkered flag accent
class F1RaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color accentColor;
  final bool showCheckeredFlag;

  const F1RaceCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.accentColor = F1Theme.f1Red,
    this.showCheckeredFlag = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(F1Theme.s),
      child: Material(
        color: context.colors.surface,
        elevation: F1Theme.elevation2,
        borderRadius: BorderRadius.circular(F1Theme.radiusL),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(F1Theme.radiusL),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(F1Theme.radiusL),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colors.surface,
                  accentColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Checkered flag pattern (optional)
                if (showCheckeredFlag)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(F1Theme.radiusL),
                          bottomLeft: Radius.circular(F1Theme.radiusM),
                        ),
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.darken],
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_motorsports,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: padding ?? const EdgeInsets.all(F1Theme.m),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// INPUTS
// =============================================================================

/// F1 styled text field with racing aesthetics
class F1TextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;

  const F1TextField({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: F1Theme.labelMedium.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: F1Theme.s),
        ],
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          onTap: onTap,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          style: F1Theme.bodyMedium.copyWith(
            color: context.colors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
            filled: true,
            fillColor: context.colors.surface == F1Theme.carbonBlack
                ? F1Theme.mediumGrey
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(F1Theme.radiusM),
              borderSide: BorderSide(
                color: F1Theme.borderGrey,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(F1Theme.radiusM),
              borderSide: BorderSide(
                color: F1Theme.borderGrey,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(F1Theme.radiusM),
              borderSide: const BorderSide(
                color: F1Theme.f1Red,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(F1Theme.radiusM),
              borderSide: const BorderSide(
                color: F1Theme.errorRed,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(F1Theme.radiusM),
              borderSide: const BorderSide(
                color: F1Theme.errorRed,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// INDICATORS
// =============================================================================

/// Position indicator with F1 podium colors
class F1PositionIndicator extends StatelessWidget {
  final int position;
  final double size;
  final bool showBackground;

  const F1PositionIndicator({
    Key? key,
    required this.position,
    this.size = 36,
    this.showBackground = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = F1Theme.getPositionColor(position);

    return Container(
      width: size,
      height: size,
      decoration: showBackground
          ? BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: F1Theme.coloredShadow(color),
            )
          : null,
      child: Center(
        child: Text(
          '$position°',
          style: F1Theme.labelMedium.copyWith(
            color: showBackground ? F1Theme.getContrastColor(color) : color,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

/// Team color indicator
class F1TeamIndicator extends StatelessWidget {
  final String? teamName;
  final double size;
  final bool showBorder;

  const F1TeamIndicator({
    Key? key,
    this.teamName,
    this.size = 24,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = F1Theme.getTeamColor(teamName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: 2,
              )
            : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Points indicator with racing style
class F1PointsIndicator extends StatelessWidget {
  final int points;
  final int? deltaPoints;
  final bool showDelta;
  final TextStyle? style;

  const F1PointsIndicator({
    Key? key,
    required this.points,
    this.deltaPoints,
    this.showDelta = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$points',
          style: style ??
              F1Theme.headlineSmall.copyWith(
                fontWeight: FontWeight.w900,
                color: F1Theme.f1Red,
              ),
        ),
        const SizedBox(width: F1Theme.xs),
        Text(
          'pts',
          style: F1Theme.bodySmall.copyWith(
            color: F1Theme.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showDelta && deltaPoints != null) ...[
          const SizedBox(width: F1Theme.s),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: F1Theme.s,
              vertical: F1Theme.xs,
            ),
            decoration: BoxDecoration(
              color:
                  deltaPoints! >= 0 ? F1Theme.successGreen : F1Theme.errorRed,
              borderRadius: BorderRadius.circular(F1Theme.radiusS),
            ),
            child: Text(
              '${deltaPoints! >= 0 ? '+' : ''}$deltaPoints',
              style: F1Theme.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// LOADING AND STATES
// =============================================================================

/// F1 themed loading indicator
class F1LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const F1LoadingIndicator({
    Key? key,
    this.message,
    this.size = 40,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color ?? F1Theme.f1Red,
            strokeWidth: 3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: F1Theme.m),
          Text(
            message!,
            style: F1Theme.bodyMedium.copyWith(
              color: F1Theme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Empty state with F1 theming
class F1EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const F1EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(F1Theme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: F1Theme.textGrey,
            ),
            const SizedBox(height: F1Theme.l),
            Text(
              title,
              style: F1Theme.headlineSmall.copyWith(
                color: context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: F1Theme.s),
              Text(
                subtitle!,
                style: F1Theme.bodyMedium.copyWith(
                  color: F1Theme.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: F1Theme.l),
              F1PrimaryButton(
                text: actionText!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with F1 theming
class F1ErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const F1ErrorState({
    Key? key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(F1Theme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: F1Theme.errorRed,
            ),
            const SizedBox(height: F1Theme.l),
            Text(
              title,
              style: F1Theme.headlineSmall.copyWith(
                color: F1Theme.errorRed,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: F1Theme.s),
              Text(
                subtitle!,
                style: F1Theme.bodyMedium.copyWith(
                  color: F1Theme.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: F1Theme.l),
              F1SecondaryButton(
                text: actionText!,
                onPressed: onAction,
                color: F1Theme.errorRed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// NAVIGATION
// =============================================================================

/// F1 themed bottom navigation item
class F1BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget? badge;

  const F1BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// F1 themed bottom navigation bar
class F1BottomNavigation extends StatelessWidget {
  final List<F1BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final bool showLabels;

  const F1BottomNavigation({
    Key? key,
    required this.items,
    required this.currentIndex,
    this.onTap,
    this.backgroundColor,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.surface,
        border: const Border(
          top: BorderSide(
            color: F1Theme.borderGrey,
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: F1Theme.m,
            vertical: F1Theme.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap?.call(index),
                  borderRadius: BorderRadius.circular(F1Theme.radiusM),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: F1Theme.s,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Icon(
                              isSelected && item.activeIcon != null
                                  ? item.activeIcon!
                                  : item.icon,
                              color:
                                  isSelected ? F1Theme.f1Red : F1Theme.textGrey,
                              size: 24,
                            ),
                            if (item.badge != null)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: item.badge!,
                              ),
                          ],
                        ),
                        if (showLabels) ...[
                          const SizedBox(height: F1Theme.xs),
                          Text(
                            item.label,
                            style: F1Theme.labelSmall.copyWith(
                              color:
                                  isSelected ? F1Theme.f1Red : F1Theme.textGrey,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
