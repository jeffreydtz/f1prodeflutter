import 'package:flutter/material.dart';

/// Widget que proporciona un layout responsivo basado en el ancho de la pantalla.
/// Muestra diferentes layouts para web y móvil.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget webLayout;

  // Umbral para determinar si estamos en modo web o móvil
  static const int webBreakpoint = 768;

  const ResponsiveLayout({
    Key? key,
    required this.mobileLayout,
    required this.webLayout,
  }) : super(key: key);

  /// Determina si el contexto actual debe considerarse una vista web
  /// basado en el ancho de la ventana
  static bool isWeb(BuildContext context) {
    return MediaQuery.of(context).size.width >= webBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= webBreakpoint) {
          return webLayout;
        }
        return mobileLayout;
      },
    );
  }
}
