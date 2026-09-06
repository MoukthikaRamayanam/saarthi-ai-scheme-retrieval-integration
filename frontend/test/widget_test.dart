import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App initializes and renders Find Schemes screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SaarthiApp());
    expect(find.text('Find Schemes For You'), findsOneWidget);
    expect(find.text('Find Matching Schemes'), findsOneWidget);
  });
}
