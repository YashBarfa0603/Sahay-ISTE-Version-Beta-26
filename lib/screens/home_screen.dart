import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/questionnaire_screen.dart';
import 'package:sahay/screens/results_screen.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/screens/schemes_screen.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:sahay/widgets/voice_input_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schemeProvider = context.read<SchemeProvider>();
      if (schemeProvider.schemes.isEmpty && !schemeProvider.isLoading) {
        schemeProvider.loadSchemes(SchemeDataService());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleVoiceResult(String text) {
    if (text.trim().isNotEmpty) {
      _searchController.text = text;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SchemesScreen(initialQuery: text.trim()),
        ),
      );
    }
  }

  void _navigateToCategory(String categoryKey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchemesScreen(initialCategory: categoryKey),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex) return;

    if (index == 0) {
      setState(() => _currentNavIndex = 0);
    } else if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SchemesScreen()),
      );
    } else if (index == 2) {
      final eligibility = context.read<EligibilityProvider>();
      if (eligibility.hasEvaluated && eligibility.results.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
        );
      }
    } else if (index == 3) {
      _showProfileSheet(context);
    }
  }

  void _showProfileSheet(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final userProfile = context.read<UserProfileProvider>();
    final answers = userProfile.answers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.warmIvory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.indianTeal,
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            answers['fullName']?.toString() ?? 'Citizen User',
                            style: AppTextStyles.heading3,
                          ),
                          Text(
                            'Session-only Profile (No cloud tracking)',
                            style: AppTextStyles.caption.copyWith(color: AppColors.forestGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'Profile Details Answered: ${answers.length}',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: answers.entries.map((e) {
                    return Chip(
                      backgroundColor: AppColors.paleSage,
                      label: Text('${e.key}: ${e.value}', style: AppTextStyles.caption),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      userProfile.clearAllAnswers();
                      context.read<EligibilityProvider>().clearResults();
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.dataCleared),
                          backgroundColor: AppColors.deepNavy,
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.mutedCoral),
                    label: Text(
                      l10n.clearData,
                      style: AppTextStyles.label.copyWith(color: AppColors.mutedCoral),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.mutedCoral),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.languageCode;
    final schemeProvider = context.watch<SchemeProvider>();

    // Localized greeting
    final greeting = currentLang == 'hi'
        ? 'नमस्ते!'
        : (currentLang == 'ta'
            ? 'வணக்கம்!'
            : (currentLang == 'mr'
                ? 'नमस्कार!'
                : (currentLang == 'bn'
                    ? 'নমস্কার!'
                    : (currentLang == 'gu'
                        ? 'નમસ્તે!'
                        : (currentLang == 'kn'
                            ? 'ನಮಸ್ಕಾರ!'
                            : (currentLang == 'or' ? 'ନମସ୍କାର!' : 'Hello!'))))));

    final categories = [
      {
        'key': 'agriculture',
        'title': l10n.agriculture,
        'icon': '🌾',
        'color': AppColors.forestGreen,
      },
      {
        'key': 'health',
        'title': l10n.health,
        'icon': '🏥',
        'color': AppColors.mutedCoral,
      },
      {
        'key': 'housing',
        'title': l10n.housing,
        'icon': '🏠',
        'color': AppColors.mutedAmber,
      },
      {
        'key': 'education',
        'title': l10n.education,
        'icon': '📚',
        'color': AppColors.steelBlue,
      },
      {
        'key': 'women',
        'title': l10n.women,
        'icon': '👩',
        'color': AppColors.mutedPurple,
      },
      {
        'key': 'employment',
        'title': l10n.employment,
        'icon': '💼',
        'color': AppColors.deepNavy,
      },
      {
        'key': 'socialWelfare',
        'title': l10n.socialWelfare,
        'icon': '🤝',
        'color': AppColors.indianTeal,
      },
      {
        'key': 'financial',
        'title': l10n.financial,
        'icon': '💰',
        'color': AppColors.softSaffron,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: 'SAHAY (सहाय)',
        showBackButton: false,
        showLanguageToggle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and Subheader
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 26,
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentLang == 'hi'
                          ? 'आज आपके लिए कौन सी योजना सहायक है?'
                          : 'Discover eligible welfare schemes crafted for you',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.deepNavy.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search Bar with Voice Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.paleSage,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.indianTeal.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.0),
                        child: Icon(
                          Icons.search_rounded,
                          color: AppColors.deepNavy,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (query) {
                            if (query.trim().isNotEmpty) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SchemesScreen(initialQuery: query.trim()),
                                ),
                              );
                            }
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: l10n.searchHint.isNotEmpty && l10n.searchHint != 'searchHint'
                                ? l10n.searchHint
                                : (currentLang == 'hi'
                                    ? 'योजनाएं खोजें (उदा. किसान, आवास)...'
                                    : 'Search schemes (e.g. Kisan, Awas)...'),
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.deepNavy.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      // Voice Input Button integrated in the search bar
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: VoiceInputButton(
                            size: 40,
                            showLabel: false,
                            onResult: _handleVoiceResult,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Prominent "Check Your Eligibility" CTA Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.indianTeal, Color(0xFF1B6A63)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indianTeal.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentLang == 'hi' ? 'पात्रता जांचें' : 'Check Your Eligibility',
                              style: AppTextStyles.heading2.copyWith(
                                color: Colors.white,
                                fontSize: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentLang == 'hi'
                          ? 'कुछ सरल प्रश्नों के उत्तर दें और जानें कि आप किन-किन सरकारी योजनाओं के लिए पात्र हैं।'
                          : 'Answer a few simple questions to instantly find schemes customized to your profile.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const QuestionnaireScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.softSaffron,
                            foregroundColor: AppColors.deepNavy,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.checkEligibilityNow.isNotEmpty && l10n.checkEligibilityNow != 'checkEligibilityNow'
                                    ? l10n.checkEligibilityNow
                                    : (currentLang == 'hi' ? 'अभी पात्रता जांचें' : 'Check Eligibility Now'),
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.deepNavy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.deepNavy,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Popular Schemes Horizontal Carousel
              if (schemeProvider.popularSchemes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentLang == 'hi' ? 'लोकप्रिय योजनाएं' : 'Popular Schemes',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SchemesScreen()),
                          );
                        },
                        child: Text(
                          l10n.seeAll.isNotEmpty && l10n.seeAll != 'seeAll' ? l10n.seeAll : 'See All',
                          style: AppTextStyles.label.copyWith(color: AppColors.indianTeal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 175,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: schemeProvider.popularSchemes.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final scheme = schemeProvider.popularSchemes[index];
                      final isCentral = scheme.governmentLevel == GovernmentLevel.central;

                      return _PopularSchemeCard(
                        scheme: scheme,
                        isCentral: isCentral,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SchemeDetailScreen(scheme: scheme),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Categories Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  currentLang == 'hi' ? 'श्रेणियां' : 'Explore by Category',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 18,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2-Column Category Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    return _CategoryGridCard(
                      title: item['title'] as String,
                      iconString: item['icon'] as String,
                      accentColor: item['color'] as Color,
                      onTap: () => _navigateToCategory(item['key'] as String),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.deepNavy,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: _onBottomNavTapped,
          backgroundColor: AppColors.deepNavy,
          selectedItemColor: AppColors.softSaffron,
          unselectedItemColor: AppColors.warmIvory.withValues(alpha: 0.6),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTextStyles.caption,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n.home.isNotEmpty && l10n.home != 'home' ? l10n.home : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_rounded),
              label: l10n.schemes.isNotEmpty && l10n.schemes != 'schemes' ? l10n.schemes : 'Schemes',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.checklist_rounded),
              label: l10n.eligibility.isNotEmpty && l10n.eligibility != 'eligibility' ? l10n.eligibility : 'Eligibility',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: l10n.profile.isNotEmpty && l10n.profile != 'profile' ? l10n.profile : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularSchemeCard extends StatelessWidget {
  final SchemeModel scheme;
  final bool isCentral;
  final VoidCallback onTap;

  const _PopularSchemeCard({
    required this.scheme,
    required this.isCentral,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warmSand,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCentral
                ? AppColors.softSaffron.withValues(alpha: 0.8)
                : AppColors.indianTeal.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCentral ? AppColors.softSaffron : AppColors.indianTeal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCentral ? 'CENTRAL' : 'STATE',
                    style: AppTextStyles.caption.copyWith(
                      color: isCentral ? AppColors.deepNavy : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.mutedAmber,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scheme.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scheme.ministry,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.deepNavy.withValues(alpha: 0.65),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    scheme.category.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.indianTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.indianTeal,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final String title;
  final String iconString;
  final Color accentColor;
  final VoidCallback onTap;

  const _CategoryGridCard({
    required this.title,
    required this.iconString,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmSand,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  iconString,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
