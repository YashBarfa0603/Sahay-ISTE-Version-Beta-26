import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/services/youtube_tutorial_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummySchemeWithTutorial = SchemeModel(
    schemeId: 'PM_KISAN_001',
    name: 'PM-KISAN Samman Nidhi',
    description: 'Direct income support of ₹6,000 annually to all landholding farmer families.',
    category: 'agriculture',
    ministry: 'Ministry of Agriculture',
    governmentLevel: GovernmentLevel.central,
    applicableStates: const ['ALL_INDIA'],
    benefits: '₹6,000 annually',
    eligibilityRules: const [],
    requiredDocuments: const ['aadhaar_card', 'bank_passbook'],
    applicationProcess: 'Online on pmkisan.gov.in',
    applicationUrl: 'https://pmkisan.gov.in',
    officialSourceUrl: 'https://pmkisan.gov.in',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final dummySchemeWithoutTutorial = SchemeModel(
    schemeId: 'unmapped_state_scheme_xyz',
    name: 'Sample Unmapped State Scheme',
    description: 'Housing grant for eligible beneficiaries.',
    category: 'housing',
    ministry: 'State Welfare Dept',
    governmentLevel: GovernmentLevel.state,
    applicableStates: const ['MP'],
    benefits: 'Housing subsidy',
    eligibilityRules: const [],
    requiredDocuments: const ['aadhaar_card'],
    applicationProcess: 'Visit local municipality',
    officialSourceUrl: 'https://mp.gov.in',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('Feature 4: YouTubeTutorialService Tests', () {
    test('returns verified tutorial model with new URLs and video IDs for all 8 schemes', () {
      // 1. PM-KISAN
      final kisanShort = YouTubeTutorialService.getTutorialForScheme('pm_kisan');
      final kisanCanonical = YouTubeTutorialService.getTutorialForScheme('PM_KISAN_001');
      expect(kisanShort, isNotNull);
      expect(kisanCanonical, isNotNull);
      expect(kisanCanonical!.videoId, 'yeINeVgyg9k');
      expect(kisanCanonical.youtubeUrl, contains('yeINeVgyg9k'));

      // 2. Ayushman Card (PM-JAY)
      final ayushman = YouTubeTutorialService.getTutorialForScheme('AYUSHMAN_001');
      final pmjay = YouTubeTutorialService.getTutorialForScheme('pm_jay');
      expect(ayushman, isNotNull);
      expect(pmjay, isNotNull);
      expect(ayushman!.videoId, 'seOr_0myl2k');
      expect(ayushman.youtubeUrl, contains('seOr_0myl2k'));

      // 3. Pradhan Mantri Awas Yojana
      final pmay1 = YouTubeTutorialService.getTutorialForScheme('PMAY_001');
      final pmay2 = YouTubeTutorialService.getTutorialForScheme('PMAY_002');
      final pmayG = YouTubeTutorialService.getTutorialForScheme('pmay_g');
      expect(pmay1, isNotNull);
      expect(pmay2, isNotNull);
      expect(pmayG, isNotNull);
      expect(pmay1!.videoId, 'iCtKY2qTUQ8');
      expect(pmay1.youtubeUrl, contains('iCtKY2qTUQ8'));

      // 4. PM Ujjwala Yojana
      final ujjwalaCanonical = YouTubeTutorialService.getTutorialForScheme('PM_UJJWALA_001');
      final ujjwalaShort = YouTubeTutorialService.getTutorialForScheme('pm_ujjwala');
      expect(ujjwalaCanonical, isNotNull);
      expect(ujjwalaShort, isNotNull);
      expect(ujjwalaCanonical!.videoId, 'gUTd57fTW6U');
      expect(ujjwalaCanonical.youtubeUrl, contains('gUTd57fTW6U'));

      // 5. Ladli Behna Yojana
      final ladliCanonical = YouTubeTutorialService.getTutorialForScheme('MP_LADLI_BEHNA_001');
      final ladliShort = YouTubeTutorialService.getTutorialForScheme('ladli_behna');
      expect(ladliCanonical, isNotNull);
      expect(ladliShort, isNotNull);
      expect(ladliCanonical!.videoId, 'tOZ2VLMuiLY');
      expect(ladliCanonical.youtubeUrl, contains('tOZ2VLMuiLY'));

      // 6. PM SVANidhi
      final svanidhiCanonical = YouTubeTutorialService.getTutorialForScheme('PM_SVANIDHI_001');
      final svanidhiShort = YouTubeTutorialService.getTutorialForScheme('pm_svanidhi');
      expect(svanidhiCanonical, isNotNull);
      expect(svanidhiShort, isNotNull);
      expect(svanidhiCanonical!.videoId, 'iO7Y-bCgon0');
      expect(svanidhiCanonical.youtubeUrl, contains('iO7Y-bCgon0'));

      // 7. Sukanya Samriddhi Yojana
      final sukanyaCanonical = YouTubeTutorialService.getTutorialForScheme('SUKANYA_SAMRIDDHI_001');
      final sukanyaShort = YouTubeTutorialService.getTutorialForScheme('sukanya_samriddhi');
      expect(sukanyaCanonical, isNotNull);
      expect(sukanyaShort, isNotNull);
      expect(sukanyaCanonical!.videoId, 'bXwcnF-nn_M');
      expect(sukanyaCanonical.youtubeUrl, contains('bXwcnF-nn_M'));

      // 8. PM Vishwakarma
      final vishwakarmaCanonical = YouTubeTutorialService.getTutorialForScheme('PM_VISHWAKARMA_001');
      final vishwakarmaShort = YouTubeTutorialService.getTutorialForScheme('pm_vishwakarma');
      expect(vishwakarmaCanonical, isNotNull);
      expect(vishwakarmaShort, isNotNull);
      expect(vishwakarmaCanonical!.videoId, 'S5uwhpLisXQ');
      expect(vishwakarmaCanonical.youtubeUrl, contains('S5uwhpLisXQ'));
    });

    test('returns null for unmapped schemes', () {
      final tutorial = YouTubeTutorialService.getTutorialForScheme('unmapped_scheme_999');
      expect(tutorial, isNull);
    });
  });

  group('Feature 4: SchemeDetailScreen How-To-Apply YouTube Integration Widget Tests', () {
    testWidgets('renders Video Tutorial card when verified tutorial exists (canonical ID)', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
            ChangeNotifierProvider<EligibilityProvider>(create: (_) => EligibilityProvider()),
            ChangeNotifierProvider<UserDocumentProvider>(create: (_) => UserDocumentProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              SahayLocalizationsDelegate(),
            ],
            home: SchemeDetailScreen(scheme: dummySchemeWithTutorial),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to "How to Apply" tab (3rd tab)
      await tester.tap(find.text('How to Apply'));
      await tester.pumpAndSettle();

      // Check YouTube Tutorial Card elements
      expect(find.text('Video Tutorial — How to Apply'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.text('Watch Step-by-Step on YouTube'), findsOneWidget);
    });

    testWidgets('renders fallback notice when no tutorial is available', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
            ChangeNotifierProvider<EligibilityProvider>(create: (_) => EligibilityProvider()),
            ChangeNotifierProvider<UserDocumentProvider>(create: (_) => UserDocumentProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              SahayLocalizationsDelegate(),
            ],
            home: SchemeDetailScreen(scheme: dummySchemeWithoutTutorial),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to "How to Apply" tab (3rd tab)
      await tester.tap(find.text('How to Apply'));
      await tester.pumpAndSettle();

      // Check Fallback notice
      expect(
        find.text('No verified application tutorial is currently available for this scheme.'),
        findsOneWidget,
      );
    });
  });
}
