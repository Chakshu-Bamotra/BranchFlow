import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BranchFlowApp());
}

class BranchFlowApp extends StatelessWidget {
  const BranchFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BranchFlow - Cross-Branch Library Network',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (!auth.isAuthenticated) {
          return const AuthScreen();
        }
        if (auth.currentUser?.isEmailVerified == false) {
          return EmailVerificationScreen(
            onVerified: () {},
          );
        }
        return const HomeScreen();
      },
    );
  }
}
