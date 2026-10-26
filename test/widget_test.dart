import 'package:flutter_test/flutter_test.dart';
import 'package:branch_flow/main.dart';

void main() {
  testWidgets('BranchFlow launch, splash and dashboard smoke test', (WidgetTester tester) async {
    // 1. Launch app on SplashScreen
    await tester.pumpWidget(const BranchFlowApp());
    expect(find.text('BranchFlow'), findsOneWidget);
    expect(find.text('Cross-Branch Library Network'), findsOneWidget);

    // 2. Fast-forward past 2-second splash timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 3. Verify main dashboard renders after auto-transition
    expect(find.text('Instant Cross-Branch Clearance'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Return Desk'), findsOneWidget);
    expect(find.text('Transit Hub'), findsWidgets);
  });
}
