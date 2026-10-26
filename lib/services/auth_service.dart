import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'member' or 'librarian'
  final bool isEmailVerified;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isEmailVerified,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    bool? isEmailVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  UserModel? _currentUser = const UserModel(
    uid: 'MEM-4021',
    email: 'priya.sharma@library.org',
    displayName: 'Priya Sharma',
    role: 'member',
    isEmailVerified: true,
  );

  bool _isFirebaseAvailable = false;
  final _authStreamController = StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Stream<UserModel?> get authStateChanges {
    // Emit initial state immediately
    Future.microtask(() => _authStreamController.add(_currentUser));
    return _authStreamController.stream;
  }

  void _notifyStateChange() {
    _authStreamController.add(_currentUser);
    notifyListeners();
  }

  static String mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password. Please verify your credentials.';
      case 'user-not-found':
        return 'No registered account found with this email.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This library account has been temporarily disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again in a few moments.';
      case 'network-request-failed':
        return 'Network connection error. Please verify your internet connection.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }

  void checkFirebaseStatus() {
    try {
      _isFirebaseAvailable = Firebase.apps.isNotEmpty;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  // -------------------------------------------------------------
  // SIGN IN
  // -------------------------------------------------------------
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return AuthResult(success: false, message: 'Please enter both email and password.');
    }

    try {
      if (_isFirebaseAvailable) {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final fbUser = credential.user;
        _currentUser = UserModel(
          uid: fbUser?.uid ?? 'UID-${DateTime.now().millisecondsSinceEpoch}',
          email: fbUser?.email ?? cleanEmail,
          displayName: fbUser?.displayName ?? cleanEmail.split('@').first,
          role: cleanEmail.contains('staff') || cleanEmail.contains('admin') ? 'librarian' : 'member',
          isEmailVerified: fbUser?.emailVerified ?? false,
        );
      } else {
        // High-fidelity local demo auth
        await Future.delayed(const Duration(milliseconds: 600));
        final role = cleanEmail.contains('staff') || cleanEmail.contains('admin') ? 'librarian' : 'member';
        _currentUser = UserModel(
          uid: 'UID-${cleanEmail.hashCode.abs()}',
          email: cleanEmail,
          displayName: cleanEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
          role: role,
          isEmailVerified: true,
        );
      }
      _notifyStateChange();
      return AuthResult(success: true, message: 'Signed in successfully.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message ?? 'Authentication failed.');
    } catch (e) {
      return AuthResult(success: false, message: 'Sign in error: $e');
    }
  }

  // -------------------------------------------------------------
  // SIGN UP
  // -------------------------------------------------------------
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.length < 6) {
      return AuthResult(
        success: false,
        message: 'Please provide a valid email and a password of at least 6 characters.',
      );
    }

    try {
      if (_isFirebaseAvailable) {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        final fbUser = credential.user;
        await fbUser?.updateDisplayName(fullName);
        await fbUser?.sendEmailVerification();

        _currentUser = UserModel(
          uid: fbUser?.uid ?? 'UID-${DateTime.now().millisecondsSinceEpoch}',
          email: cleanEmail,
          displayName: fullName,
          role: role,
          isEmailVerified: false,
        );
      } else {
        // High-fidelity local demo auth
        await Future.delayed(const Duration(milliseconds: 700));
        _currentUser = UserModel(
          uid: 'UID-${cleanEmail.hashCode.abs()}',
          email: cleanEmail,
          displayName: fullName,
          role: role,
          isEmailVerified: false, // Triggers email verification workflow
        );
      }
      _notifyStateChange();
      return AuthResult(
        success: true,
        message: 'Account created! Verification email sent to $cleanEmail.',
        requiresVerification: true,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message ?? 'Sign up failed.');
    } catch (e) {
      return AuthResult(success: false, message: 'Sign up error: $e');
    }
  }

  // -------------------------------------------------------------
  // FORGOT PASSWORD / PASSWORD RESET
  // -------------------------------------------------------------
  Future<AuthResult> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return AuthResult(success: false, message: 'Please enter a valid email address.');
    }

    try {
      if (_isFirebaseAvailable) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
      return AuthResult(
        success: true,
        message: 'Password reset link sent! Check your inbox at $cleanEmail.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message ?? 'Failed to send reset email.');
    } catch (e) {
      return AuthResult(success: false, message: 'Error: $e');
    }
  }

  // -------------------------------------------------------------
  // SEND EMAIL VERIFICATION
  // -------------------------------------------------------------
  Future<AuthResult> sendEmailVerification() async {
    if (_currentUser == null) {
      return AuthResult(success: false, message: 'No user currently signed in.');
    }

    try {
      if (_isFirebaseAvailable) {
        final fbUser = FirebaseAuth.instance.currentUser;
        await fbUser?.sendEmailVerification();
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return AuthResult(
        success: true,
        message: 'Verification link resent to ${_currentUser!.email}.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message ?? 'Failed to resend verification.');
    } catch (e) {
      return AuthResult(success: false, message: 'Error: $e');
    }
  }

  // -------------------------------------------------------------
  // SIMULATE / CONFIRM VERIFICATION
  // -------------------------------------------------------------
  Future<bool> checkEmailVerified() async {
    if (_isFirebaseAvailable) {
      final fbUser = FirebaseAuth.instance.currentUser;
      await fbUser?.reload();
      final verified = fbUser?.emailVerified ?? false;
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(isEmailVerified: verified);
        _notifyStateChange();
      }
      return verified;
    } else {
      // In demo mode: instantly verify on user request
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        _notifyStateChange();
      }
      return true;
    }
  }

  // -------------------------------------------------------------
  // SIGN OUT
  // -------------------------------------------------------------
  Future<void> signOut() async {
    if (_isFirebaseAvailable) {
      await FirebaseAuth.instance.signOut();
    }
    _currentUser = null;
    _notifyStateChange();
  }
}

class AuthResult {
  final bool success;
  final String message;
  final bool requiresVerification;

  AuthResult({
    required this.success,
    required this.message,
    this.requiresVerification = false,
  });
}
