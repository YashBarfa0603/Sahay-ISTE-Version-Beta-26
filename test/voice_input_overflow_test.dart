import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/widgets/voice_input_button.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {
  UserModel? mockUser;
  _FakeAuthRepo({this.mockUser});

  @override
  Stream<UserModel?> get currentUserProfileStream => Stream.value(mockUser);
  @override
  Future<UserModel?> getCurrentUser() async => mockUser;
  @override
  Future<void> signOut() async {
    mockUser = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugin.csd.speech_to_text'),
      (methodCall) async {
        if (methodCall.method == 'initialize') return true;
        if (methodCall.method == 'listen') return true;
        if (methodCall.method == 'stop') return true;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (methodCall) async => 1,
    );
  });

  Widget buildApp(Widget child, {required AuthProvider authProvider, SchemeProvider? schemeProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: schemeProvider ?? SchemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => EligibilityProvider()),
        ChangeNotifierProvider(create: (_) => UserDocumentProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          SahayLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: SahayLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('VoiceInputButton Mic Tap & Listening Pulse Overflow Verification', () {
    testWidgets('Guest HomeScreen: Clicking mic does not throw RenderFlex overflow', (tester) async {
      final auth = AuthProvider();
      auth.enterGuestMode();

      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(const SchemeDataService());

      await tester.pumpWidget(
        buildApp(const HomeScreen(), authProvider: auth, schemeProvider: schemeProvider),
      );
      await tester.pumpAndSettle();

      final micFinder = find.byType(VoiceInputButton);
      expect(micFinder, findsOneWidget);

      // Tap the mic button
      await tester.tap(micFinder);
      await tester.pump();

      // Pump through several animation frames of the listening ripple/scale
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Authenticated HomeScreen: Clicking mic does not throw RenderFlex overflow', (tester) async {
      final user = UserModel(
        uid: 'test_user_1',
        fullName: 'Aarav Sharma',
        mobileNumber: '9876543210',
        email: 'aarav@example.com',
        createdAt: DateTime.now(),
        profileComplete: true,
      );
      final authRepo = _FakeAuthRepo(mockUser: user);
      final auth = AuthProvider(authRepository: authRepo);
      await tester.pump(const Duration(milliseconds: 50));

      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(const SchemeDataService());

      await tester.pumpWidget(
        buildApp(const HomeScreen(), authProvider: auth, schemeProvider: schemeProvider),
      );
      await tester.pumpAndSettle();

      final micFinder = find.byType(VoiceInputButton);
      expect(micFinder, findsOneWidget);

      await tester.tap(micFinder);
      await tester.pump();

      // Advance animation through peak scale and ripple
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('VoiceInputButton within tight 44x44 constraints never overflows during listening', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: VoiceInputButton(
                  size: 40,
                  showLabel: false,
                  onResult: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final micFinder = find.byType(VoiceInputButton);
      await tester.tap(micFinder);
      await tester.pump();

      // Pump 15 frames of listening animation
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
