import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/utils/validators.dart';
import 'package:sahay/widgets/language_toggle.dart';

/// Screen allowing new users to create an account with email and basic details.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _consentAccepted = false;

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
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (!_formKey.currentState!.validate()) return;

    final lang = context.read<LocaleProvider>().languageCode;
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      consentAccepted: _consentAccepted,
      consentVersion: '1.0',
      lang: lang,
    );

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _submitGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final lang = context.read<LocaleProvider>().languageCode;

    final success = await auth.signInWithGoogle(lang: lang);
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showTermsDialog(BuildContext context, bool isHi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.warmIvory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isHi ? 'सेवा की शर्तें एवं गोपनीयता नीति' : 'Terms of Service & Privacy Policy',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 12),
                Text(
                  isHi
                      ? '1. सहाय (SAHAY) एक नागरिक कल्याण सहायक है।\n'
                        '2. हम आधार, पैन कार्ड, या बैंक खाते का विवरण कभी एकत्र नहीं करते हैं।\n'
                        '3. आपकी जानकारी का उपयोग केवल सरकारी कल्याणकारी योजनाओं की पात्रता जांचने के लिए किया जाता है।\n'
                        '4. आप किसी भी समय अपनी प्रोफ़ाइल और डेटा को हटा सकते हैं।'
                      : '1. SAHAY is a welfare scheme discovery assistant for citizens.\n'
                        '2. We never store or collect Aadhaar, PAN card, or bank account credentials.\n'
                        '3. Your demographic information is exclusively used to check eligibility for schemes.\n'
                        '4. You may edit or delete your account and data at any time from your profile.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indianTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isHi ? 'समझ गया' : 'I Understand'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  isHi ? 'खाता बनाएं' : 'Create Account',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.deepNavy,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isHi
                      ? 'अपनी योजनाओं की खोज और लाभ सुरक्षित करने के लिए पंजीकरण करें।'
                      : 'Sign up to discover schemes and track benefits privately.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.deepNavy.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),

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

                // Full Name
                Text(
                  isHi ? 'पूरा नाम' : 'Full Name',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: isHi ? 'उदा. राहुल शर्मा' : 'e.g. Rahul Sharma',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.indianTeal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (v) => Validators.validateFullName(v, lang),
                ),
                const SizedBox(height: 14),

                // Mobile Number
                Text(
                  isHi ? 'मोबाइल नंबर (10 अंक)' : 'Mobile Number (10 digits)',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '9876543210',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.indianTeal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (v) => Validators.validateMobileNumber(v, lang),
                ),
                const SizedBox(height: 14),

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
                    hintText: 'name@example.com',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.indianTeal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (v) => Validators.validateEmail(v, lang),
                ),
                const SizedBox(height: 14),

                // Password
                Text(
                  isHi ? 'पासवर्ड (कम से कम 8 अक्षर)' : 'Password (min 8 characters)',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
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
                  ),
                  validator: (v) => Validators.validatePassword(v, lang),
                ),
                const SizedBox(height: 14),

                // Confirm Password
                Text(
                  isHi ? 'पासवर्ड की पुष्टि करें' : 'Confirm Password',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.indianTeal),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  validator: (v) => Validators.validateConfirmPassword(
                    _passwordController.text,
                    v,
                    lang,
                  ),
                ),
                const SizedBox(height: 14),

                // Consent Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _consentAccepted,
                      activeColor: AppColors.indianTeal,
                      onChanged: (val) {
                        setState(() => _consentAccepted = val ?? false);
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTermsDialog(context, isHi),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text.rich(
                            TextSpan(
                              text: isHi
                                  ? 'मैं सेवा की शर्तों एवं '
                                  : 'I agree to the ',
                              style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy),
                              children: [
                                TextSpan(
                                  text: isHi
                                      ? 'गोपनीयता नीति से सहमत हूँ।'
                                      : 'Terms of Service & Privacy Policy.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.indianTeal,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Signup Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (!_consentAccepted || auth.isLoading) ? null : _submitSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indianTeal,
                      disabledBackgroundColor: AppColors.indianTeal.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            isHi ? 'खाता बनाएं' : 'Create Account',
                            style: AppTextStyles.buttonText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

                // Google Button
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: auth.isLoading ? null : _submitGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppColors.cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                const SizedBox(height: 20),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isHi ? 'पहले से खाता है? ' : 'Already have an account? ',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<AuthProvider>().clearError();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        isHi ? 'साइन इन करें' : 'Sign In',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.indianTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
