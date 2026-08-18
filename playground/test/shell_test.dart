import 'package:flutter/material.dart' hide Placeholder;
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart' as tome;
import 'package:tomeui_playground/app.dart';
import 'package:tomeui_playground/src/widgets/story_canvas.dart';
import 'package:tomeui_playground/src/widgets/story_list.dart';

Finder inList(String label) =>
    find.descendant(of: find.byType(StoryList), matching: find.text(label));

Future<void> tapInList(WidgetTester tester, String label) async {
  await tester.tap(inList(label));
  await tester.pump();
}

void main() {
  // The catalogue is taller than the default 600px test window, and rows
  // scrolled off the bottom never get built — give the shell room to show
  // every story instead of scrolling to reach them.
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views
        .first;
    view.physicalSize = const Size(1600, 1600);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('lists the catalogue: Tokens on top, flat single-story rows', (
    tester,
  ) async {
    await tester.pumpWidget(const PlaygroundApp());

    // Groups start closed — the list is widgets first, stories on request
    // — but the first story is still what the canvas opens on.
    expect(inList('Tokens'), findsOneWidget);
    expect(inList('Colors'), findsNothing);
    expect(find.text('derived roles'), findsOneWidget, reason: 'Colors');

    // Opening Tokens spells its stories out, and closing folds them away.
    await tapInList(tester, 'Tokens');
    expect(inList('Colors'), findsOneWidget);
    await tapInList(tester, 'Tokens');
    expect(inList('Colors'), findsNothing);

    // The widgets have one story each: flat rows wearing the widget's name.
    expect(inList('Surface'), findsOneWidget);
    expect(inList('Checkbox'), findsOneWidget);
    expect(inList('Placeholder'), findsOneWidget);
    expect(inList('Gallery'), findsNothing);

    // Selecting Surface previews the gallery: a cell per variant × swatch.
    await tapInList(tester, 'Surface');
    expect(
      find.byType(tome.Surface),
      findsNWidgets(
        tome.SurfaceVariant.values.length * tome.SemanticSwatch.values.length,
      ),
    );
  });

  testWidgets('selecting a story previews it on the canvas', (tester) async {
    await tester.pumpWidget(const PlaygroundApp());

    await tapInList(tester, 'Placeholder');
    expect(find.byType(tome.Placeholder), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(tome.Placeholder),
        matching: find.text('Drop here'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('knobs steer the story', (tester) async {
    await tester.pumpWidget(const PlaygroundApp());

    // The gallery has nothing to steer.
    expect(find.text('This story has no knobs.'), findsOneWidget);

    // The Placeholder story does: picking the error swatch pill re-resolves
    // the previewed placeholder.
    await tapInList(tester, 'Placeholder');
    await tester.tap(find.text('error'));
    await tester.pump();

    final element = tester.element(
      find.descendant(
        of: find.byType(tome.Placeholder),
        matching: find.text('Drop here'),
      ),
    );
    final expected = const tome.Theme().widgets.surface
        .resolve(tome.SemanticSwatch.error, tome.SurfaceVariant.placeholder)
        .foreground;
    expect(DefaultTextStyle.of(element).style.color, expected);
  });

  testWidgets('the App tab retunes the global theme', (tester) async {
    await tester.pumpWidget(const PlaygroundApp());

    await tester.tap(find.text('App'));
    await tester.pump();
    expect(find.text('Dark mode'), findsOneWidget);

    // Flip to light: the canvas background follows the palette.
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    final canvas = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(StoryCanvas),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(
      canvas.color,
      const tome.Palette(brightness: Brightness.light).background,
    );

    // The playground's own chrome follows the toggle too.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });
}
