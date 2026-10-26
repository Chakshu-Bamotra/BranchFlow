import 'package:flutter_test/flutter_test.dart';
import 'package:branch_flow/services/auth_service.dart';

void main() {
  group('Auth, Forgot Password & Email Verification Tests', () {
    late AuthService auth;

    setUp(() {
      auth = AuthService();
    });

    test('Sign Up creates user with unverified email requiring verification', () async {
      final res = await auth.signUp(
        email: 'new.member@library.org',
        password: 'securePassword123',
        fullName: 'New Reader',
        role: 'member',
      );

      expect(res.success, isTrue);
      expect(res.requiresVerification, isTrue);
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, 'new.member@library.org');
      expect(auth.currentUser!.isEmailVerified, isFalse);
    });

    test('Email Verification confirms verification status', () async {
      // User is currently unverified from previous step
      expect(auth.currentUser!.isEmailVerified, isFalse);

      // Trigger verification confirmation
      final isVerified = await auth.checkEmailVerified();
      expect(isVerified, isTrue);
      expect(auth.currentUser!.isEmailVerified, isTrue);
    });

    test('Forgot Password sends reset link to registered email', () async {
      final resetRes = await auth.sendPasswordReset('new.member@library.org');
      expect(resetRes.success, isTrue);
      expect(resetRes.message, contains('Password reset link sent'));

      // Invalid email test
      final invalidRes = await auth.sendPasswordReset('not-an-email');
      expect(invalidRes.success, isFalse);
      expect(invalidRes.message, contains('valid email'));
    });

    test('Sign Out clears active user session', () async {
      expect(auth.isAuthenticated, isTrue);
      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('Sign In authenticates registered user', () async {
      final signInRes = await auth.signIn(
        email: 'priya.sharma@library.org',
        password: 'password123',
      );

      expect(signInRes.success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser!.email, 'priya.sharma@library.org');
      expect(auth.currentUser!.isEmailVerified, isTrue);
    });
  });
}
