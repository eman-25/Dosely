// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dosely/main.dart';   // ← fixed package name

void main() {
  testWidgets('Welcome screen shows login & register buttons', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const DoselyApp());

    // Check that welcome screen elements are present
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    // Optional: tap Login and verify navigation (requires more setup)
    // await tester.tap(find.text('Login'));
    // await tester.pumpAndSettle();
    // expect(find.byType(LoginScreen), findsOneWidget);
  });
}