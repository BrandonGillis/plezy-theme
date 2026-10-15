import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_theme.dart';
import 'package:plezy/theme/liquid_glass.dart';
import 'package:plezy/theme/mono_theme.dart';

Widget _host(ThemeData theme, Widget child) => MaterialApp(
  theme: theme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('LiquidGlass blurs its backdrop in the Liquid Glass theme', (tester) async {
    await tester.pumpWidget(
      _host(monoTheme(dark: true, glass: true), const LiquidGlass(child: SizedBox(width: 200, height: 60))),
    );

    expect(isLiquidGlass(tester.element(find.byType(LiquidGlass))), isTrue);
    expect(find.descendant(of: find.byType(LiquidGlass), matching: find.byType(BackdropFilter)), findsOneWidget);
  });

  testWidgets('LiquidGlass falls back to a flat surface in other themes', (tester) async {
    final theme = monoTheme(dark: true);
    await tester.pumpWidget(_host(theme, const LiquidGlass(child: SizedBox(width: 200, height: 60))));

    expect(isLiquidGlass(tester.element(find.byType(LiquidGlass))), isFalse);
    expect(find.descendant(of: find.byType(LiquidGlass), matching: find.byType(BackdropFilter)), findsNothing);
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(LiquidGlass), matching: find.byType(DecoratedBox)).first,
    );
    expect((box.decoration as BoxDecoration).color, theme.colorScheme.surface);
  });

  testWidgets('LiquidGlassModalBackdrop only blurs in the Liquid Glass theme', (tester) async {
    await tester.pumpWidget(_host(monoTheme(dark: true), const LiquidGlassModalBackdrop(child: Text('dialog'))));
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.pumpWidget(
      _host(monoTheme(dark: true, glass: true), const LiquidGlassModalBackdrop(child: Text('dialog'))),
    );
    // MaterialApp animates between themes.
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('dialog'), findsOneWidget);
  });

  testWidgets('LiquidPressScale squishes while pressed and releases on drag', (tester) async {
    double scale() => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    await tester.pumpWidget(
      _host(monoTheme(dark: true, glass: true), const LiquidPressScale(child: SizedBox(width: 100, height: 100))),
    );
    final gesture = await tester.startGesture(tester.getCenter(find.byType(LiquidPressScale)));
    await tester.pump();
    expect(scale(), lessThan(1));

    // Scrolling past the touch slop must not leave the card stuck pressed.
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(scale(), 1);
    await gesture.up();
  });

  testWidgets('LiquidPressScale is inert outside the Liquid Glass theme', (tester) async {
    await tester.pumpWidget(
      _host(monoTheme(dark: true), const LiquidPressScale(child: SizedBox(width: 100, height: 100))),
    );
    expect(find.byType(AnimatedScale), findsNothing);
  });

  testWidgets('Liquid Glass lifts focused cards further with a springy curve', (tester) async {
    late BuildContext glassContext;
    await tester.pumpWidget(
      _host(
        monoTheme(dark: true, glass: true),
        Builder(
          builder: (context) {
            glassContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(FocusTheme.scaleFor(glassContext, FocusTheme.focusScale), greaterThan(FocusTheme.focusScale));
    // Player controls already scale a lot; they keep their own value.
    expect(FocusTheme.scaleFor(glassContext, FocusTheme.playerControlFocusScale), FocusTheme.playerControlFocusScale);
    expect(FocusTheme.focusCurve(glassContext), liquidSpringCurve);

    late BuildContext monoContext;
    await tester.pumpWidget(
      _host(
        monoTheme(dark: true),
        Builder(
          builder: (context) {
            monoContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(FocusTheme.scaleFor(monoContext, FocusTheme.focusScale), FocusTheme.focusScale);
    expect(FocusTheme.focusCurve(monoContext), Curves.easeOutCubic);
  });

  test('the glass theme uses the glow splash; other palettes keep no splash', () {
    expect(monoTheme(dark: true, glass: true).splashFactory, LiquidGlowSplash.splashFactory);
    expect(monoTheme(dark: true).splashFactory, NoSplash.splashFactory);
  });
}
