import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/main.dart';

void main() {
  testWidgets('SmartOrderButtonApp mounts root widget cleanly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartOrderButtonApp());
    expect(find.byType(SmartOrderButtonApp), findsOneWidget);
  });
}
