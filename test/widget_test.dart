import 'package:flutter_test/flutter_test.dart';

import 'package:precision_pos/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PrecisionPOSApp());
    expect(find.text('Precision POS'), findsWidgets);
  });
}
