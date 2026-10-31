import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/screens/schemes_screen.dart';
import 'package:sahay/services/category_service.dart';
import 'package:sahay/services/scheme_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoryService Canonical Authority Tests', () {
    test('contains all 13 canonical categories', () {
      expect(CategoryService.allCategories.length, 13);
      final ids = CategoryService.allCategories.map((c) => c.categoryId).toSet();
      expect(ids.contains('women-child'), isTrue);
      expect(ids.contains('agriculture'), isTrue);
      expect(ids.contains('education'), isTrue);
      expect(ids.contains('employment-skills'), isTrue);
      expect(ids.contains('health'), isTrue);
      expect(ids.contains('housing'), isTrue);
      expect(ids.contains('social-security'), isTrue);
      expect(ids.contains('finance'), isTrue);
      expect(ids.contains('business'), isTrue);
      expect(ids.contains('rural-development'), isTrue);
      expect(ids.contains('utilities'), isTrue);
      expect(ids.contains('food-security'), isTrue);
      expect(ids.contains('tribal-welfare'), isTrue);
    });

    test('normalizes aliases accurately', () {
      expect(CategoryService.normalizeCategory('women'), 'women-child');
      expect(CategoryService.normalizeCategory('women-child'), 'women-child');
      expect(CategoryService.normalizeCategory('Women Welfare'), 'women-child');
      expect(CategoryService.normalizeCategory('employment'), 'employment-skills');
      expect(CategoryService.normalizeCategory('socialWelfare'), 'social-security');
      expect(CategoryService.normalizeCategory('social-security'), 'social-security');
      expect(CategoryService.normalizeCategory('financial'), 'finance');
      expect(CategoryService.normalizeCategory('finance'), 'finance');
      expect(CategoryService.normalizeCategory('farming'), 'agriculture');
    });

    test('matchesCategory matches canonical and alias variants', () {
      expect(CategoryService.matchesCategory('women-child', 'women'), isTrue);
      expect(CategoryService.matchesCategory('women', 'women-child'), isTrue);
      expect(CategoryService.matchesCategory('employment-skills', 'employment'), isTrue);
      expect(CategoryService.matchesCategory('social-security', 'socialWelfare'), isTrue);
      expect(CategoryService.matchesCategory('finance', 'financial'), isTrue);
      expect(CategoryService.matchesCategory('agriculture', 'education'), isFalse);
    });
  });

  group('SchemeProvider & SchemeDataService Category Filtering', () {
    test('filters schemes catalogue by canonical category', () async {
      final dataService = SchemeDataService();
      final allSchemes = await dataService.getCompleteCatalogue();
      expect(allSchemes.isNotEmpty, isTrue);

      final agriSchemes = await dataService.getSchemesByCategory('agriculture');
      expect(agriSchemes.isNotEmpty, isTrue);
      expect(agriSchemes.every((s) => CategoryService.matchesCategory(s.category, 'agriculture')), isTrue);

      final womenSchemes = await dataService.getSchemesByCategory('women');
      expect(womenSchemes.isNotEmpty, isTrue);
      expect(womenSchemes.every((s) => CategoryService.matchesCategory(s.category, 'women-child')), isTrue);
    });

    test('SchemeProvider filterByCategory updates filtered list', () async {
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadFullCatalogue(SchemeDataService());
      expect(schemeProvider.schemes.length, greaterThanOrEqualTo(100));

      schemeProvider.filterByCategory('education');
      expect(schemeProvider.filteredSchemes.isNotEmpty, isTrue);
      expect(schemeProvider.filteredSchemes.every((s) => CategoryService.matchesCategory(s.category, 'education')), isTrue);

      // Reset to all
      schemeProvider.filterByCategory('all');
      expect(schemeProvider.filteredSchemes.length, schemeProvider.schemes.length);
    });
  });

  group('Category UI Navigation & Header Widget Tests', () {
    testWidgets('SchemesScreen renders Category Banner when opened with initialCategory', (tester) async {
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadFullCatalogue(SchemeDataService());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SchemeProvider>.value(value: schemeProvider),
            ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              SahayLocalizationsDelegate(),
            ],
            home: SchemesScreen(initialCategory: 'agriculture'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that category banner is displayed
      expect(find.text('Agriculture & Farming'), findsWidgets);
      expect(find.byIcon(Icons.close_rounded), findsWidgets);
    });
  });
}
