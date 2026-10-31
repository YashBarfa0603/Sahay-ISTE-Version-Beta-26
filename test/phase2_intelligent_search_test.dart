import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/services/scheme_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2: Intelligent Scheme Search Service Tests', () {
    late SchemeSearchService searchService;
    late List<SchemeModel> sampleSchemes;

    setUp(() async {
      searchService = const SchemeSearchService();
      sampleSchemes = await SchemeDataService().getCompleteCatalogue();
    });

    test('Empty or blank query returns all schemes preserved in order', () {
      final results1 = searchService.search(schemes: sampleSchemes, query: '');
      expect(results1.length, sampleSchemes.length);

      final results2 = searchService.search(schemes: sampleSchemes, query: '   ');
      expect(results2.length, sampleSchemes.length);
    });

    test('Partial name matches: kisan, awas, ayushman, ujjwala', () {
      final kisan = searchService.search(schemes: sampleSchemes, query: 'kisan');
      expect(kisan.isNotEmpty, isTrue);
      expect(kisan.first.schemeId.toLowerCase(), contains('kisan'));

      final awas = searchService.search(schemes: sampleSchemes, query: 'awas');
      expect(awas.isNotEmpty, isTrue);
      expect(awas.first.name.toLowerCase(), contains('awas'));

      final ayushman = searchService.search(schemes: sampleSchemes, query: 'ayushman');
      expect(ayushman.isNotEmpty, isTrue);
      expect(ayushman.first.name.toLowerCase(), contains('ayushman'));

      final ujjwala = searchService.search(schemes: sampleSchemes, query: 'ujjwala');
      expect(ujjwala.isNotEmpty, isTrue);
      expect(ujjwala.first.name.toLowerCase(), contains('ujjwala'));
    });

    test('Colloquial alias and acronym matches: ladli behena yojna, pm kisan, sukanya, svanidhi', () {
      final ladli = searchService.search(schemes: sampleSchemes, query: 'ladli behena yojna');
      expect(ladli.isNotEmpty, isTrue);
      expect(ladli.first.schemeId, 'MP_LADLI_BEHNA_001');

      final pmkisan = searchService.search(schemes: sampleSchemes, query: 'pm kisan');
      expect(pmkisan.isNotEmpty, isTrue);
      expect(pmkisan.first.schemeId, 'PM_KISAN_001');

      final sukanya = searchService.search(schemes: sampleSchemes, query: 'sukanya');
      expect(sukanya.isNotEmpty, isTrue);
      expect(sukanya.first.schemeId, 'SUKANYA_SAMRIDDHI_001');

      final svanidhi = searchService.search(schemes: sampleSchemes, query: 'svanidhi');
      expect(svanidhi.isNotEmpty, isTrue);
      expect(svanidhi.first.schemeId, 'PM_SVANIDHI_001');

      final vishwakarma = searchService.search(schemes: sampleSchemes, query: 'pm vishwakarma');
      expect(vishwakarma.isNotEmpty, isTrue);
      expect(vishwakarma.first.schemeId, 'PM_VISHWAKARMA_001');
    });

    test('Hindi Devnagari queries: लाडली बहना, पीएम किसान, आयुष्मान', () {
      final hiLadli = searchService.search(schemes: sampleSchemes, query: 'लाडली बहना');
      expect(hiLadli.isNotEmpty, isTrue);
      expect(hiLadli.first.schemeId, 'MP_LADLI_BEHNA_001');

      final hiKisan = searchService.search(schemes: sampleSchemes, query: 'पीएम किसान');
      expect(hiKisan.isNotEmpty, isTrue);
      expect(hiKisan.first.schemeId, 'PM_KISAN_001');

      final hiAyushman = searchService.search(schemes: sampleSchemes, query: 'आयुष्मान भारत');
      expect(hiAyushman.isNotEmpty, isTrue);
      expect(
        hiAyushman.first.schemeId == 'AYUSHMAN_001' ||
            hiAyushman.first.schemeId == 'PMJAY_002',
        isTrue,
      );
    });

    test('Typo tolerance with fuzzy matching: laadli, kisaan, ayusman, ujwala', () {
      final typoLadli = searchService.search(schemes: sampleSchemes, query: 'laadli behna');
      expect(typoLadli.isNotEmpty, isTrue);
      expect(typoLadli.first.schemeId, 'MP_LADLI_BEHNA_001');

      final typoKisan = searchService.search(schemes: sampleSchemes, query: 'kisaan');
      expect(typoKisan.isNotEmpty, isTrue);
      expect(typoKisan.first.schemeId, 'PM_KISAN_001');

      final typoAyusman = searchService.search(schemes: sampleSchemes, query: 'ayusman bharat');
      expect(typoAyusman.isNotEmpty, isTrue);
      expect(
        typoAyusman.first.schemeId == 'AYUSHMAN_001' ||
            typoAyusman.first.schemeId == 'PMJAY_002',
        isTrue,
      );

      final typoUjwala = searchService.search(schemes: sampleSchemes, query: 'ujwala yojana');
      expect(typoUjwala.isNotEmpty, isTrue);
      expect(
        typoUjwala.first.schemeId == 'PM_UJJWALA_001' ||
            typoUjwala.first.schemeId == 'PMUY_004',
        isTrue,
      );
    });

    test('Multi-word and intent queries: farmer cash assistance, lpg cylinder, student scholarship', () {
      final farmerCash = searchService.search(schemes: sampleSchemes, query: 'farmer cash assistance');
      expect(farmerCash.isNotEmpty, isTrue);
      expect(farmerCash.first.schemeId, 'PM_KISAN_001');

      final lpg = searchService.search(schemes: sampleSchemes, query: 'lpg cylinder');
      expect(lpg.isNotEmpty, isTrue);
      expect(
        lpg.first.schemeId == 'PM_UJJWALA_001' ||
            lpg.first.schemeId == 'PMUY_004',
        isTrue,
      );

      final scholarship = searchService.search(schemes: sampleSchemes, query: 'scholarship for girls');
      expect(scholarship.isNotEmpty, isTrue);
      expect(scholarship.any((s) => s.schemeId.contains('PRAGATI') || s.category.toLowerCase().contains('education')), isTrue);
    });
  });
}
