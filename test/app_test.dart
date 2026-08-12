import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  testWidgets('renders home over the theme background, in themed text', (
    tester,
  ) async {
    const theme = Theme();
    await tester.pumpWidget(const TomeApp(home: Text('hello')));

    expect(find.text('hello'), findsOneWidget);

    final style = DefaultTextStyle.of(
      tester.element(find.text('hello')),
    ).style;
    expect(style.color, theme.palette.text);
    expect(style.fontSize, theme.typography.body.fontSize);

    final background = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
    expect(background.map((b) => b.color), contains(theme.palette.background));
  });

  testWidgets('ThemeProvider serves routes, and admits when there is none', (
    tester,
  ) async {
    late Theme seen;
    await tester.pumpWidget(
      TomeApp(
        theme: const Theme(palette: Palette(brightness: Brightness.light)),
        home: Builder(
          builder: (context) {
            seen = ThemeProvider.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen.palette.brightness, Brightness.light);

    // No provider above it at all: maybeOf says so rather than guessing.
    late Theme? absent;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            absent = ThemeProvider.maybeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(absent, isNull);
  });

  testWidgets('named routes navigate through TomePageRoute', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        routes: {
          '/': (_) => Builder(
            builder: (context) => GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/next'),
              child: const Text('go'),
            ),
          ),
          '/next': (_) => const Text('arrived'),
        },
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('arrived'), findsOneWidget);
    expect(find.text('go'), findsNothing);
  });

  testWidgets('icons default to the themed size and colour', (tester) async {
    const theme = Theme();
    await tester.pumpWidget(TomeApp(home: Icon(theme.icons.settings)));

    final icon = IconTheme.of(tester.element(find.byType(Icon)));
    expect(icon.color, theme.palette.text);
    expect(icon.size, Sizes.icon);
  });
}
