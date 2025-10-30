import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/f1_theme.dart';

/// Animated background used across the app to reinforce the F1 brand.
/// Combines layered gradients, moving telemetry lines, and soft glows.
class F1AppBackground extends StatelessWidget {
  final Widget? child;

  const F1AppBackground({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _AnimatedNightRaceBackdrop()),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

class _AnimatedNightRaceBackdrop extends StatefulWidget {
  const _AnimatedNightRaceBackdrop();

  @override
  State<_AnimatedNightRaceBackdrop> createState() =>
      _AnimatedNightRaceBackdropState();
}

class _AnimatedNightRaceBackdropState extends State<_AnimatedNightRaceBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final rotation = _controller.value * 2 * math.pi;
          final sweep = (_controller.value * 0.65) + 0.35;
          final glowAlignment = Alignment(
            math.cos(rotation) * 0.35,
            math.sin(rotation) * 0.35,
          );

          return Container(
            decoration: const BoxDecoration(
              gradient: F1Theme.nightRaceGradient,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: glowAlignment,
                        radius: 1.2,
                        colors: [
                          F1Theme.hyperdrivePurple.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        startAngle: 0,
                        endAngle: 2 * math.pi,
                        transform: GradientRotation(rotation / 2),
                        colors: [
                          F1Theme.pulsePink.withOpacity(0.05 * sweep),
                          Colors.transparent,
                          F1Theme.telemetryTeal.withOpacity(0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter:
                        _TelemetryLinesPainter(progress: _controller.value),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(color: Colors.black.withOpacity(0.35)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TelemetryLinesPainter extends CustomPainter {
  final double progress;

  const _TelemetryLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final diagonalPaint = Paint()
      ..color = F1Theme.telemetryTeal.withOpacity(0.12)
      ..strokeWidth = 1.2;

    final accentPaint = Paint()
      ..color = F1Theme.pulsePink.withOpacity(0.08)
      ..strokeWidth = 1.8;

    final spacing = 140.0;
    final offset = progress * spacing;

    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      final start = Offset(x + offset, 0);
      final end = Offset(x + offset - size.height, size.height);
      canvas.drawLine(start, end, diagonalPaint);
    }

    final accentOffset = (progress * size.width) % size.width;
    canvas.drawLine(
      Offset(accentOffset, 0),
      Offset(accentOffset - size.height, size.height),
      accentPaint,
    );

    final circles = 3;
    for (var i = 0; i < circles; i++) {
      final normalized = (progress + (i / circles)) % 1.0;
      final center = Offset(
        (0.2 + normalized * 0.6) * size.width,
        (0.3 + math.sin(normalized * 2 * math.pi) * 0.2) * size.height,
      );
      final radius = size.shortestSide * (0.15 + normalized * 0.25);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = F1Theme.f1Red.withOpacity(0.05 + normalized * 0.08);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TelemetryLinesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
