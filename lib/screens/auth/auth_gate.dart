import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/profile/profile_setup_screen.dart';
import 'package:sahay/screens/welcome_screen.dart';

/// Entry gateway routing users based on authentication and guest state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Initial loading
    if (authProvider.isLoading && authProvider.currentUser == null && !authProvider.isGuest) {
      return const Scaffold(
        backgroundColor: AppColors.warmIvory,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.indianTeal),
          ),
        ),
      );
    }

    // Authenticated state
    if (authProvider.isAuthenticated) {
      final userLang = authProvider.currentUser?.preferredLanguage;
      if (userLang != null && userLang.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.read<LocaleProvider>().syncWithUserLanguage(userLang);
          }
        });
      }
      if (authProvider.isProfileComplete) {
        return const HomeScreen();
      } else {
        return const ProfileSetupScreen();
      }
    }

    // Guest state
    if (authProvider.isGuest) {
      return const HomeScreen();
    }

    // Unauthenticated state
    return const WelcomeScreen();
  }
}

