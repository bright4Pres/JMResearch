// ============================================================================
// app_theme.dart - Centralized Theme & Design System
// ============================================================================
// this file defines ALL the visual styling for the app in one place
// benefits: consistency, easy tweaking, dark mode ready, looks professional
//
// design philosophy: warm food-app vibes with modern glassmorphism touches
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// COLOR PALETTE - warm, appetizing colors for a food ordering app
// ============================================================================
class AppColors {
  // primary brand colors
  static const Color primary = Color(0xFFFF6B35); // vibrant orange
  static const Color primaryLight = Color(0xFFFF8F5C); // lighter orange
  static const Color primaryDark = Color(0xFFE85A2A); // darker orange

  // secondary accent
  static const Color secondary = Color(0xFF2D3436); // charcoal
  static const Color secondaryLight = Color(0xFF636E72); // grey

  // background colors
  static const Color background = Color(0xFFFAF7F2); // warm cream
  static const Color surface = Color(0xFFFFFFFF); // white
  static const Color surfaceVariant = Color(0xFFF8F4EE); // off-white

  // status colors
  static const Color success = Color(0xFF00B894); // mint green
  static const Color warning = Color(0xFFFDCB6E); // soft yellow
  static const Color error = Color(0xFFE17055); // soft red
  static const Color info = Color(0xFF74B9FF); // soft blue

  // text colors
  static const Color textPrimary = Color(0xFF2D3436); // dark grey
  static const Color textSecondary = Color(0xFF636E72); // medium grey
  static const Color textHint = Color(0xFFB2BEC3); // light grey
  static const Color textOnPrimary = Color(0xFFFFFFFF); // white

  // special gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFFFFF5F0), Color(0xFFFAF7F2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ============================================================================
// TYPOGRAPHY - clean, readable font styles
// ============================================================================
class AppTypography {
  // headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.4,
  );

  // special styles
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    letterSpacing: 0.5,
  );

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
}

// ============================================================================
// SPACING - consistent spacing throughout the app
// ============================================================================
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ============================================================================
// RADIUS - consistent border radius
// ============================================================================
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 100;

  static BorderRadius get smallRadius => BorderRadius.circular(sm);
  static BorderRadius get mediumRadius => BorderRadius.circular(md);
  static BorderRadius get largeRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
}

// ============================================================================
// SHADOWS - subtle, modern shadows
// ============================================================================
class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}

// ============================================================================
// DECORATIONS - reusable box decorations
// ============================================================================
class AppDecorations {
  // standard card
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.largeRadius,
    boxShadow: AppShadows.small,
  );

  // elevated card (more prominent)
  static BoxDecoration get cardElevated => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.largeRadius,
    boxShadow: AppShadows.medium,
  );

  // glass effect card
  static BoxDecoration get cardGlass => BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.9),
    borderRadius: AppRadius.largeRadius,
    boxShadow: AppShadows.small,
    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
  );

  // gradient card
  static BoxDecoration get cardGradient => BoxDecoration(
    gradient: AppColors.warmGradient,
    borderRadius: AppRadius.largeRadius,
    boxShadow: AppShadows.glow,
  );

  // input field decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textHint, size: 22)
          : null,
      suffix: suffix,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      labelStyle: AppTypography.bodyMedium,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }
}

// ============================================================================
// BUTTON STYLES - consistent button styling
// ============================================================================
class AppButtons {
  // primary filled button
  static ButtonStyle get primary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
    textStyle: AppTypography.button,
  );

  // secondary outlined button
  static ButtonStyle get secondary => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
    textStyle: AppTypography.button,
  );

  // text button
  static ButtonStyle get text => TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    textStyle: AppTypography.button,
  );

  // icon button style
  static ButtonStyle get icon => IconButton.styleFrom(
    backgroundColor: AppColors.surfaceVariant,
    foregroundColor: AppColors.textPrimary,
    padding: const EdgeInsets.all(12),
  );
}

// ============================================================================
// THEME DATA - complete MaterialApp theme
// ============================================================================
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      // color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // app bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h4,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // card theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      ),

      // elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary),

      // outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtons.secondary),

      // text button theme
      textButtonTheme: TextButtonThemeData(style: AppButtons.text),

      // input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: BorderSide.none,
        ),
      ),

      // tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.button.copyWith(fontSize: 14),
        unselectedLabelStyle: AppTypography.bodyMedium,
      ),

      // bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        titleTextStyle: AppTypography.h3,
      ),

      // snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
        behavior: SnackBarBehavior.floating,
      ),

      // floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // divider theme
      dividerTheme: DividerThemeData(
        color: AppColors.textHint.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }
}

// ============================================================================
// CUSTOM WIDGETS - reusable UI components
// ============================================================================

/// A modern card with optional gradient header
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: elevated ? AppDecorations.cardElevated : AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.largeRadius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Status badge (pending, ready, finished, etc.)
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const StatusBadge({super.key, required this.status, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, icon) = _getStatusColors();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 12,
        vertical: isLarge ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isLarge ? 18 : 14, color: fgColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: isLarge ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: fgColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _getStatusColors() {
    switch (status.toLowerCase()) {
      case 'pending':
      case '':
        return (AppColors.warning, const Color(0xFFD68910), Icons.schedule);
      case 'ready for pick up':
      case 'ready':
        return (AppColors.info, const Color(0xFF2980B9), Icons.local_shipping);
      case 'finished':
      case 'completed':
        return (AppColors.success, const Color(0xFF1E8449), Icons.check_circle);
      case 'open':
        return (AppColors.success, const Color(0xFF1E8449), Icons.storefront);
      case 'closed':
        return (AppColors.error, const Color(0xFFC0392B), Icons.store);
      default:
        return (AppColors.textHint, AppColors.textSecondary, Icons.info);
    }
  }
}

/// Animated loading indicator
class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoader({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
      ),
    );
  }
}

/// Empty state placeholder
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Gradient app bar background
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.warmGradient),
      child: AppBar(
        title: Text(
          title,
          style: AppTypography.h4.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: showBackButton,
        actions: actions,
        bottom: bottom,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
