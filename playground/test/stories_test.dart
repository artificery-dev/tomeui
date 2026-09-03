import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_playground/stories/stories.dart';

void main() {
  // Room enough that a story which lays out honestly isn't reported as an
  // overflow — the playground's canvas is a desktop pane, not a phone.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1400, 1000);
    view.devicePixelRatio = 1;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('every story in the catalog previews without complaint', (
    tester,
  ) async {
    final complaints = <String>[];
    for (final category in buildStories()) {
      for (final story in category.allStories) {
        await tester.pumpWidget(TomeApp(home: Builder(builder: story.builder)));
        final trouble = tester.takeException();
        if (trouble != null) {
          complaints.add('${category.name} / ${story.name}: $trouble');
        }
      }
    }
    expect(complaints, isEmpty);
  });
}
