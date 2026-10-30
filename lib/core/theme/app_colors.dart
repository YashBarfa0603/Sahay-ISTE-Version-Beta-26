import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core
  static const Color warmIvory = Color(0xFFF7F5EF);
  static const Color deepNavy = Color(0xFF19344D);
  static const Color indianTeal = Color(0xFF258C83);
  static const Color softSaffron = Color(0xFFE3B66B);
  static const Color paleSage = Color(0xFFE8F1EC);
  static const Color warmSand = Color(0xFFF3E9DF);

  // Status
  static const Color forestGreen = Color(0xFF287A55);
  static const Color mutedAmber = Color(0xFFB77924);
  static const Color steelBlue = Color(0xFF426D9B);
  static const Color mutedCoral = Color(0xFFB84C4C);
  static const Color mutedPurple = Color(0xFF78649B);

  // Semantic
  static const Color primary = indianTeal;
  static const Color primaryLight = Color(0xFF38A89D);
  static const Color primaryDark = Color(0xFF1B6A63);

  static const Color secondary = softSaffron;
  static const Color secondaryLight = Color(0xFFEDC98C);
  static const Color secondaryDark = Color(0xFFCA9D50);

  static const Color background = warmIvory;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = warmSand;

  static const Color textPrimary = deepNavy;
  static const Color textSecondary = Color(0xFF4A6277);
  static const Color textMuted = Color(0xFF7E92A2);
  static const Color textLight = warmIvory;

  static const Color border = Color(0xFFDCD6CA);
  static const Color borderLight = Color(0xFFEBE6DC);
  static const Color divider = Color(0xFFE2DDD3);

  static const Color success = forestGreen;
  static const Color warning = mutedAmber;
  static const Color error = mutedCoral;
  static const Color info = steelBlue;

  // Eligibility
  static const Color eligibleGreen = forestGreen;
  static const Color borderlineOrange = mutedAmber;
  static const Color ineligibleRed = mutedCoral;
  static const Color needsInfoBlue = steelBlue;

  // Shimmer
  static const Color shimmerBase = Color(0xFFE8E4DA);
  static const Color shimmerHighlight = Color(0xFFF7F5EF);

  // Status helper
  static Color forStatus(String status) {
    switch (status.toLowerCase()) {
      case 'eligible':
      case 'mayqualify':
      case 'passed':
      case 'verified':
      case 'active':
        return forestGreen;
      case 'needsmoreinfo':
      case 'needsmoreinformation':
      case 'pending':
      case 'partiallyeligible':
      case 'underverification':
        return mutedAmber;
      case 'noteligible':
      case 'doesnotqualify':
      case 'failed':
      case 'rejected':
      case 'inactive':
        return mutedCoral;
      default:
        return steelBlue;
    }
  }
}
