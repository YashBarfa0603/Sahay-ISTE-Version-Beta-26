import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_theme.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/services/document_service.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/services/scheme_notes_service.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {
  @override
  Stream<UserModel?> get currentUserProfileStream => const Stream.empty();
  @override
  Future<UserModel?> getCurrentUser() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5 — Scheme Edge Cases & Important Precautions Tests', () {
    test('SchemeNotesService provides specific or grounded notes for all schemes', () async {
      final service = SchemeDataService();
      final catalogue = await service.getCompleteCatalogue();
      expect(catalogue.length, equals(100));

      for (final scheme in catalogue) {
        final notes = SchemeNotesService.getNotesForSchemeOrGrounded(scheme);
        expect(notes.criticalConditions.isNotEmpty, isTrue, reason: 'Failed on ${scheme.schemeId}');
        expect(notes.disqualificationReasons.isNotEmpty, isTrue, reason: 'Failed on ${scheme.schemeId}');
        expect(notes.applicationPrecautions.isNotEmpty, isTrue, reason: 'Failed on ${scheme.schemeId}');
      }
    });

    testWidgets('SchemeDetailScreen renders Edge Cases & Important Precautions section in Overview tab', (tester) async {
      final service = SchemeDataService();
      final schemes = await service.getAllSchemes();
      final kisan = schemes.firstWhere((s) => s.schemeId == 'pm-kisan');

      final authProvider = AuthProvider(authRepository: _FakeAuthRepo());
      authProvider.enterGuestMode();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => SchemeProvider()),
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => EligibilityProvider()),
            ChangeNotifierProvider(create: (_) => UserDocumentProvider(service: DocumentService())),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              SahayLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: SahayLocalizations.supportedLocales,
            home: SchemeDetailScreen(scheme: kisan),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect "Edge Cases & Important Precautions" section header
      expect(find.text('Edge Cases & Important Precautions'), findsOneWidget);

      // Expect subsections within ExpansionTiles
      expect(find.text('Critical Eligibility Conditions'), findsOneWidget);
      expect(find.text('Reasons Leading to Disqualification'), findsOneWidget);
      expect(find.text('Important Document Requirements'), findsOneWidget);
      expect(find.text('Application Precautions'), findsOneWidget);
    });
  });
}
