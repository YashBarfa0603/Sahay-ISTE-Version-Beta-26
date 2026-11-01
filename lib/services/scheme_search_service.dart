import 'dart:math';
import 'package:sahay/models/scheme_model.dart';

/// Intelligent multi-layered scheme search service.
/// Supports exact matching, token-based partial matching, common aliases/acronyms,
/// Hinglish/transliterated variations, typo/fuzzy matching, and semantic tags.
class SchemeSearchService {
  const SchemeSearchService();

  /// Curated aliases mapping common citizen queries and colloquial names to scheme keywords
  static final Map<String, List<String>> _schemeAliases = {
    'pm-kisan': [
      'pm kisan',
      'pm-kisan',
      'pmkisan',
      'kisan samman',
      'kisan samman nidhi',
      'pm kisan samman nidhi',
      'kisan',
      'kisan yojana',
      'pm kisaan',
      'kisaan',
      'पीएम किसान',
      'किसान सम्मान',
      'किसान सम्मान निधि',
    ],
    'pm_kisan_001': [
      'pm kisan',
      'pm-kisan',
      'pmkisan',
      'kisan samman',
      'kisan samman nidhi',
      'pm kisan samman nidhi',
      'kisan',
      'kisan yojana',
      'pm kisaan',
      'kisaan',
      'farmer cash assistance',
      'farmer income support',
      '6000 per year',
      'किसान सहायता',
      'पीएम किसान',
      'किसान सम्मान',
      'किसान सम्मान निधि',
    ],
    'ayushman_001': [
      'ayushman',
      'ayushman bharat',
      'pm-jay',
      'pmjay',
      'ab-pmjay',
      'pm jay',
      'ayushman card',
      'ayushman yojana',
      'ayushman bhrat',
      'golden card',
      'health insurance',
      'आयुष्मान भारत',
      'आयुष्मान कार्ड',
      'जन आरोग्य योजना',
    ],
    'pm-jay': [
      'ayushman',
      'ayushman bharat',
      'pm-jay',
      'pmjay',
      'ab-pmjay',
      'pm jay',
      'ayushman card',
      'ayushman yojana',
      'ayushman bhrat',
      'golden card',
      'आयुष्मान भारत',
      'आयुष्मान कार्ड',
      'जन आरोग्य योजना',
    ],
    'pmay-g': [
      'pm awas',
      'pmay',
      'pmay-g',
      'pmayg',
      'pm awas yojana',
      'awas yojana',
      'pradhan mantri awas',
      'pradhan mantri awas yojana',
      'indira awas',
      'pm awaas',
      'आवास योजना',
      'प्रधानमंत्री आवास',
      'प्रधानमंत्री आवास योजना',
    ],
    'pmay_001': [
      'pm awas',
      'pmay',
      'pmay-g',
      'pmayg',
      'pm awas yojana',
      'awas yojana',
      'pradhan mantri awas',
      'pradhan mantri awas yojana',
      'indira awas',
      'pm awaas',
      'आवास योजना',
      'प्रधानमंत्री आवास',
      'प्रधानमंत्री आवास योजना',
    ],
    'pmay_002': [
      'pm awas',
      'pmay',
      'pmay-u',
      'pmayu',
      'pm awas yojana urban',
      'awas yojana',
      'pradhan mantri awas',
      'आवास योजना',
    ],
    'ujjwala-2': [
      'ujjwala',
      'pm ujjwala',
      'pmuy',
      'ujjwala yojana',
      'ujwala',
      'ujwala yojana',
      'gas cylinder',
      'free gas',
      'lpg yojana',
      'उज्ज्वला',
      'उज्ज्वला योजना',
      'गैस कनेक्शन',
    ],
    'pm_ujjwala_001': [
      'ujjwala',
      'pm ujjwala',
      'pmuy',
      'ujjwala yojana',
      'ujwala',
      'ujwala yojana',
      'gas cylinder',
      'free gas',
      'lpg yojana',
      'उज्ज्वला',
      'उज्ज्वला योजना',
      'गैस कनेक्शन',
    ],
    'ladli-behna-mp': [
      'ladli behna',
      'ladli behena',
      'ladli bahna',
      'ladli',
      'ladli yojna',
      'ladli yojana',
      'ladli behena yojna',
      'mukhyamantri ladli behna',
      'mukhyamantri ladli behna yojana',
      'लाडली बहना',
      'लाडली बहना योजना',
      'लाड़ली बहना',
    ],
    'mp_ladli_behna_001': [
      'ladli behna',
      'ladli behena',
      'ladli bahna',
      'ladli',
      'ladli yojna',
      'ladli yojana',
      'ladli behena yojna',
      'mukhyamantri ladli behna',
      'mukhyamantri ladli behna yojana',
      'लाडली बहना',
      'लाडली बहना योजना',
      'लाड़ली बहना',
    ],
    'pm-scholarship': [
      'student scholarship',
      'pm scholarship',
      'scholarship',
      'education scholarship',
      'छात्रवृत्ति',
      'स्कॉलरशिप',
      'विद्यार्थी छात्रवृत्ति',
    ],
    'cs_scholarship_college_university_001': [
      'student scholarship',
      'college scholarship',
      'university scholarship',
      'higher education scholarship',
      'scholarship',
      'छात्रवृत्ति',
      'स्कॉलरशिप',
    ],
    'mp_post_matric_scholarship_sc_st_001': [
      'student scholarship',
      'post matric scholarship',
      'mp scholarship',
      'scholarship',
      'छात्रवृत्ति',
      'स्कॉलरशिप',
    ],
    'pre_matric_scholarship_minorities_001': [
      'student scholarship',
      'pre matric scholarship',
      'minority scholarship',
      'scholarship',
      'छात्रवृत्ति',
      'स्कॉलरशिप',
    ],
    'pm_svanidhi_001': [
      'pm svanidhi',
      'svanidhi',
      'swanidhi',
      'street vendor loan',
      'vendor scheme',
      'स्वनिधि',
      'रेहड़ी पटरी',
      'स्ट्रीट वेंडर',
    ],
    'pm_vishwakarma_001': [
      'pm vishwakarma',
      'vishwakarma',
      'vishwakarma yojana',
      'artisan scheme',
      'craftsman loan',
      'विश्वकर्मा',
      'विश्वकर्मा योजना',
    ],
    'sukanya_samriddhi_001': [
      'sukanya samriddhi',
      'sukanya',
      'ssy',
      'sukanya yojana',
      'girl child scheme',
      'सुकन्या समृद्धि',
      'सुकन्या समृद्धि योजना',
    ],
  };

  /// Normalizes input string by trimming, lowercasing, collapsing whitespace,
  /// and stripping punctuation.
  static String normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\-_/\\,;:!?.()\[\]{}"\x27]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculates Levenshtein edit distance between two strings
  static int levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List<int>.generate(b.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        int cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= b.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[b.length];
  }

  /// Calculates normalized string similarity ratio between 0.0 and 1.0
  static double similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    int maxLen = max(s1.length, s2.length);
    int dist = levenshteinDistance(s1, s2);
    return (maxLen - dist) / maxLen;
  }

  /// Core intelligent search method.
  /// Takes a list of candidate schemes and a raw query string.
  /// Returns relevant schemes ranked by semantic, exact, alias, and fuzzy scores.
  List<SchemeModel> search({
    required List<SchemeModel> schemes,
    required String query,
  }) {
    final cleanQuery = normalize(query);
    if (cleanQuery.isEmpty) {
      return List<SchemeModel>.unmodifiable(schemes);
    }

    final queryTokens = cleanQuery
        .split(' ')
        .where((t) => t.trim().isNotEmpty)
        .toList();

    final List<_ScoredScheme> scored = [];

    for (final scheme in schemes) {
      final score = _calculateSchemeScore(scheme, cleanQuery, queryTokens);
      if (score > 0) {
        scored.add(_ScoredScheme(scheme, score));
      }
    }

    // Sort descending by score. Secondary sort by popularity rank or name.
    scored.sort((a, b) {
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }
      final rankA = a.scheme.popularityRank;
      final rankB = b.scheme.popularityRank;
      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }
      return a.scheme.name.compareTo(b.scheme.name);
    });

    return scored.map((s) => s.scheme).toList();
  }

  /// Evaluates scheme match score against search query
  double _calculateSchemeScore(
    SchemeModel scheme,
    String cleanQuery,
    List<String> queryTokens,
  ) {
    double score = 0.0;

    final nameNorm = normalize(scheme.name);
    final nameHindiNorm = normalize(scheme.nameHindi ?? '');
    final descNorm = normalize(scheme.description);
    final ministryNorm = normalize(scheme.ministry);
    final categoryNorm = normalize(scheme.category);
    final benefitsNorm = normalize(scheme.benefits);
    final docTagsNorm = scheme.requiredDocuments.map((t) => normalize(t)).toList();

    // Retrieve curated aliases for this scheme
    final schemeKey = scheme.schemeId.toLowerCase().replaceAll('-', '_');
    final aliases = _schemeAliases[scheme.schemeId.toLowerCase()] ??
        _schemeAliases[schemeKey] ??
        [];
    final normAliases = aliases.map((a) => normalize(a)).toList();

    // ----------------------------------------------------
    // LAYER 1: Exact and Normalized Match (Score: 1000)
    // ----------------------------------------------------
    if (nameNorm == cleanQuery || nameHindiNorm == cleanQuery) {
      return 1000.0;
    }

    // ----------------------------------------------------
    // LAYER 2: Exact Alias / Acronym Match (Score: 850)
    // ----------------------------------------------------
    for (final alias in normAliases) {
      if (alias == cleanQuery) {
        return 850.0;
      }
    }

    // ----------------------------------------------------
    // LAYER 3: Strong Substring & Token Subset Match
    // ----------------------------------------------------
    if (nameNorm.contains(cleanQuery) || nameHindiNorm.contains(cleanQuery)) {
      score = max(score, 650.0);
    }

    for (final alias in normAliases) {
      if (alias.contains(cleanQuery) || cleanQuery.contains(alias)) {
        score = max(score, 600.0);
      }
    }

    // Check if ALL query tokens are present in scheme title or aliases
    final titleTokens = nameNorm.split(' ')..addAll(nameHindiNorm.split(' '));
    for (final alias in normAliases) {
      titleTokens.addAll(alias.split(' '));
    }

    bool matchesToken(String qt, String tt) {
      if (tt == qt) return true;
      if (qt.length >= 3 && tt.length >= 3) {
        return tt.contains(qt) || qt.contains(tt);
      }
      return false;
    }

    bool allTokensInTitle = queryTokens.isNotEmpty &&
        queryTokens.every((qt) => titleTokens.any((tt) => matchesToken(qt, tt)));

    if (allTokensInTitle) {
      score = max(score, 520.0);
    }

    // Individual token matching in titles
    int matchedTokens = 0;
    for (final qt in queryTokens) {
      if (titleTokens.any((tt) => matchesToken(qt, tt))) {
        matchedTokens++;
      }
    }
    if (matchedTokens > 0) {
      score = max(score, 250.0 + (matchedTokens * 40.0));
    }

    // ----------------------------------------------------
    // LAYER 4: Fuzzy Match (Typo-tolerant: ladli behena, ujwala, etc.)
    // ----------------------------------------------------
    for (final qt in queryTokens) {
      // Compare against title tokens and alias tokens
      for (final tt in titleTokens) {
        if (tt.length >= 3 && qt.length >= 3) {
          final sim = similarity(qt, tt);
          if (sim >= 0.72) {
            score = max(score, 260.0 * sim);
          }
        }
      }
      // Also compare query against full aliases
      for (final alias in normAliases) {
        final sim = similarity(cleanQuery, alias);
        if (sim >= 0.70) {
          score = max(score, 450.0 * sim);
        }
      }
    }

    // ----------------------------------------------------
    // LAYER 5: Semantic & Keyword/Beneficiary Fallback
    // ----------------------------------------------------
    for (final docTag in docTagsNorm) {
      if (docTag == cleanQuery || queryTokens.contains(docTag)) {
        score = max(score, 200.0);
      }
    }

    if (descNorm.contains(cleanQuery) || benefitsNorm.contains(cleanQuery)) {
      score = max(score, 180.0);
    }

    if (categoryNorm.contains(cleanQuery) || ministryNorm.contains(cleanQuery)) {
      score = max(score, 160.0);
    }

    for (final qt in queryTokens) {
      if (qt.length >= 3 && (descNorm.contains(qt) || benefitsNorm.contains(qt))) {
        score = max(score, 120.0);
      }
    }

    return score;
  }
}

class _ScoredScheme {
  final SchemeModel scheme;
  final double score;
  const _ScoredScheme(this.scheme, this.score);
}
