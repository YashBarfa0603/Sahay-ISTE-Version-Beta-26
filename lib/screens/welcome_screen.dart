import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/screens/auth/login_screen.dart';
import 'package:sahay/widgets/language_toggle.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.languageCode;
    final characterAsset = localeProvider.getCharacterAsset(currentLang);
    final l10n = SahayLocalizations.of(context);

    // Headings
    final namasteText = l10n.namaste.isNotEmpty && l10n.namaste != 'namaste'
        ? l10n.namaste
        : (currentLang == 'hi'
            ? 'नमस्ते'
            : (currentLang == 'ta'
                ? 'வணக்கம்'
                : (currentLang == 'mr'
                    ? 'नमस्कार'
                    : (currentLang == 'bn'
                        ? 'নমস্কার'
                        : (currentLang == 'gu'
                            ? 'નમસ્તે'
                            : (currentLang == 'kn'
                                ? 'ನಮಸ್ಕಾರ'
                                : (currentLang == 'or' ? 'ନମସ୍କାର' : 'Namaste')))))));

    final welcomeTitle = l10n.welcomeTitle.isNotEmpty && l10n.welcomeTitle != 'welcomeTitle'
        ? l10n.welcomeTitle
        : (currentLang == 'hi' ? 'सहाय में आपका स्वागत है' : 'Welcome to SAHAY');

    final welcomeSubtitle = l10n.welcomeSubtitle.isNotEmpty && l10n.welcomeSubtitle != 'welcomeSubtitle'
        ? l10n.welcomeSubtitle
        : (currentLang == 'hi'
            ? 'सहाय (SAHAY) एक बहुभाषी सहायक है जो नागरिकों को उन सरकारी योजनाओं की खोज करने और उपलब्ध लाभों को समझने में मदद करता है जिनके वे पात्र हो सकते हैं।'
            : 'SAHAY is a multilingual assistant that helps citizens discover government schemes they may be eligible for and understand the benefits available to them.');

    final getStartedText = l10n.getStarted.isNotEmpty && l10n.getStarted != 'getStarted'
        ? l10n.getStarted
        : (currentLang == 'hi' ? 'शुरू करें' : 'Get Started');

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mascotHeight = (constraints.maxHeight * 0.35).clamp(230.0, 320.0);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Header with Language Toggle
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.paleSage,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const LanguageToggle(
                                iconColor: AppColors.indianTeal,
                                iconSize: 26,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Mascot Image
                        SizedBox(
                          height: mascotHeight,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: ClipRRect(
                              key: ValueKey<String>(characterAsset),
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                characterAsset,
                                height: mascotHeight,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: mascotHeight * 0.9,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.paleSage,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_rounded,
                                      size: 80,
                                      color: AppColors.indianTeal,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Namaste Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.softSaffron.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.softSaffron,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            namasteText,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.deepNavy,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Welcome Title
                        Text(
                          welcomeTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.deepNavy,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.deepNavy.withValues(alpha: 0.78),
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 16),

                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.indianTeal.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.indianTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    getStartedText,
                                    style: AppTextStyles.buttonText.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: () {
                            context.read<AuthProvider>().enterGuestMode();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          ),
                          child: Text(
                            currentLang == 'hi'
                                ? 'अतिथि के रूप में जारी रखें'
                                : 'Continue as Guest',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.deepNavy.withValues(alpha: 0.75),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
