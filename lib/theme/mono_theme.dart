import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'gapped_track_shape.dart';
import 'liquid_glass.dart';
import 'mono_tokens.dart';

final Map<({bool dark, bool oled, bool glass, TargetPlatform platform}), ThemeData> _monoThemeCache = {};

/// The app theme for a palette. [glass] selects the Liquid Glass palette, a
/// dark Apple TV–style variant whose floating chrome renders as blurred glass
/// (see `LiquidGlass`); it implies [dark] and takes precedence over [oled].
ThemeData monoTheme({required bool dark, bool oled = false, bool glass = false}) {
  // ThemeData derives several defaults from defaultTargetPlatform.
  final key = (dark: dark || oled || glass, oled: oled && !glass, glass: glass, platform: defaultTargetPlatform);
  final cached = _monoThemeCache[key];
  if (cached != null) return cached;

  final theme = _buildMonoTheme(dark: key.dark, oled: key.oled, glass: key.glass, platform: key.platform);
  _monoThemeCache[key] = theme;
  return theme;
}

/// Liquid Glass tint over the blurred backdrop: dark enough that white text
/// stays legible over bright artwork, light enough to let colour through.
const _glassFill = Color(0x8C1E1F24);

/// Denser glass for surfaces holding long-form content (dialogs, sheets,
/// menus), which need more separation from what's behind them.
const _glassThick = Color(0xE61C1D22);
const _glassRim = Color(0x80FFFFFF);
const _glassBorder = BorderSide(color: Color(0x29FFFFFF));

ThemeData _buildMonoTheme({
  required bool dark,
  required bool oled,
  required bool glass,
  required TargetPlatform platform,
}) {
  // neutral greys tuned for crisp contrast
  final ({Color bg, Color surface, Color outline, Color text, Color textMuted}) c;
  if (glass) {
    // Apple TV: near-black canvas with a cool cast, graphite cells, and the
    // system label / secondary-label greys.
    c = (
      bg: const Color(0xFF08090C),
      surface: const Color(0xFF1C1D22),
      outline: const Color(0x24FFFFFF),
      text: const Color(0xFFF5F5F7),
      textMuted: const Color(0x99EBEBF5),
    );
  } else if (oled) {
    c = (
      bg: const Color(0xFF000000), // Pure black for OLED
      surface: const Color(0xFF0A0A0A), // Very dark gray
      outline: const Color(0x1FFFFFFF),
      text: const Color(0xFFEDEDED),
      textMuted: const Color(0x99EDEDED),
    );
  } else if (dark) {
    c = (
      bg: const Color(0xFF0E0F12),
      surface: const Color(0xFF15171C),
      outline: const Color(0x1FFFFFFF),
      text: const Color(0xFFEDEDED),
      textMuted: const Color(0x99EDEDED),
    );
  } else {
    c = (
      bg: const Color(0xFFF7F7F8),
      surface: const Color(0xFFFFFFFF),
      outline: const Color(0x19000000),
      text: const Color(0xFF111111),
      textMuted: const Color(0x99111111),
    );
  }

  final isDark = dark || oled;
  final clickableCursor = WidgetStateProperty.resolveWith<MouseCursor>(
    (states) => states.contains(WidgetState.disabled) ? MouseCursor.defer : SystemMouseCursors.click,
  );

  // Disabled buttons use the Material disabled opacities over the text colour;
  // a flat colour for every state made them look pressable.
  final buttonStyle = ButtonStyle(
    mouseCursor: clickableCursor,
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? c.text.withValues(alpha: 0.12) : c.text,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.disabled) ? c.text.withValues(alpha: 0.38) : (isDark ? c.bg : Colors.white),
    ),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
  );

  final base = ThemeData(
    platform: platform,
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    // Linux resolves UI text through fontconfig, which on a minimal desktop
    // may have no CJK font at all; the bundled subtitle fonts (pubspec
    // `fonts:`) cover it. Other platforms keep their native CJK fonts.
    fontFamilyFallback: platform == TargetPlatform.linux ? const ['Go Noto Current', 'Go Noto Current Hangul'] : null,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: c.text,
      onPrimary: isDark ? c.bg : Colors.white,
      secondary: c.text,
      onSecondary: c.bg,
      surface: c.surface,
      onSurface: c.text,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      tertiary: c.text,
      onTertiary: c.bg,
      primaryContainer: c.surface,
      onPrimaryContainer: c.text,
      secondaryContainer: c.surface,
      onSecondaryContainer: c.text,
      surfaceContainerHighest: c.surface,
      surfaceContainerLow: c.bg,
      surfaceDim: c.bg,
      surfaceBright: c.surface,
      outline: c.outline,
      shadow: Colors.transparent,
      scrim: Colors.black,
      inverseSurface: c.text,
      onInverseSurface: c.bg,
      inversePrimary: c.bg,
    ),
    // remove "Material feel"
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    // Explicit mono-derived tile highlights: ListTile's native focus/hover
    // fill is the dpad focus visual inside M3E grouped-list cards.
    focusColor: c.text.withValues(alpha: 0.12),
    hoverColor: c.text.withValues(alpha: 0.05),
    dividerColor: c.outline,
    scaffoldBackgroundColor: c.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.text,
      titleTextStyle: TextStyle(color: c.text, fontSize: 18, fontWeight: .w700, letterSpacing: -0.2),
    ),
    textTheme: Typography.englishLike2021
        .apply(bodyColor: c.text, displayColor: c.text)
        .copyWith(
          displayLarge: const TextStyle(fontWeight: .w700, letterSpacing: -0.5),
          titleMedium: const TextStyle(fontWeight: .w600),
          bodyMedium: TextStyle(color: c.text),
          bodySmall: TextStyle(color: c.textMuted),
        ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: .zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    inputDecorationTheme: _inputDecorationTheme(c.text, c.textMuted),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    iconButtonTheme: IconButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    sliderTheme: SliderThemeData(
      // The mono scheme maps surfaceContainerHighest (the M3 default inactive
      // track) to the same color as surface cards, which makes the inactive
      // track invisible inside grouped-list items.
      inactiveTrackColor: c.text.withValues(alpha: 0.12),
      trackHeight: 16,
      trackGap: 6,
      thumbSize: const WidgetStatePropertyAll(Size(4, 20)),
      thumbShape: const HandleThumbShape(),
      trackShape: const GappedTrackShape(),
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
      // ignore: deprecated_member_use — opting into the 2024 slider appearance until the default flips
      year2023: false,
    ),
    dividerTheme: DividerThemeData(space: 0, thickness: 1, color: c.outline),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconColor: c.text,
      textColor: c.text,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: c.textMuted, fontSize: 11)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(opacity: active ? 1 : 0.6, size: 22, color: c.text);
      }),
    ),
    // Floating snackbars auto-offset above the Scaffold's bottom NavigationBar,
    // so they don't cover it on mobile. Background color tracks the theme to
    // avoid jarring brightness on HDR playback / dark mode.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.surface,
      contentTextStyle: TextStyle(color: c.text),
      actionTextColor: c.text,
      elevation: 6,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      insetPadding: const EdgeInsets.all(16),
    ),
  );

  if (glass) return _applyLiquidGlass(base, c, buttonStyle);

  return base.copyWith(
    extensions: [
      MonoTokens(
        radiusSm: 8,
        radiusMd: 12,
        radiusLg: 20,
        radiusXs: 5,
        groupGap: 2,
        space: 12,
        fast: const Duration(milliseconds: 120),
        normal: const Duration(milliseconds: 200),
        slow: const Duration(milliseconds: 300),
        expressive: const Duration(milliseconds: 350),
        bg: c.bg,
        surface: c.surface,
        outline: c.outline,
        text: c.text,
        textMuted: c.textMuted,
      ),
    ],
  );
}

/// Liquid Glass overrides on top of the dark mono base: rounder, softer
/// geometry, bolder Apple-style titles, capsule controls, and translucent
/// overlays with a hairline specular border.
ThemeData _applyLiquidGlass(
  ThemeData base,
  ({Color bg, Color surface, Color outline, Color text, Color textMuted}) c,
  ButtonStyle buttonStyle,
) {
  // Styles derive from the text theme so they keep its font fallbacks
  // (the bundled CJK fonts on Linux).
  final glassButtonStyle = buttonStyle.copyWith(
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 15)),
    textStyle: WidgetStatePropertyAll(
      base.textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: .w600, letterSpacing: -0.1),
    ),
  );
  // Secondary buttons are frosted capsules rather than bare text.
  final tonalButtonStyle = glassButtonStyle.copyWith(
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => c.text.withValues(alpha: states.contains(WidgetState.disabled) ? 0.06 : 0.14),
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? c.text.withValues(alpha: 0.38) : c.text,
    ),
    side: const WidgetStatePropertyAll(_glassBorder),
  );
  const overlayShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30)), side: _glassBorder);
  final textTheme = base.textTheme.copyWith(
    displayLarge: base.textTheme.displayLarge?.copyWith(fontWeight: .w800, letterSpacing: -1.2),
    displayMedium: base.textTheme.displayMedium?.copyWith(fontWeight: .w800, letterSpacing: -1),
    displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: .w700, letterSpacing: -0.8),
    headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: .w700, letterSpacing: -0.6),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: .w700, letterSpacing: -0.5),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: .w700, letterSpacing: -0.4),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: .w700, letterSpacing: -0.3),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: .w600, letterSpacing: -0.2),
  );

  return base.copyWith(
    textTheme: textTheme,
    focusColor: c.text.withValues(alpha: 0.16),
    hoverColor: c.text.withValues(alpha: 0.07),
    // A soft glow blooms from the touch point instead of the mono theme's
    // no-splash.
    splashFactory: LiquidGlowSplash.splashFactory,
    splashColor: c.text.withValues(alpha: 0.22),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(fontSize: 20, letterSpacing: -0.4),
    ),
    cardTheme: base.cardTheme.copyWith(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22)), side: _glassBorder),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: glassButtonStyle),
    filledButtonTheme: FilledButtonThemeData(style: glassButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: tonalButtonStyle),
    inputDecorationTheme: _inputDecorationTheme(c.text, c.textMuted, radius: 16),
    // The bar and rail sit inside a LiquidGlass capsule that paints the
    // surface, so they must stay transparent themselves.
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      height: 64,
      indicatorColor: c.text.withValues(alpha: 0.16),
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected) ? c.text : c.textMuted,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected) ? .w600 : .w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: c.text.withValues(alpha: 0.16),
      indicatorShape: const StadiumBorder(),
      selectedIconTheme: IconThemeData(color: c.text),
      unselectedIconTheme: IconThemeData(color: c.textMuted),
      selectedLabelTextStyle: TextStyle(color: c.text, fontSize: 11, fontWeight: .w600),
      unselectedLabelTextStyle: TextStyle(color: c.textMuted, fontSize: 11),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _glassThick,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: overlayShape,
      barrierColor: const Color(0x73000000),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: c.text, fontSize: 20, letterSpacing: -0.4),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _glassThick,
      modalBackgroundColor: _glassThick,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        side: _glassBorder,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _glassThick,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black54,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)), side: _glassBorder),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(_glassThick),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)), side: _glassBorder),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(
        color: _glassThick,
        shape: const StadiumBorder(side: _glassBorder),
      ),
      textStyle: TextStyle(color: c.text, fontSize: 12, fontWeight: .w500),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: c.text.withValues(alpha: 0.1),
      selectedColor: c.text,
      shape: const StadiumBorder(side: _glassBorder),
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      backgroundColor: const Color(0xF22A2B31),
      shape: const StadiumBorder(side: _glassBorder),
      elevation: 0,
    ),
    extensions: [
      MonoTokens(
        radiusSm: 12,
        radiusMd: 18,
        radiusLg: 28,
        radiusXs: 8,
        groupGap: 2,
        space: 14,
        // Unhurried, fluid motion: glass "settles" rather than snaps.
        fast: const Duration(milliseconds: 160),
        normal: const Duration(milliseconds: 260),
        slow: const Duration(milliseconds: 380),
        expressive: const Duration(milliseconds: 450),
        bg: c.bg,
        surface: c.surface,
        outline: c.outline,
        text: c.text,
        textMuted: c.textMuted,
        glass: true,
        glassFill: _glassFill,
        glassRim: _glassRim,
        glassBlur: 28,
      ),
    ],
  );
}

/// Brighter fill on focus so input focus is visible inside TV overscan.
InputDecorationTheme _inputDecorationTheme(Color text, Color textMuted, {double radius = 12}) {
  final unfocusedFill = text.withValues(alpha: 0.08);
  final focusedFill = text.withValues(alpha: 0.18);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    borderSide: BorderSide.none,
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.focused) ? focusedFill : unfocusedFill,
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    hintStyle: TextStyle(color: textMuted),
  );
}
