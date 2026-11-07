import 'package:flutter_test/flutter_test.dart';
import 'package:transnova_flutter/main.dart';

void main() {
  testWidgets('TransnovaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TransnovaApp());
    expect(find.byType(TransnovaApp), findsOneWidget);
  });
}
