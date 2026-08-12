import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  testWidgets('re-exports the widgets layer', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Text('tome')),
      ),
    );

    expect(find.text('tome'), findsOneWidget);
  });
}
