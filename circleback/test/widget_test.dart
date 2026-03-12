import 'package:flutter_test/flutter_test.dart';
import 'package:bantou/main.dart';

void main() {
  testWidgets('App launches and shows auth screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BantouApp());
    // Verify the app title is present on the auth screen
    expect(find.text('Bantou'), findsOneWidget);
  });
}
