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
    schemeId: 'pm_kisan',
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
    test('returns verified tutorial model for PM-KISAN', () {
      final tutorial = YouTubeTutorialService.getTutorialForScheme('pm_kisan');
      expect(tutorial, isNotNull);
      expect(tutorial!.youtubeUrl.contains('youtube.com'), isTrue);
      expect(tutorial.thumbnailUrl.contains('img.youtube.com'), isTrue);
      expect(tutorial.isVerified, isTrue);
      expect(tutorial.channelName.isNotEmpty, isTrue);
    });

    test('returns verified tutorial model for Ladli Behna', () {
      final tutorial = YouTubeTutorialService.getTutorialForScheme('ladli_behna');
      expect(tutorial, isNotNull);
      expect(tutorial!.videoId, isNotEmpty);
    });

    test('returns null for unmapped schemes', () {
      final tutorial = YouTubeTutorialService.getTutorialForScheme('unmapped_scheme_999');
      expect(tutorial, isNull);
    });
  });

  group('Feature 4: SchemeDetailScreen How-To-Apply YouTube Integration Widget Tests', () {
    testWidgets('renders Video Tutorial card when verified tutorial exists', (tester) async {
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
