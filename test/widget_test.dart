import 'package:flutter_test/flutter_test.dart';
import 'package:vdm_manager/main.dart';

void main() {
  testWidgets('VdmManagerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VdmManagerApp());
    expect(find.byType(VdmManagerApp), findsOneWidget);
  });
}
