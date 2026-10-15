import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/device_performance.dart';
import 'mono_tokens.dart';

/// Whether the active theme is the Liquid Glass palette.
bool isLiquidGlass(BuildContext context) => Theme.of(context).extension<MonoTokens>()?.glass ?? false;

/// Saturation boost applied to the blurred backdrop, so colours bleeding
/// through a glass surface stay vivid instead of washing out to grey.
const double _backdropSaturation = 1.5;

ColorFilter _saturation(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final i = 1 - s;
  return ColorFilter.matrix([
    r * i + s, g * i, b * i, 0, 0, //
    r * i, g * i + s, b * i, 0, 0, //
    r * i, g * i, b * i + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
}

/// A Liquid Glass surface: the backdrop blurred and saturated, a translucent
/// tint with a soft top-down sheen, and a specular rim catching light on the
/// leading-top edge.
///
/// Outside the Liquid Glass theme it paints [fallbackColor] (default: the
/// mono surface) on the same shape, so callers can use it unconditionally.
/// Reduced-performance devices skip the blur and get a denser tint instead,
/// since a live backdrop blur re-samples everything behind it every frame.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(MonoTokens.radiusFull)),
    this.fallbackColor,
    this.tint,
    this.shadow = true,
    this.padding,
    required this.child,
  });

  final BorderRadiusGeometry borderRadius;

  /// Fill outside the Liquid Glass theme; null uses the mono surface colour.
  final Color? fallbackColor;

  /// Overrides the theme's glass tint (e.g. a thicker tint for dialogs).
  final Color? tint;

  /// Whether to cast the soft drop shadow that lifts floating chrome.
  final bool shadow;

  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Tolerates a theme without MonoTokens (startup frames, bare tests).
    final t = Theme.of(context).extension<MonoTokens>();
    final content = padding == null ? child : Padding(padding: padding!, child: child);
    if (t == null || !t.glass) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: fallbackColor ?? t?.surface ?? Theme.of(context).colorScheme.surface,
          borderRadius: borderRadius,
        ),
        child: content,
      );
    }

    final reduced = DevicePerformance.isReduced;
    final fill = tint ?? t.glassFill;
    final effectiveFill = reduced ? Color.alphaBlend(fill, t.bg.withValues(alpha: 0.9)) : fill;

    Widget glass = CustomPaint(
      painter: _GlassFillPainter(
        borderRadius: borderRadius,
        fill: effectiveFill,
        textDirection: Directionality.of(context),
      ),
      foregroundPainter: _GlassRimPainter(
        borderRadius: borderRadius,
        rim: t.glassRim,
        textDirection: Directionality.of(context),
      ),
      child: content,
    );
    if (!reduced && t.glassBlur > 0) {
      glass = BackdropFilter(
        filter: ui.ImageFilter.compose(
          outer: _saturation(_backdropSaturation),
          inner: ui.ImageFilter.blur(sigmaX: t.glassBlur, sigmaY: t.glassBlur, tileMode: TileMode.mirror),
        ),
        child: glass,
      );
    }
    glass = ClipRRect(borderRadius: borderRadius, child: glass);

    if (!shadow) return glass;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 12)),
          BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: glass,
    );
  }
}

class _GlassFillPainter extends CustomPainter {
  _GlassFillPainter({required this.borderRadius, required this.fill, required this.textDirection});

  final BorderRadiusGeometry borderRadius;
  final Color fill;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.resolve(textDirection).toRRect(rect);
    // Light enters from above: the top of the slab reads slightly brighter.
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.alphaBlend(const Color(0x14FFFFFF), fill), fill],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlassFillPainter old) =>
      old.fill != fill || old.borderRadius != borderRadius || old.textDirection != textDirection;
}

class _GlassRimPainter extends CustomPainter {
  _GlassRimPainter({required this.borderRadius, required this.rim, required this.textDirection});

  final BorderRadiusGeometry borderRadius;
  final Color rim;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = borderRadius.resolve(textDirection).toRRect(rect).deflate(0.5);
    // Specular highlight: bright on the top-leading edge, fading through the
    // sides, with a faint bounce on the bottom-trailing edge.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          rim,
          rim.withValues(alpha: rim.a * 0.15),
          rim.withValues(alpha: rim.a * 0.5),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) =>
      old.rim != rim || old.borderRadius != borderRadius || old.textDirection != textDirection;
}

/// Blurs and dims the page behind a modal (dialog) in the Liquid Glass theme,
/// the way tvOS and iOS defocus content under an alert. A no-op elsewhere.
class LiquidGlassModalBackdrop extends StatelessWidget {
  const LiquidGlassModalBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isLiquidGlass(context) || DevicePerformance.isReduced) return child;
    // passthrough keeps the dialog's original (tight, full-route) constraints.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12, tileMode: TileMode.mirror),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
