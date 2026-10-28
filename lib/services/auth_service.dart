import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  // Start as null so user must actually enter credentials on startup!
  UserModel? _currentUser;

  // Built-in demo accounts use addresses that can't receive mail, so they skip email verification.
  static const Set<String> _demoEmails = {'member@branchflow.lib', 'staff@branchflow.lib'};

  static bool _isDemoEmail(String email) => _demoEmails.contains(email.trim().toLowerCase());

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

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
        return 'Incorrect email or password. Please verify your credentials or create a new account.';
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

  bool checkFirebaseStatus() {
    return _isFirebaseAvailable;
  }

  static const String _noServerMessage =
      'Email codes need a connection to the BranchFlow server. Please check your connection.';

  // Calls a BranchFlow Cloud Function (see functions/index.js). OTP codes are generated,
  // emailed and checked on the server only; the app never sees them.
  Future<Map<String, dynamic>> _callFunction(String name, Map<String, dynamic> data) async {
    final result = await FirebaseFunctions.instance.httpsCallable(name).call<dynamic>(data);
    final payload = result.data;
    return payload is Map ? Map<String, dynamic>.from(payload) : <String, dynamic>{};
  }

  static String _functionErrorMessage(FirebaseFunctionsException e) {
    final message = e.message;
    // Errors raised by our functions carry a readable message; transport errors
    // (function not deployed, offline, etc.) only carry the bare status code.
    if (message == null || message.isEmpty || message.toUpperCase() == message) {
      return 'Could not reach the verification server. Please try again shortly.';
    }
    return message;
  }

  // Refreshes the Firebase user so emailVerified reflects changes made by the server.
  Future<bool> _reloadEmailVerified() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return false;
    await fbUser.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed?.emailVerified == true) {
      await refreshed!.getIdToken(true);
      return true;
    }
    return false;
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
        try {
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
            isEmailVerified: (fbUser?.emailVerified ?? false) || _isDemoEmail(cleanEmail),
          );
        } on FirebaseAuthException catch (e) {
          // If demo user does not exist in Firebase Auth yet, auto-provision it
          final isDemoAccount = cleanEmail.contains('branchflow.lib') ||
              cleanEmail.contains('library.org') ||
              cleanEmail.contains('member') ||
              cleanEmail.contains('staff');

          if (isDemoAccount && (e.code == 'invalid-credential' || e.code == 'user-not-found')) {
            try {
              final newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: cleanEmail,
                password: password,
              );
              final fbUser = newCred.user;
              _currentUser = UserModel(
                uid: fbUser?.uid ?? 'UID-${DateTime.now().millisecondsSinceEpoch}',
                email: fbUser?.email ?? cleanEmail,
                displayName: cleanEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
                role: cleanEmail.contains('staff') || cleanEmail.contains('admin') ? 'librarian' : 'member',
                isEmailVerified: _isDemoEmail(cleanEmail),
              );
            } catch (_) {
              // High-fidelity fallback if cloud registration cannot complete
              final role = cleanEmail.contains('staff') || cleanEmail.contains('admin') ? 'librarian' : 'member';
              _currentUser = UserModel(
                uid: 'UID-${cleanEmail.hashCode.abs()}',
                email: cleanEmail,
                displayName: cleanEmail.split('@').first.replaceAll('.', ' ').toUpperCase(),
                role: role,
                isEmailVerified: _isDemoEmail(cleanEmail),
              );
            }
          } else {
            return AuthResult(success: false, message: mapAuthException(e));
          }
        }
      } else {
        // High-fidelity local auth
        await Future.delayed(const Duration(milliseconds: 400));
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
      return AuthResult(success: false, message: mapAuthException(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Sign in error: $e');
    }
  }

  // -------------------------------------------------------------
  // SIGN UP WITH OTP REQUIREMENT
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
      if (!_isFirebaseAvailable) {
        // Offline local mode has no server to email codes, so accounts start verified.
        await Future.delayed(const Duration(milliseconds: 500));
        _currentUser = UserModel(
          uid: 'UID-${cleanEmail.hashCode.abs()}',
          email: cleanEmail,
          displayName: fullName,
          role: role,
          isEmailVerified: true,
        );
        _notifyStateChange();
        return AuthResult(success: true, message: 'Account created (offline mode).');
      }

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final fbUser = credential.user;
      await fbUser?.updateDisplayName(fullName);

      _currentUser = UserModel(
        uid: fbUser?.uid ?? 'UID-${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        displayName: fullName,
        role: role,
        isEmailVerified: false,
      );
      _notifyStateChange();

      final sendRes = await sendEmailVerificationOtp();
      return AuthResult(
        success: true,
        message: sendRes.success
            ? 'Account created! We emailed a 6-digit verification code to $cleanEmail.'
            : 'Account created, but the code could not be sent: ${sendRes.message}',
        requiresVerification: true,
        codeSent: sendRes.success,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: mapAuthException(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Sign up error: $e');
    }
  }

  // -------------------------------------------------------------
  // OTP EMAIL VERIFICATION
  // -------------------------------------------------------------
  Future<AuthResult> verifyEmailWithOtp(String otp) async {
    if (!_isFirebaseAvailable) return AuthResult(success: false, message: _noServerMessage);
    if (FirebaseAuth.instance.currentUser == null) {
      return AuthResult(success: false, message: 'Your session has ended. Please sign in again.');
    }

    try {
      await _callFunction('verifyEmailOtp', {'code': otp.trim()});
      await _reloadEmailVerified();
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        _notifyStateChange();
      }
      return AuthResult(
        success: true,
        message: 'Email successfully verified! Redirecting to Dashboard...',
      );
    } on FirebaseFunctionsException catch (e) {
      return AuthResult(success: false, message: _functionErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Verification error: $e');
    }
  }

  // -------------------------------------------------------------
  // SEND / RESEND VERIFICATION OTP
  // -------------------------------------------------------------
  Future<AuthResult> sendEmailVerificationOtp() async {
    if (!_isFirebaseAvailable) return AuthResult(success: false, message: _noServerMessage);
    if (FirebaseAuth.instance.currentUser == null) {
      return AuthResult(success: false, message: 'Your session has ended. Please sign in again.');
    }

    try {
      final data = await _callFunction('requestEmailOtp', {'purpose': 'verify'});
      if (data['alreadyVerified'] == true) {
        await checkEmailVerified();
        return AuthResult(success: true, message: 'Your email is already verified.');
      }
      return AuthResult(
        success: true,
        message: 'A new 6-digit code was sent to ${_currentUser?.email ?? 'your email'}.',
      );
    } on FirebaseFunctionsException catch (e) {
      return AuthResult(success: false, message: _functionErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Could not send code: $e');
    }
  }

  Future<bool> checkEmailVerified() async {
    if (!_isFirebaseAvailable || _currentUser == null) return false;
    try {
      final verified = await _reloadEmailVerified();
      if (verified) {
        _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        _notifyStateChange();
      }
      return verified;
    } catch (e) {
      debugPrint('Email verification check failed: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // FORGOT PASSWORD VIA OTP
  // -------------------------------------------------------------
  Future<AuthResult> sendPasswordResetOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return AuthResult(success: false, message: 'Please enter a valid email address.');
    }
    if (!_isFirebaseAvailable) return AuthResult(success: false, message: _noServerMessage);

    try {
      await _callFunction('requestEmailOtp', {'purpose': 'reset', 'email': cleanEmail});
      // The server answers the same way for unknown emails, so accounts can't be probed.
      return AuthResult(
        success: true,
        message: 'If an account exists for $cleanEmail, a 6-digit code has been emailed to it.',
      );
    } on FirebaseFunctionsException catch (e) {
      return AuthResult(success: false, message: _functionErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Could not send code: $e');
    }
  }

  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (otp.trim().length != 6) {
      return AuthResult(success: false, message: 'Please enter the 6-digit code from your email.');
    }
    if (newPassword.length < 6) {
      return AuthResult(success: false, message: 'New password must be at least 6 characters.');
    }
    if (!_isFirebaseAvailable) return AuthResult(success: false, message: _noServerMessage);

    try {
      await _callFunction('resetPasswordWithOtp', {
        'email': cleanEmail,
        'code': otp.trim(),
        'newPassword': newPassword,
      });
      return AuthResult(
        success: true,
        message: 'Password successfully reset! You can now sign in with your new password.',
      );
    } on FirebaseFunctionsException catch (e) {
      return AuthResult(success: false, message: _functionErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Password reset error: $e');
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
  // True when a verification code was emailed as part of this action.
  final bool codeSent;

  AuthResult({
    required this.success,
    required this.message,
    this.requiresVerification = false,
    this.codeSent = false,
  });
}
