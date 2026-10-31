import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/screens/auth/auth_gate.dart';
import 'package:sahay/screens/auth/signup_screen.dart';
import 'package:sahay/utils/auth_strings.dart';
import 'package:sahay/utils/validators.dart';
import 'package:sahay/widgets/language_toggle.dart';

/// Screen allowing existing users to authenticate via email/password or Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (!_formKey.currentState!.validate()) return;

    final lang = context.read<LocaleProvider>().languageCode;
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      lang: lang,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _submitGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final lang = context.read<LocaleProvider>().languageCode;

    final success = await auth.signInWithGoogle(lang: lang);
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    final isHi = context.read<LocaleProvider>().languageCode == 'hi';

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHi
              ? 'कृपया पहले अपना ईमेल पता दर्ज करें'
              : 'Please enter your email address first',
          ),
          backgroundColor: AppColors.deepNavy,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final lang = context.read<LocaleProvider>().languageCode;
    final sent = await auth.sendPasswordReset(email, lang: lang);

    if (mounted) {
      final msg = sent
          ? AuthStrings.getMessage('reset-email-sent', lang)
          : (auth.errorMessage ?? 'Unable to send reset email');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: sent ? AppColors.forestGreen : AppColors.mutedCoral,
        ),
      );
    }
  }

  void _continueAsGuest() {
    context.read<AuthProvider>().enterGuestMode();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isHi = context.watch<LocaleProvider>().languageCode == 'hi';
    final lang = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.deepNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: LanguageToggle(iconColor: AppColors.indianTeal, iconSize: 24),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    isHi ? 'साइन इन करें' : 'Sign In',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.deepNavy,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isHi
                        ? 'अपनी योजनाओं और जानकारी को सुरक्षित रखने के लिए प्रवेश करें।'
                        : 'Sign in to access your eligible government schemes.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.deepNavy.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error banner
                  if (auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mutedCoral.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.mutedCoral.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.mutedCoral, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.deepNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  Text(
                    isHi ? 'ईमेल पता' : 'Email Address',
                    style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: isHi ? 'उदा. name@example.com' : 'e.g. name@example.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.indianTeal),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.indianTeal, width: 2),
                      ),
                    ),
                    validator: (v) => Validators.validateEmail(v, lang),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Text(
                    isHi ? 'पासवर्ड' : 'Password',
                    style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: isHi ? 'पासवर्ड दर्ज करें' : 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.indianTeal),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.indianTeal, width: 2),
                      ),
                    ),
                    validator: (v) => Validators.validatePassword(v, lang),
                  ),
                  const SizedBox(height: 8),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: auth.isLoading ? null : _handleForgotPassword,
                      child: Text(
                        isHi ? 'पासवर्ड भूल गए?' : 'Forgot Password?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.indianTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Login button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indianTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isHi ? 'साइन इन करें' : 'Sign In',
                              style: AppTextStyles.buttonText.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          isHi ? 'या' : 'OR',
                          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google button
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: auth.isLoading ? null : _submitGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: AppColors.cardBorder, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.g_mobiledata_rounded, color: Colors.redAccent, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            isHi ? 'गूगल से जारी रखें' : 'Continue with Google',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isHi ? 'खाता नहीं है? ' : "Don't have an account? ",
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<AuthProvider>().clearError();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: Text(
                          isHi ? 'साइन अप करें' : 'Sign Up',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.indianTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Guest button
                  TextButton(
                    onPressed: auth.isLoading ? null : _continueAsGuest,
                    child: Text(
                      isHi ? 'अतिथि के रूप में जारी रखें' : 'Continue as Guest',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.deepNavy.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

