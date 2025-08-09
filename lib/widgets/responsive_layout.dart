import 'package:flutter/material.dart';
import '../theme/f1_theme.dart';

/// Advanced responsive layout widget that provides multiple breakpoints
/// and layout options optimized for F1 Prode's design system.
class ResponsiveLayout extends StatelessWidget {
  final Widget? mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;
  final Widget? webLayout; // Fallback for backward compatibility

  const ResponsiveLayout({
    Key? key,
    this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
    this.webLayout, // Backward compatibility
  }) : super(key: key);

  /// Legacy constructor for backward compatibility
  const ResponsiveLayout.simple({
    Key? key,
    required Widget mobileLayout,
    required Widget webLayout,
  })  : mobileLayout = mobileLayout,
        tabletLayout = null,
        desktopLayout = null,
        webLayout = webLayout,
        super(key: key);

  /// Determines if the context should be considered mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < F1Theme.mobileBreakpoint;
  }

  /// Determines if the context should be considered tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= F1Theme.mobileBreakpoint &&
        width < F1Theme.tabletBreakpoint;
  }

  /// Determines if the context should be considered desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= F1Theme.tabletBreakpoint;
  }

  /// Legacy web check for backward compatibility
  static bool isWeb(BuildContext context) {
    return MediaQuery.of(context).size.width >= F1Theme.mobileBreakpoint;
  }

  /// Get the current breakpoint type
  static BreakpointType getBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < F1Theme.mobileBreakpoint) {
      return BreakpointType.mobile;
    } else if (width < F1Theme.tabletBreakpoint) {
      return BreakpointType.tablet;
    } else {
      return BreakpointType.desktop;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Mobile layout
        if (width < F1Theme.mobileBreakpoint) {
          return mobileLayout ?? webLayout ?? const SizedBox();
        }

        // Tablet layout
        if (width < F1Theme.tabletBreakpoint) {
          return tabletLayout ??
              desktopLayout ??
              webLayout ??
              mobileLayout ??
              const SizedBox();
        }

        // Desktop layout
        return desktopLayout ??
            webLayout ??
            tabletLayout ??
            mobileLayout ??
            const SizedBox();
      },
    );
  }
}

/// Breakpoint types for responsive design
enum BreakpointType {
  mobile,
  tablet,
  desktop,
}

/// Responsive grid widget that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = F1Theme.m,
    this.runSpacing = F1Theme.m,
    this.childAspectRatio = 1.0,
    this.padding = const EdgeInsets.all(F1Theme.m),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _buildGrid(context, mobileColumns),
      tabletLayout: _buildGrid(context, tabletColumns),
      desktopLayout: _buildGrid(context, desktopColumns),
    );
  }

  Widget _buildGrid(BuildContext context, int columns) {
    return Padding(
      padding: padding,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Responsive wrap widget that adjusts layout based on screen size
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry padding;

  const ResponsiveWrap({
    Key? key,
    required this.children,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.spacing = F1Theme.m,
    this.runSpacing = F1Theme.m,
    this.padding = const EdgeInsets.all(F1Theme.m),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Wrap(
        alignment: alignment,
        runAlignment: runAlignment,
        spacing: spacing,
        runSpacing: runSpacing,
        children: children,
      ),
    );
  }
}

/// Responsive container that adapts max width based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;
  final EdgeInsetsGeometry padding;
  final bool center;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.mobileMaxWidth,
    this.tabletMaxWidth = 600,
    this.desktopMaxWidth = 1200,
    this.padding = const EdgeInsets.all(F1Theme.m),
    this.center = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _buildContainer(context, mobileMaxWidth),
      tabletLayout: _buildContainer(context, tabletMaxWidth),
      desktopLayout: _buildContainer(context, desktopMaxWidth),
    );
  }

  Widget _buildContainer(BuildContext context, double? maxWidth) {
    Widget container = Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: padding,
      child: child,
    );

    return center ? Center(child: container) : container;
  }
}

/// Value class that returns different values based on screen size
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  T getValue(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) {
      return mobile;
    } else if (ResponsiveLayout.isTablet(context)) {
      return tablet ?? desktop ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }
}

/// Extension to easily get responsive values
extension ResponsiveValueExtension<T> on T {
  ResponsiveValue<T> get responsive => ResponsiveValue(mobile: this);

  ResponsiveValue<T> tablet(T value) => ResponsiveValue(
        mobile: this,
        tablet: value,
      );

  ResponsiveValue<T> desktop(T value) => ResponsiveValue(
        mobile: this,
        desktop: value,
      );

  ResponsiveValue<T> allBreakpoints({T? tablet, T? desktop}) => ResponsiveValue(
        mobile: this,
        tablet: tablet,
        desktop: desktop,
      );
}
