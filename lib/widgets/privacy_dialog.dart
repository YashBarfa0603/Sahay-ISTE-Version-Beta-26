import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/auth/auth_gate.dart';
import 'package:sahay/services/privacy_service.dart';

class PrivacyDialog {
  PrivacyDialog._();

  /// Shows confirmation dialog before clearing all temporary session data on shared phones.
  static Future<void> showEndSessionConfirmation(BuildContext context) {
    final lang = context.read<LocaleProvider>().languageCode;
    final isHi = lang == 'hi';

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mutedCoral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.mutedCoral, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isHi ? 'सत्र समाप्त करें एवं डेटा हटाएं' : 'End Session & Clear Data',
                style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHi
                  ? 'क्या आप इस डिवाइस से अपना सारा अस्थायी डेटा हटाना चाहते हैं?'
                  : 'Are you using a shared phone or public device?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paleSage,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHi ? 'तत्काल हटा दी जाने वाली जानकारी:' : 'Data that will be cleared immediately:',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                  ),
                  const SizedBox(height: 6),
                  Text('• ${isHi ? "पात्रता प्रश्नावली के सभी उत्तर" : "Questionnaire answers & income estimates"}', style: AppTextStyles.caption),
                  Text('• ${isHi ? "योजना परिणाम एवं पात्रता स्थिति" : "Scheme eligibility results & breakdown"}', style: AppTextStyles.caption),
                  Text('• ${isHi ? "अस्थायी दस्तावेज चेकलिस्ट" : "Active document checklists"}', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isHi
                  ? 'नोट: आपका खाता एवं स्थायी प्रोफाइल सुरक्षित रहेगा।'
                  : 'Note: Your login account and permanent profile will remain safe.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isHi ? 'रद्द करें' : 'Cancel',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();

              // Clear all temporary data
              context.read<UserProfileProvider>().clearAllAnswers();
              context.read<EligibilityProvider>().clearResults();
              try {
                context.read<UserDocumentProvider>().clear();
              } catch (_) {}
              try {
                context.read<ApplicationProvider>().clearSession();
              } catch (_) {}
              PrivacyService().clearSessionData();
              context.read<AuthProvider>().exitGuestMode();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isHi
                        ? 'सत्र समाप्त: सभी व्यक्तिगत डेटा मेमोरी से सुरक्षित रूप से हटा दिए गए।'
                        : 'Session ended: All personal assessment data wiped from device memory.',
                  ),
                  backgroundColor: AppColors.forestGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );

              // Navigate to AuthGate and completely clear stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isHi ? 'डेटा हटाएं (Clear)' : 'End Session',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

