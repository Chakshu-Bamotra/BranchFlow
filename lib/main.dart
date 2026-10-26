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
    return StreamBuilder<UserModel?>(
      stream: auth.authStateChanges,
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        // While stream initializes
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }
        if (!user.isEmailVerified) {
          return EmailVerificationScreen(
            onVerified: () {},
          );
        }
        return const HomeScreen();
      },
    );
  }
}
