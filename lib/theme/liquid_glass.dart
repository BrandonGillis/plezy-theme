import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kTouchSlop;
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

/// Overshooting ease used by Liquid Glass motion: elements settle with a
/// slight springy bounce instead of stopping dead.
const Curve liquidSpringCurve = Cubic(0.34, 1.36, 0.64, 1);

/// Touch feedback for Liquid Glass: the child squishes slightly while pressed
/// and springs back on release. A drag past the touch slop releases it, so
/// scrolling a row never leaves a card stuck pressed. A no-op elsewhere.
///
/// Uses a raw [Listener], so it never competes with the child's own gesture
/// recognizers.
class LiquidPressScale extends StatefulWidget {
  const LiquidPressScale({super.key, this.pressedScale = 0.96, this.enabled = true, required this.child});

  final double pressedScale;
  final bool enabled;
  final Widget child;

  @override
  State<LiquidPressScale> createState() => _LiquidPressScaleState();
}

class _LiquidPressScaleState extends State<LiquidPressScale> {
  bool _pressed = false;
  Offset? _downPosition;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !isLiquidGlass(context) || DevicePerformance.isReduced) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _downPosition = event.position;
        _setPressed(true);
      },
      onPointerMove: (event) {
        final down = _downPosition;
        if (_pressed && down != null && (event.position - down).distance > kTouchSlop) _setPressed(false);
      },
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _pressed ? 110 : 420),
        curve: _pressed ? Curves.easeOut : liquidSpringCurve,
        child: widget.child,
      ),
    );
  }
}

/// Liquid Glass focus treatment for cards (tvOS 26): instead of a solid
/// border, the focused card catches light — a specular rim brightest on the
/// top-leading edge and a soft sheen across its top. Fades with [focused].
class LiquidFocusRim extends StatelessWidget {
  const LiquidFocusRim({
    super.key,
    required this.focused,
    required this.borderRadius,
    required this.duration,
    required this.child,
  });

  final bool focused;
  final BorderRadiusGeometry borderRadius;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: focused ? 1 : 0),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => CustomPaint(
        foregroundPainter: t == 0
            ? null
            : _FocusRimPainter(borderRadius: borderRadius, t: t, textDirection: Directionality.of(context)),
        child: child,
      ),
    );
  }
}

class _FocusRimPainter extends CustomPainter {
  _FocusRimPainter({required this.borderRadius, required this.t, required this.textDirection});

  final BorderRadiusGeometry borderRadius;
  final double t;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = borderRadius.resolve(textDirection).toRRect(rect);
    canvas.save();
    canvas.clipRRect(rrect);
    // Sheen: light pooling across the top of the slab.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.22 * t),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.45],
        ).createShader(rect),
    );
    canvas.restore();
    // Specular rim.
    canvas.drawRRect(
      rrect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95 * t),
            Colors.white.withValues(alpha: 0.35 * t),
            Colors.white.withValues(alpha: 0.6 * t),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_FocusRimPainter old) =>
      old.t != t || old.borderRadius != borderRadius || old.textDirection != textDirection;
}

/// Liquid Glass touch highlight: a soft glow that blooms from the touch point
/// and fades, in place of Material's ink ripple.
class LiquidGlowSplash extends InteractiveInkFeature {
  LiquidGlowSplash({
    required MaterialInkController controller,
    required super.referenceBox,
    required Offset position,
    required super.color,
    required this._textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    this._customBorder,
    double? radius,
    super.onRemoved,
  }) : _position = position,
       _borderRadius = borderRadius ?? BorderRadius.zero,
       _clipCallback = containedInkWell ? (rectCallback ?? () => Offset.zero & referenceBox.size) : rectCallback,
       _targetRadius = radius ?? _maxRadius(referenceBox.size, position),
       super(controller: controller) {
    _bloom = AnimationController(duration: const Duration(milliseconds: 380), vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _fade = AnimationController(duration: const Duration(milliseconds: 320), vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) dispose();
      });
    controller.addInkFeature(this);
  }

  static const InteractiveInkFeatureFactory splashFactory = _LiquidGlowSplashFactory();

  final Offset _position;
  final TextDirection _textDirection;
  final BorderRadius _borderRadius;
  final ShapeBorder? _customBorder;
  final RectCallback? _clipCallback;
  final double _targetRadius;
  late final AnimationController _bloom;
  late final AnimationController _fade;

  static double _maxRadius(Size size, Offset position) {
    final corners = [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)];
    return corners.map((c) => (c - position).distance).reduce((a, b) => a > b ? a : b);
  }

  @override
  void confirm() => _fade.forward();

  @override
  void cancel() => _fade.forward();

  @override
  void dispose() {
    _bloom.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final bloom = Curves.easeOutCubic.transform(_bloom.value);
    final radius = _targetRadius * (0.35 + 0.65 * bloom);
    final opacity = (1 - _fade.value) * color.a;
    if (opacity <= 0 || radius <= 0) return;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: _position, radius: radius));
    paintInkCircle(
      canvas: canvas,
      transform: transform,
      paint: paint,
      center: _position,
      textDirection: _textDirection,
      radius: radius,
      customBorder: _customBorder,
      borderRadius: _borderRadius,
      clipCallback: _clipCallback,
    );
  }
}

class _LiquidGlowSplashFactory extends InteractiveInkFeatureFactory {
  const _LiquidGlowSplashFactory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) => LiquidGlowSplash(
    controller: controller,
    referenceBox: referenceBox,
    position: position,
    color: color,
    textDirection: textDirection,
    containedInkWell: containedInkWell,
    rectCallback: rectCallback,
    borderRadius: borderRadius,
    customBorder: customBorder,
    radius: radius,
    onRemoved: onRemoved,
  );
}
