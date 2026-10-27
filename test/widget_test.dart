import 'package:flutter_test/flutter_test.dart';
import 'package:branch_flow/main.dart';
import 'package:branch_flow/services/auth_service.dart';

void main() {
  testWidgets('BranchFlow launch, splash and dashboard smoke test', (WidgetTester tester) async {
    // 1. Launch app on SplashScreen
    await tester.pumpWidget(const BranchFlowApp());
    expect(find.text('BranchFlow'), findsOneWidget);
    expect(find.text('Cross-Branch Library Network'), findsOneWidget);

    // 2. Fast-forward past 2-second splash timer -> lands on AuthScreen
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 3. Verify AuthScreen rendered with Sign In form
    expect(find.text('Sign in to access unified library catalog'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);

    // 4. Authenticate user to transition to Dashboard
    final signInFuture = AuthService().signIn(email: 'staff@branchflow.lib', password: 'password123');
    await tester.pump(const Duration(milliseconds: 500));
    await signInFuture;
    await tester.pumpAndSettle();

    // 5. Verify main Athenaeum dashboard renders
    expect(find.text('Instant Cross-Branch Clearance'), findsOneWidget);
    expect(find.text('Shelf'), findsOneWidget);
    expect(find.text('Return Desk'), findsOneWidget);
    expect(find.text('Network Map'), findsWidgets);
  });
}
