import 'package:flutter_test/flutter_test.dart';
import 'package:paws_flutter/main.dart';

void main() {
  testWidgets('PawsApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PawsApp());
    expect(find.byType(PawsApp), findsOneWidget);
  });
}
