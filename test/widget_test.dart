import 'package:flutter_test/flutter_test.dart';
import 'package:branch_flow/main.dart';

void main() {
  testWidgets('BranchFlow smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BranchFlowApp());
    await tester.pumpAndSettle();

    // Verify that BranchFlow title and key UI elements are present
    expect(find.text('BranchFlow'), findsOneWidget);
    expect(find.text('Instant Cross-Branch Clearance'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Return Desk'), findsOneWidget);
    expect(find.text('Transit Hub'), findsWidgets);
  });
}
