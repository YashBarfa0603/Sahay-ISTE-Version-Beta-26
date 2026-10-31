import 'package:flutter/material.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/services/category_service.dart';
import 'package:sahay/utils/indian_states.dart';

enum RecommendationBadge {
  likelyRelevant,
  mayBeRelevant,
  moreInfoRequired,
}

extension RecommendationBadgeExt on RecommendationBadge {
  String get labelEn {
    switch (this) {
      case RecommendationBadge.likelyRelevant:
        return 'Likely Relevant';
      case RecommendationBadge.mayBeRelevant:
        return 'May Be Relevant';
      case RecommendationBadge.moreInfoRequired:
        return 'More Information Required';
    }
  }

  String get labelHi {
    switch (this) {
      case RecommendationBadge.likelyRelevant:
        return 'अत्यधिक उपयुक्त';
      case RecommendationBadge.mayBeRelevant:
        return 'उपयुक्त हो सकता है';
      case RecommendationBadge.moreInfoRequired:
        return 'अधिक जानकारी आवश्यक';
    }
  }

  Color get color {
    switch (this) {
      case RecommendationBadge.likelyRelevant:
        return AppColors.forestGreen;
      case RecommendationBadge.mayBeRelevant:
        return AppColors.softSaffron;
      case RecommendationBadge.moreInfoRequired:
        return AppColors.steelBlue;
    }
  }

  IconData get icon {
    switch (this) {
      case RecommendationBadge.likelyRelevant:
        return Icons.verified_rounded;
      case RecommendationBadge.mayBeRelevant:
        return Icons.help_outline_rounded;
      case RecommendationBadge.moreInfoRequired:
        return Icons.info_outline_rounded;
    }
  }
}

class SchemeRecommendation {
  final SchemeModel scheme;
  final RecommendationBadge badge;
  final List<String> reasons;
  final List<String> reasonsHindi;
  final double score;

  const SchemeRecommendation({
    required this.scheme,
    required this.badge,
    required this.reasons,
    required this.reasonsHindi,
    required this.score,
  });
}

class RecommendationService {
  const RecommendationService();

  /// Deterministic scheme recommendations for authenticated users based on UserModel
  List<SchemeRecommendation> getRecommendations({
    required UserModel user,
    required List<SchemeModel> allSchemes,
    int maxResults = 8,
  }) {
    final List<SchemeRecommendation> recommendations = [];

    final userStateUpper = user.state?.trim().toUpperCase();
    final userOccupation = user.occupation?.trim().toLowerCase();
    final userGender = user.gender?.trim().toLowerCase();
    final userAge = user.age;
    final userResidence = user.residenceType?.trim().toLowerCase();

    for (final scheme in allSchemes) {
      if (scheme.status == SchemeStatus.inactive) continue;

      // 1. Geographic check
      bool stateMatch = false;
      if (scheme.applicableStates.contains('ALL_INDIA') ||
          scheme.governmentLevel == GovernmentLevel.central) {
        stateMatch = true;
      } else if (userStateUpper != null) {
        stateMatch = scheme.applicableStates.any((s) {
          final sUpper = s.toUpperCase();
          return sUpper == userStateUpper ||
              (IndianStates.findByCode(s)?.nameEnglish.toUpperCase() == userStateUpper);
        });
      }

      // If scheme is state-level and doesn't match user's state, exclude
      if (!stateMatch && scheme.governmentLevel == GovernmentLevel.state && userStateUpper != null) {
        continue;
      }

      double score = 0.0;
      final List<String> reasons = [];
      final List<String> reasonsHi = [];
      bool missingInfo = false;

      // 2. State suitability reason
      if (stateMatch) {
        score += 0.2;
        if (scheme.governmentLevel == GovernmentLevel.state && user.state != null) {
          reasons.add('Exclusive to residents of ${user.state}');
          reasonsHi.add('${user.state} के निवासियों के लिए विशेष योजना');
          score += 0.15;
        } else {
          reasons.add('Applicable across all states in India');
          reasonsHi.add('पूरे भारत में सभी राज्यों के लिए लागू');
        }
      }

      // 3. Occupation matching
      final canonicalCat = CategoryService.normalizeCategory(scheme.category);
      if (userOccupation != null && userOccupation.isNotEmpty) {
        if ((userOccupation == 'farmer' || userOccupation == 'agricultural_worker') &&
            (canonicalCat == 'agriculture' || scheme.name.toLowerCase().contains('kisan') || scheme.description.toLowerCase().contains('farmer'))) {
          score += 0.4;
          reasons.add('Designed for Farmers & Agricultural Beneficiaries');
          reasonsHi.add('किसानों और कृषि से जुड़े लाभार्थियों के लिए तैयार');
        } else if (userOccupation == 'student' &&
            (canonicalCat == 'education' || scheme.name.toLowerCase().contains('scholarship') || scheme.description.toLowerCase().contains('student'))) {
          score += 0.4;
          reasons.add('Education & Scholarship assistance for Students');
          reasonsHi.add('छात्रों के लिए शिक्षा एवं छात्रवृत्ति सहायता');
        } else if ((userOccupation == 'artisan_craftsperson' || userOccupation == 'street_vendor') &&
            (scheme.name.toLowerCase().contains('vishwakarma') || scheme.name.toLowerCase().contains('swanidhi') || canonicalCat == 'finance')) {
          score += 0.4;
          reasons.add('Micro-credit & tools for artisans and informal workers');
          reasonsHi.add('कारीगरों और छोटे व्यापारियों के लिए ऋण एवं उपकरण योजना');
        } else if ((userOccupation == 'small_business_owner' || userOccupation == 'self_employed') &&
            (canonicalCat == 'business' || canonicalCat == 'finance' || scheme.name.toLowerCase().contains('mudra'))) {
          score += 0.35;
          reasons.add('Business credit & entrepreneurship support');
          reasonsHi.add('व्यापार ऋण और उद्यमिता संवर्धन हेतु सहयोग');
        } else if (userOccupation == 'unorganized_worker' &&
            (canonicalCat == 'social-security' || scheme.name.toLowerCase().contains('e-shram') || scheme.name.toLowerCase().contains('yogi'))) {
          score += 0.35;
          reasons.add('Social welfare coverage for informal sector workers');
          reasonsHi.add('असंगठित क्षेत्र के कामगारों के लिए सामाजिक सुरक्षा');
        }
      } else {
        missingInfo = true;
      }

      // 4. Gender suitability
      if (userGender != null && userGender.isNotEmpty) {
        final isFemaleScheme = canonicalCat == 'women-child' ||
            scheme.name.toLowerCase().contains('mahila') ||
            scheme.name.toLowerCase().contains('ladli') ||
            scheme.name.toLowerCase().contains('kanya') ||
            scheme.name.toLowerCase().contains('sukanya') ||
            scheme.name.toLowerCase().contains('matru');

        if (isFemaleScheme) {
          if (userGender == 'female') {
            score += 0.35;
            reasons.add('Targeted empowerment benefit for women');
            reasonsHi.add('महिलाओं के सशक्तिकरण और कल्याण हेतु विशेष योजना');
          } else if (userGender == 'male') {
            // Scheme is exclusively for women, male is not the target
            continue;
          }
        }
      } else {
        missingInfo = true;
      }

      // 5. Age suitability
      if (userAge != null) {
        if (userAge >= 60 && (canonicalCat == 'social-security' || scheme.name.toLowerCase().contains('vridha') || scheme.name.toLowerCase().contains('pension'))) {
          score += 0.35;
          reasons.add('Old-age security pension for senior citizens');
          reasonsHi.add('वरिष्ठ नागरिकों के लिए वृद्धावस्था पेंशन');
        } else if (userAge <= 25 && canonicalCat == 'education') {
          score += 0.2;
          reasons.add('Eligible age bracket for education support');
          reasonsHi.add('शिक्षा सहायता के लिए उपयुक्त आयु वर्ग');
        }
      } else {
        missingInfo = true;
      }

      // 6. Residence type suitability (rural / urban)
      if (userResidence != null && userResidence.isNotEmpty) {
        if (userResidence == 'rural' &&
            (canonicalCat == 'rural-development' || scheme.name.toLowerCase().contains('gramin') || scheme.name.toLowerCase().contains('mgnrega'))) {
          score += 0.25;
          reasons.add('Designed for rural development and households');
          reasonsHi.add('ग्रामीण परिवारों और आजीविका के लिए उपयुक्त');
        } else if (userResidence == 'urban' &&
            (scheme.name.toLowerCase().contains('urban') || scheme.name.toLowerCase().contains('shehari'))) {
          score += 0.25;
          reasons.add('Urban municipal welfare initiative');
          reasonsHi.add('शहरी नागरिकों के लिए कल्याणकारी योजना');
        }
      }

      // 7. General high-impact baseline (Food security, Universal Healthcare)
      if (canonicalCat == 'health' && (scheme.name.toLowerCase().contains('ayushman') || scheme.name.toLowerCase().contains('arogyasri'))) {
        score += 0.3;
        reasons.add('Cashless hospital treatment and health coverage');
        reasonsHi.add('कैशलेस अस्पताल उपचार और स्वास्थ्य सुरक्षा');
      } else if (canonicalCat == 'food-security' || scheme.name.toLowerCase().contains('anna') || scheme.name.toLowerCase().contains('ration')) {
        score += 0.25;
        reasons.add('Essential nutritional and ration food security');
        reasonsHi.add('रियायती राशन एवं अनिवार्य खाद्य सुरक्षा');
      }

      // Determine Badge
      RecommendationBadge badge;
      if (score >= 0.6) {
        badge = RecommendationBadge.likelyRelevant;
      } else if (score >= 0.35) {
        badge = RecommendationBadge.mayBeRelevant;
      } else if (missingInfo) {
        badge = RecommendationBadge.moreInfoRequired;
        if (reasons.isEmpty) {
          reasons.add('Complete your age or occupation to confirm full criteria');
          reasonsHi.add('पूर्ण पात्रता की पुष्टि के लिए आयु व व्यवसाय दर्ज करें');
        }
      } else {
        badge = RecommendationBadge.mayBeRelevant;
      }

      // Ensure reasons are not empty
      if (reasons.isEmpty) {
        reasons.add('General public welfare initiative');
        reasonsHi.add('सार्वजनिक कल्याणकारी पहल');
      }

      recommendations.add(
        SchemeRecommendation(
          scheme: scheme,
          badge: badge,
          reasons: reasons,
          reasonsHindi: reasonsHi,
          score: score,
        ),
      );
    }

    // Sort by score descending
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    return recommendations.take(maxResults).toList();
  }
}

