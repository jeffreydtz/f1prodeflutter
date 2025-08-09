/// F1 Prode Theme System
///
/// Provides a comprehensive design system inspired by Formula 1 aesthetics.
/// Features minimalistic design with emphasis on speed, precision, and modern UI patterns.
/// Optimized for both mobile and web platforms.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class F1Theme {
  // Private constructor to prevent instantiation
  F1Theme._();

  // CORE BRAND COLORS
  static const Color f1Red = Color(0xFFFF1801);
  static const Color f1RedDark = Color(0xFFE61601);
  static const Color f1RedLight = Color(0xFFFF4B3D);

  // NEUTRAL COLORS
  static const Color carbonBlack = Color(0xFF0C0C0C);
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const Color mediumGrey = Color(0xFF2D2D2D);
  static const Color lightGrey = Color(0xFF404040);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color borderGrey = Color(0xFF333333);

  // ACCENT COLORS
  static const Color championGold = Color(0xFFFFD700);
  static const Color silverSecond = Color(0xFFC0C0C0);
  static const Color bronzeThird = Color(0xFFCD7F32);
  static const Color safetyYellow = Color(0xFFFFC107);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

  // TEAM COLORS
  static const Map<String, Color> teamColors = {
    'Mercedes': Color(0xFF00D2BE),
    'Red Bull Racing': Color(0xFF3671C6),
    'Ferrari': Color(0xFFDC0000),
    'McLaren': Color(0xFFFF8700),
    'Aston Martin': Color(0xFF006F62),
    'Alpine': Color(0xFF0090FF),
    'Williams': Color(0xFF005AFF),
    'Visa Cash App RB': Color(0xFF6A8FB9),
    'Sauber': Color(0xFF01E84A),
    'Haas F1 Team': Color(0xFFFFFFFF),
  };

  // TYPOGRAPHY SCALE
  static const String primaryFontFamily = 'SF Pro Display';
  static const String codeFontFamily = 'SF Mono';

  // TEXT STYLES
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.2,
    color: Colors.white,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.3,
    color: Colors.white,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Colors.white,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Colors.white,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Colors.white,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Colors.white,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: Colors.white,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: Colors.white,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.5,
    color: Colors.white,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Colors.white,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Colors.white,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textGrey,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: Colors.white,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: Colors.white,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: textGrey,
  );

  // SPACING SCALE
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // BORDER RADIUS
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // ELEVATION
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 4.0;
  static const double elevation4 = 8.0;
  static const double elevation5 = 16.0;

  // BREAKPOINTS
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  // MAIN THEME DATA
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,

      // COLOR SCHEME
      colorScheme: ColorScheme.fromSeed(
        seedColor: f1Red,
        brightness: brightness,
        primary: f1Red,
        secondary: f1RedLight,
        surface: isDark ? carbonBlack : Colors.white,
        background: isDark ? carbonBlack : Colors.grey[50]!,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: isDark ? Colors.white : carbonBlack,
        onBackground: isDark ? Colors.white : carbonBlack,
        onError: Colors.white,
      ),

      // SCAFFOLD THEME
      scaffoldBackgroundColor: isDark ? carbonBlack : Colors.grey[50],

      // APP BAR THEME
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkGrey : Colors.white,
        foregroundColor: isDark ? Colors.white : carbonBlack,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: headlineMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        toolbarHeight: 64,
        shape: const Border(
          bottom: BorderSide(
            color: borderGrey,
            width: 1,
          ),
        ),
      ),

      // CARD THEME
      cardTheme: CardTheme(
        color: isDark ? darkGrey : Colors.white,
        elevation: elevation2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(
            color: isDark ? borderGrey : Colors.grey[200]!,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(s),
      ),

      // ELEVATED BUTTON THEME
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: f1Red,
          foregroundColor: Colors.white,
          elevation: elevation2,
          shadowColor: f1Red.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: l,
            vertical: m,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OUTLINED BUTTON THEME
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : carbonBlack,
          side: BorderSide(
            color: isDark ? borderGrey : Colors.grey[300]!,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: l,
            vertical: m,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: labelLarge,
        ),
      ),

      // TEXT BUTTON THEME
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: f1Red,
          padding: const EdgeInsets.symmetric(
            horizontal: l,
            vertical: m,
          ),
          textStyle: labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // INPUT DECORATION THEME
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? mediumGrey : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(
            color: isDark ? borderGrey : Colors.grey[300]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(
            color: isDark ? borderGrey : Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(
            color: f1Red,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(
            color: errorRed,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(
            color: errorRed,
            width: 2,
          ),
        ),
        labelStyle: bodyMedium.copyWith(
          color: textGrey,
        ),
        hintStyle: bodyMedium.copyWith(
          color: textGrey,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: m,
          vertical: m,
        ),
      ),

      // FLOATING ACTION BUTTON THEME
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: f1Red,
        foregroundColor: Colors.white,
        elevation: elevation3,
        shape: CircleBorder(),
      ),

      // BOTTOM NAVIGATION BAR THEME
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? darkGrey : Colors.white,
        selectedItemColor: f1Red,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: elevation2,
        selectedLabelStyle: labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: labelSmall,
      ),

      // NAVIGATION BAR THEME
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? darkGrey : Colors.white,
        indicatorColor: f1Red.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return labelSmall.copyWith(
              color: f1Red,
              fontWeight: FontWeight.w600,
            );
          }
          return labelSmall.copyWith(color: textGrey);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: f1Red);
          }
          return const IconThemeData(color: textGrey);
        }),
      ),

      // DIVIDER THEME
      dividerTheme: DividerThemeData(
        color: isDark ? borderGrey : Colors.grey[200],
        thickness: 1,
        space: 1,
      ),

      // DIALOG THEME
      dialogTheme: DialogTheme(
        backgroundColor: isDark ? darkGrey : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        elevation: elevation4,
        titleTextStyle: headlineSmall,
        contentTextStyle: bodyMedium,
      ),

      // BOTTOM SHEET THEME
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkGrey : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXL),
          ),
        ),
        elevation: elevation4,
      ),

      // SNACK BAR THEME
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? mediumGrey : Colors.grey[800],
        contentTextStyle: bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevation3,
      ),

      // CHIP THEME
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? mediumGrey : Colors.grey[100]!,
        selectedColor: f1Red.withOpacity(0.1),
        side: BorderSide(
          color: isDark ? borderGrey : Colors.grey[300]!,
        ),
        labelStyle: labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),

      // TEXT THEME
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ).apply(
        bodyColor: isDark ? Colors.white : carbonBlack,
        displayColor: isDark ? Colors.white : carbonBlack,
      ),

      // ICON THEME
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : carbonBlack,
        size: 24,
      ),

      // PRIMARY ICON THEME
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // UTILITY METHODS
  static Color getPositionColor(int position) {
    switch (position) {
      case 1:
        return championGold;
      case 2:
        return silverSecond;
      case 3:
        return bronzeThird;
      default:
        return textGrey;
    }
  }

  static Color getTeamColor(String? teamName) {
    if (teamName == null || teamName.isEmpty) return f1Red;
    return teamColors[teamName] ?? f1Red;
  }

  static bool isLightColor(Color color) {
    final relativeLuminance = color.computeLuminance();
    return relativeLuminance > 0.5;
  }

  static Color getContrastColor(Color color) {
    return isLightColor(color) ? carbonBlack : Colors.white;
  }

  // CUSTOM GRADIENTS
  static const LinearGradient f1RedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [f1Red, f1RedDark],
  );

  static const LinearGradient carbonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [carbonBlack, darkGrey],
  );

  static const LinearGradient championGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [championGold, Color(0xFFFFE55C)],
  );

  // SHADOWS
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

// EXTENSION METHODS
extension ColorExtension on Color {
  Color get darken => Color.lerp(this, Colors.black, 0.2) ?? this;
  Color get lighten => Color.lerp(this, Colors.white, 0.2) ?? this;

  Color withAlpha(int alpha) => Color.fromARGB(alpha, red, green, blue);
}

extension ContextExtension on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Media query shortcuts
  MediaQueryData get media => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Responsive helpers
  bool get isMobile => screenWidth < F1Theme.mobileBreakpoint;
  bool get isTablet =>
      screenWidth >= F1Theme.mobileBreakpoint &&
      screenWidth < F1Theme.tabletBreakpoint;
  bool get isDesktop => screenWidth >= F1Theme.tabletBreakpoint;
  bool get isWeb => screenWidth >= F1Theme.mobileBreakpoint;
}
