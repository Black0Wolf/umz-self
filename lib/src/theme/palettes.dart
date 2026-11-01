import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colours for one palette in one brightness.
class PaletteVariant {
  const PaletteVariant(
      {required this.bg, required this.surface, required this.accent});

  /// Page background.
  final Color bg;

  /// Cards, dialogs.
  final Color surface;
  final Color accent;
}

class AppPalette {
  const AppPalette(this.id, this.nameEn, this.nameFa, this.dark, this.light);

  final String id;
  final String nameEn;
  final String nameFa;
  final PaletteVariant dark;
  final PaletteVariant light;

  PaletteVariant variant(Brightness b) =>
      b == Brightness.dark ? dark : light;

  String name(String lang) => lang == 'fa' ? nameFa : nameEn;
}

const List<AppPalette> palettes = [
  AppPalette(
    'neon',
    'Neon',
    'نئون',
    PaletteVariant(
        bg: Color(0xFF0A0A0A),
        surface: Color(0xFF141414),
        accent: Color(0xFF39FF14)),
    PaletteVariant(
        bg: Color(0xFFF4F7F3),
        surface: Color(0xFFFFFFFF),
        accent: Color(0xFF00C853)),
  ),
  AppPalette(
    'ocean',
    'Ocean',
    'اقیانوس',
    PaletteVariant(
        bg: Color(0xFF08121C),
        surface: Color(0xFF0F1D2B),
        accent: Color(0xFF38BDF8)),
    PaletteVariant(
        bg: Color(0xFFF1F7FB),
        surface: Color(0xFFFFFFFF),
        accent: Color(0xFF0369A1)),
  ),
  AppPalette(
    'violet',
    'Violet',
    'بنفش',
    PaletteVariant(
        bg: Color(0xFF0E0A16),
        surface: Color(0xFF17111F),
        accent: Color(0xFFA78BFA)),
    PaletteVariant(
        bg: Color(0xFFF7F5FC),
        surface: Color(0xFFFFFFFF),
        accent: Color(0xFF7C3AED)),
  ),
  AppPalette(
    'sunset',
    'Sunset',
    'غروب',
    PaletteVariant(
        bg: Color(0xFF140B08),
        surface: Color(0xFF1F130F),
        accent: Color(0xFFFB923C)),
    PaletteVariant(
        bg: Color(0xFFFCF6F1),
        surface: Color(0xFFFFFFFF),
        accent: Color(0xFFEA580C)),
  ),
  AppPalette(
    'rose',
    'Rose',
    'رز',
    PaletteVariant(
        bg: Color(0xFF150A0F),
        surface: Color(0xFF20111A),
        accent: Color(0xFFFB7185)),
    PaletteVariant(
        bg: Color(0xFFFCF4F6),
        surface: Color(0xFFFFFFFF),
        accent: Color(0xFFE11D48)),
  ),
  AppPalette(
    'mono',
    'Mono',
    'تک‌رنگ',
    PaletteVariant(
        bg: Color(0xFF000000),
        surface: Color(0xFF111111),
        accent: Color(0xFFFFFFFF)),
    PaletteVariant(
        bg: Color(0xFFF6F6F6),
        surface: Color(0xFFFFFFFF),
        accent: Color(0xFF111111)),
  ),
];

AppPalette paletteById(String id) =>
    palettes.firstWhere((p) => p.id == id, orElse: () => palettes.first);

/// WCAG contrast ratio between two colours (1..21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const Color _ink = Color(0xFF0A0A0A);
const Color _paper = Color(0xFFFFFFFF);

/// Black or white, whichever reads better on [c].
Color onColor(Color c) =>
    contrastRatio(c, _ink) >= contrastRatio(c, _paper) ? _ink : _paper;

/// Body text colour for a brightness.
Color textColor(Brightness b) =>
    b == Brightness.dark ? const Color(0xFFF2F2F2) : const Color(0xFF111111);

ThemeData buildTheme(AppPalette palette, Brightness brightness) {
  final v = palette.variant(brightness);
  final dark = brightness == Brightness.dark;
  final text = textColor(brightness);
  final line = text.withValues(alpha: 0.10);
  final error = dark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: v.accent,
    onPrimary: onColor(v.accent),
    secondary: v.accent,
    onSecondary: onColor(v.accent),
    error: error,
    onError: onColor(error),
    surface: v.surface,
    onSurface: text,
    outline: text.withValues(alpha: 0.45),
    outlineVariant: line,
    surfaceContainerHighest: Color.alphaBlend(
        text.withValues(alpha: dark ? 0.07 : 0.05), v.surface),
    primaryContainer:
        Color.alphaBlend(v.accent.withValues(alpha: 0.16), v.surface),
    onPrimaryContainer: text,
  );

  final base = ThemeData(useMaterial3: true, brightness: brightness);
  const radius = BorderRadius.all(Radius.circular(14));

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: v.bg,
    canvasColor: v.bg,
    textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
    splashColor: v.accent.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: const OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: v.accent, width: 1.5)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : text),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? v.accent
              : text.withValues(alpha: 0.18)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: v.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: text),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: line),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: v.accent,
      linearTrackColor: line,
    ),
    iconTheme: IconThemeData(color: text.withValues(alpha: 0.85)),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: _FadeSlideTransitions(),
      TargetPlatform.iOS: _FadeSlideTransitions(),
      TargetPlatform.windows: _FadeSlideTransitions(),
      TargetPlatform.macOS: _FadeSlideTransitions(),
      TargetPlatform.linux: _FadeSlideTransitions(),
      TargetPlatform.fuchsia: _FadeSlideTransitions(),
    }),
  );
}

/// Quiet page transition: fade plus a small upward slide.
class _FadeSlideTransitions extends PageTransitionsBuilder {
  const _FadeSlideTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
