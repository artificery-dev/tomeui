import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, double width, Widget child) async {
    tester.view
      ..physicalSize = Size(width, 800)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await tester.pumpWidget(TomeApp(home: child));
  }

  group('the bands', () {
    test('are the thresholds’ floors, not their ceilings', () {
      const breakpoints = Breakpoints();
      expect(breakpoints.at(0), Breakpoint.compact);
      expect(breakpoints.at(619), Breakpoint.compact);
      expect(breakpoints.at(620), Breakpoint.medium);
      expect(breakpoints.at(899), Breakpoint.medium);
      expect(breakpoints.at(900), Breakpoint.expanded);
      expect(breakpoints.at(1239), Breakpoint.expanded);
      expect(breakpoints.at(1240), Breakpoint.large);
    });

    test('are ordered, so responsive code can ask for “roomier than”', () {
      expect(Breakpoint.expanded.atLeast(Breakpoint.medium), isTrue);
      expect(Breakpoint.expanded.atLeast(Breakpoint.expanded), isTrue);
      expect(Breakpoint.compact.atLeast(Breakpoint.medium), isFalse);
    });
  });

  testWidgets('BreakpointBuilder reads the window, not the slot', (
    tester,
  ) async {
    await pumpAt(
      tester,
      1000,
      const SizedBox(
        width: 200,
        child: BreakpointBuilder(builder: _name),
      ),
    );

    expect(find.text('expanded'), findsOneWidget);
  });

  testWidgets('a narrower window is a narrower band', (tester) async {
    await pumpAt(tester, 500, const BreakpointBuilder(builder: _name));
    expect(find.text('compact'), findsOneWidget);
  });

  testWidgets('the thresholds are the theme’s', (tester) async {
    tester.view
      ..physicalSize = const Size(500, 800)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const TomeApp(
        theme: Theme(breakpoints: Breakpoints(compact: 400)),
        home: BreakpointBuilder(builder: _name),
      ),
    );

    expect(find.text('medium'), findsOneWidget, reason: '500 clears 400 now');
  });

  testWidgets('ContainerSizeBuilder reads the slot, not the window', (
    tester,
  ) async {
    late ContainerSize seen;
    await pumpAt(
      tester,
      1000,
      // Centred so the box is free to be 300 wide: a route hands its child
      // tight constraints, and a SizedBox cannot shrink under those.
      Center(
        child: SizedBox(
          width: 300,
          height: 120,
          child: ContainerSizeBuilder(
          builder: (context, size) {
              seen = size;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(seen.width, 300);
    expect(seen.height, 120);
    expect(seen.breakpoint, Breakpoint.compact);
    expect(seen.isBoundedWidth, isTrue);
  });

  testWidgets('an unbounded slot is as roomy as it gets', (tester) async {
    late ContainerSize seen;
    await pumpAt(
      tester,
      400,
      ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ContainerSizeBuilder(
            builder: (context, size) {
              seen = size;
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );

    expect(seen.isBoundedWidth, isFalse);
    expect(seen.width, double.infinity);
    expect(seen.breakpoint, Breakpoint.large);
  });
}

Widget _name(BuildContext context, Breakpoint breakpoint) =>
    Text(breakpoint.name, textDirection: TextDirection.ltr);
