import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/screens/sahay_assistance_screen.dart';

class SahayAssistanceFAB extends StatelessWidget {
  final String currentScreen;
  final String? selectedSchemeId;
  final String? selectedSchemeName;
  final bool mini;
  final String? heroTag;

  const SahayAssistanceFAB({
    super.key,
    this.currentScreen = 'home',
    this.selectedSchemeId,
    this.selectedSchemeName,
    this.mini = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().languageCode;
    final isHi = lang.startsWith('hi');
    final tag = heroTag ?? 'sahay_assistance_fab_${currentScreen}_${mini ? "mini" : "ext"}';

    if (mini) {
      return FloatingActionButton.small(
        heroTag: tag,
        backgroundColor: AppColors.softSaffron,
        foregroundColor: AppColors.deepNavy,
        elevation: 4,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SahayAssistanceScreen(
                currentScreen: currentScreen,
                selectedSchemeId: selectedSchemeId,
                selectedSchemeName: selectedSchemeName,
              ),
            ),
          );
        },
        child: const Icon(Icons.support_agent_rounded, size: 20),
      );
    }

    return FloatingActionButton.extended(
      heroTag: tag,
      backgroundColor: AppColors.softSaffron,
      foregroundColor: AppColors.deepNavy,
      elevation: 4,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SahayAssistanceScreen(
              currentScreen: currentScreen,
              selectedSchemeId: selectedSchemeId,
              selectedSchemeName: selectedSchemeName,
            ),
          ),
        );
      },
      icon: const Icon(Icons.support_agent_rounded, size: 20),
      label: Text(
        isHi ? 'सहाय से पूछें' : 'Ask SAHAY',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

