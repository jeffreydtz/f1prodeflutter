/// F1 Prode Widget Library
///
/// A collection of reusable widgets that implement the F1 design system.
/// Provides consistent UI components with built-in responsive behavior
/// and Formula 1 aesthetic principles.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/f1_theme.dart';

// =============================================================================
// BUTTONS
// =============================================================================

/// Primary F1 styled button with gradient background and racing aesthetics
class F1PrimaryButton extends StatefulWidget {
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
  State<F1PrimaryButton> createState() => _F1PrimaryButtonState();
}

class _F1PrimaryButtonState extends State<F1PrimaryButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  void _handleHover(bool hovered) {
    if (_isDisabled) return;
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(F1Theme.radiusXL);
    final gradient = _isDisabled
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [F1Theme.mediumGrey, F1Theme.darkGrey],
          )
        : (_hovered || _focused)
            ? F1Theme.telemetryGradient
            : F1Theme.f1RedGradient;
    final shadows = _isDisabled
        ? <BoxShadow>[]
        : (_hovered || _focused)
            ? F1Theme.softGlow(F1Theme.f1Red, spread: 22)
            : F1Theme.coloredShadow(F1Theme.f1Red);

    Widget button = MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: AnimatedScale(
          scale: _pressed
              ? 0.97
              : (_hovered || _focused)
                  ? 1.015
                  : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: borderRadius,
              boxShadow: shadows,
              border: Border.all(
                color: _focused
                    ? F1Theme.telemetryTeal.withOpacity(0.6)
                    : Colors.white.withOpacity(_hovered ? 0.08 : 0.04),
                width: 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isDisabled ? null : widget.onPressed,
                borderRadius: borderRadius,
                splashColor: Colors.white.withOpacity(0.15),
                highlightColor: Colors.white.withOpacity(0.05),
                onHighlightChanged: (value) {
                  if (_isDisabled) return;
                  setState(() => _pressed = value);
                },
                child: Padding(
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(
                        horizontal: F1Theme.xl,
                        vertical: F1Theme.m,
                      ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInBack,
                    child: widget.isLoading
                        ? const SizedBox(
                            key: ValueKey('primary-loading'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            key: const ValueKey('primary-content'),
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, size: 20),
                                const SizedBox(width: F1Theme.s),
                              ],
                              Text(
                                widget.text.toUpperCase(),
                                style: F1Theme.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Secondary F1 styled button with outline design
class F1SecondaryButton extends StatefulWidget {
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
  State<F1SecondaryButton> createState() => _F1SecondaryButtonState();
}

class _F1SecondaryButtonState extends State<F1SecondaryButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  void _handleHover(bool hovered) {
    if (_isDisabled) return;
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? F1Theme.telemetryTeal;
    final effectiveColor = _isDisabled ? F1Theme.borderGrey : accent;
    final borderRadius = BorderRadius.circular(F1Theme.radiusXL);
    final borderColor = _isDisabled
        ? F1Theme.borderGrey.withOpacity(0.8)
        : effectiveColor.withOpacity(_focused ? 0.95 : 0.7);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _isDisabled
          ? [
              Colors.white.withOpacity(0.02),
              Colors.white.withOpacity(0.0),
            ]
          : [
              Colors.white.withOpacity(_hovered ? 0.08 : 0.02),
              effectiveColor.withOpacity(_hovered ? 0.18 : 0.08),
            ],
    );
    final shadows = _isDisabled
        ? <BoxShadow>[]
        : _hovered
            ? F1Theme.softGlow(effectiveColor, spread: 14)
            : [
                BoxShadow(
                  color: effectiveColor.withOpacity(0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ];

    Widget button = MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: AnimatedScale(
          scale: _pressed
              ? 0.97
              : (_hovered || _focused)
                  ? 1.01
                  : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor,
                width: 1.4,
              ),
              gradient: gradient,
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: _isDisabled ? null : widget.onPressed,
                splashColor: effectiveColor.withOpacity(0.15),
                highlightColor: effectiveColor.withOpacity(0.05),
                onHighlightChanged: (value) {
                  if (_isDisabled) return;
                  setState(() => _pressed = value);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: F1Theme.xl,
                    vertical: F1Theme.m,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: widget.isLoading
                        ? SizedBox(
                            key: const ValueKey('secondary-loading'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: effectiveColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            key: const ValueKey('secondary-content'),
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon,
                                    size: 18, color: effectiveColor),
                                const SizedBox(width: F1Theme.s),
                              ],
                              Text(
                                widget.text,
                                style: F1Theme.labelLarge.copyWith(
                                  color: effectiveColor,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
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

    final style = TextButton.styleFrom(
      foregroundColor: buttonColor,
      padding: const EdgeInsets.symmetric(
        horizontal: F1Theme.m,
        vertical: F1Theme.s,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(F1Theme.radiusM),
      ),
      textStyle: F1Theme.labelMedium.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith(
        (states) => buttonColor.withOpacity(0.12),
      ),
      backgroundColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.hovered) ||
                states.contains(MaterialState.focused)
            ? buttonColor.withOpacity(0.12)
            : Colors.transparent,
      ),
    );

    return TextButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: F1Theme.s),
          ],
          Text(text),
        ],
      ),
    );
  }
}

// =============================================================================
// CARDS
// =============================================================================

/// Base F1 card component with consistent styling
class F1Card extends StatefulWidget {
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
  State<F1Card> createState() => _F1CardState();
}

class _F1CardState extends State<F1Card> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(F1Theme.radiusL);
    final surface = context.colors.surface;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        surface.withOpacity(0.92),
        surface.withOpacity(_hovered ? 0.55 : 0.68),
      ],
    );
    final border = widget.hasBorder
        ? Border.all(
            color: (widget.borderColor ?? F1Theme.borderGrey)
                .withOpacity(_hovered ? 0.6 : 0.35),
            width: 1.1,
          )
        : null;
    final shadows = _hovered
        ? F1Theme.softGlow(F1Theme.telemetryTeal.withOpacity(0.7), spread: 18)
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 16),
              spreadRadius: -12,
            ),
          ];

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(F1Theme.s),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: borderRadius,
              splashColor: F1Theme.f1Red.withOpacity(0.08),
              highlightColor: F1Theme.f1Red.withOpacity(0.03),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.elevation != null
                        ? 8 + (widget.elevation! * 1.5)
                        : 18,
                    sigmaY: widget.elevation != null
                        ? 8 + (widget.elevation! * 1.5)
                        : 18,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: widget.padding ?? const EdgeInsets.all(F1Theme.m),
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: gradient,
                      border: border,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Racing-themed card with checkered flag accent
class F1RaceCard extends StatefulWidget {
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
  State<F1RaceCard> createState() => _F1RaceCardState();
}

class _F1RaceCardState extends State<F1RaceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final borderRadius = BorderRadius.circular(F1Theme.radiusXL);
    final surface = context.colors.surface;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        surface.withOpacity(0.92),
        accent.withOpacity(_hovered ? 0.28 : 0.14),
      ],
    );
    final border = Border.all(
      color: accent.withOpacity(_hovered ? 0.6 : 0.35),
      width: 1.6,
    );

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(F1Theme.s),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: _hovered
                ? F1Theme.softGlow(accent, spread: 20)
                : F1Theme.coloredShadow(accent),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: borderRadius,
              splashColor: accent.withOpacity(0.18),
              highlightColor: accent.withOpacity(0.08),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: gradient,
                            border: border,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _hovered ? 1 : 0,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withOpacity(0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.showCheckeredFlag)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(F1Theme.radiusXL),
                              bottomLeft: Radius.circular(F1Theme.radiusM),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent,
                                accent.darken,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.sports_motorsports,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding:
                            widget.padding ?? const EdgeInsets.all(F1Theme.m),
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
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
