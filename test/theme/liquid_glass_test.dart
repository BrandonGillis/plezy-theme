import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
