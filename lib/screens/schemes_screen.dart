import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:sahay/widgets/voice_input_button.dart';

class SchemesScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialQuery;

  const SchemesScreen({
    super.key,
    this.initialCategory,
    this.initialQuery,
  });

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  late final TextEditingController _searchController;
  GovernmentLevel? _selectedLevel;
  String? _selectedCategory;

  final List<String> _categories = [
    'all',
    'agriculture',
    'health',
    'housing',
    'education',
    'women',
    'employment',
    'socialWelfare',
    'financial',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _selectedCategory = widget.initialCategory;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schemeProvider = context.read<SchemeProvider>();
      if (schemeProvider.schemes.isEmpty && !schemeProvider.isLoading) {
        schemeProvider.loadSchemes(SchemeDataService()).then((_) {
          _applyInitialFilters();
        });
      } else {
        _applyInitialFilters();
      }
    });
  }

  void _applyInitialFilters() {
    final schemeProvider = context.read<SchemeProvider>();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      schemeProvider.searchSchemes(widget.initialQuery!);
    }
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      schemeProvider.filterByCategory(widget.initialCategory);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<SchemeProvider>().searchSchemes(query);
  }

  void _onLevelFilterChanged(GovernmentLevel? level) {
    setState(() => _selectedLevel = level);
    context.read<SchemeProvider>().filterByLevel(level);
  }

  void _onCategoryFilterChanged(String category) {
    final target = category == 'all' ? null : category;
    setState(() => _selectedCategory = target);
    context.read<SchemeProvider>().filterByCategory(target);
  }

  String _getCategoryDisplayName(String catKey, SahayLocalizations l10n) {
    switch (catKey) {
      case 'agriculture':
        return l10n.agriculture;
      case 'health':
        return l10n.health;
      case 'housing':
        return l10n.housing;
      case 'education':
        return l10n.education;
      case 'women':
        return l10n.women;
      case 'employment':
        return l10n.employment;
      case 'socialWelfare':
        return l10n.socialWelfare;
      case 'financial':
        return l10n.financial;
      default:
        return l10n.allSchemes.isNotEmpty && l10n.allSchemes != 'allSchemes'
            ? l10n.allSchemes
            : 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.languageCode;
    final schemeProvider = context.watch<SchemeProvider>();

    final screenTitle = currentLang == 'hi'
        ? 'योजनाएं'
        : (l10n.schemes.isNotEmpty && l10n.schemes != 'schemes' ? l10n.schemes : 'Government Schemes');

    final displayedSchemes = schemeProvider.filteredSchemes;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: screenTitle,
        showBackButton: true,
        showLanguageToggle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field Container
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.paleSage,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.indianTeal.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.deepNavy,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: l10n.searchHint.isNotEmpty && l10n.searchHint != 'searchHint'
                              ? l10n.searchHint
                              : 'Search schemes by name or keyword...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.deepNavy.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.deepNavy),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: VoiceInputButton(
                          size: 36,
                          showLabel: false,
                          onResult: (text) {
                            _searchController.text = text;
                            _onSearchChanged(text);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Filter Chips (Government Level & Categories)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Level Filter: All
                  _FilterChip(
                    label: currentLang == 'hi' ? 'सभी' : 'All Levels',
                    isSelected: _selectedLevel == null,
                    onSelected: () => _onLevelFilterChanged(null),
                  ),
                  const SizedBox(width: 8),

                  // Level Filter: Central
                  _FilterChip(
                    label: l10n.central.isNotEmpty && l10n.central != 'central' ? l10n.central : 'Central',
                    isSelected: _selectedLevel == GovernmentLevel.central,
                    color: AppColors.softSaffron,
                    onSelected: () => _onLevelFilterChanged(
                      _selectedLevel == GovernmentLevel.central ? null : GovernmentLevel.central,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Level Filter: State
                  _FilterChip(
                    label: l10n.stateLevel.isNotEmpty && l10n.stateLevel != 'stateLevel' ? l10n.stateLevel : 'State',
                    isSelected: _selectedLevel == GovernmentLevel.state,
                    color: AppColors.indianTeal,
                    onSelected: () => _onLevelFilterChanged(
                      _selectedLevel == GovernmentLevel.state ? null : GovernmentLevel.state,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                  const SizedBox(width: 12),

                  // Category Chips
                  ..._categories.map((catKey) {
                    final isSelected = (_selectedCategory == null && catKey == 'all') ||
                        (_selectedCategory == catKey);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _FilterChip(
                        label: _getCategoryDisplayName(catKey, l10n),
                        isSelected: isSelected,
                        onSelected: () => _onCategoryFilterChanged(catKey),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Schemes Count Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${displayedSchemes.length} ${displayedSchemes.length == 1 ? 'Scheme found' : 'Schemes found'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.deepNavy.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_searchController.text.isNotEmpty ||
                      _selectedLevel != null ||
                      _selectedCategory != null)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _selectedLevel = null;
                        _selectedCategory = null;
                        schemeProvider.clearFilters();
                        setState(() {});
                      },
                      child: Text(
                        l10n.clearFilter.isNotEmpty && l10n.clearFilter != 'clearFilter'
                            ? l10n.clearFilter
                            : 'Clear Filters',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedCoral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 12),

            // Schemes List View / Loading / Empty State
            Expanded(
              child: schemeProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.indianTeal),
                    )
                  : displayedSchemes.isEmpty
                      ? _buildEmptyState(context, l10n)
                      : RefreshIndicator(
                          color: AppColors.indianTeal,
                          onRefresh: () async {
                            await context.read<SchemeProvider>().loadSchemes(SchemeDataService());
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: displayedSchemes.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final scheme = displayedSchemes[index];
                              return _SchemeCard(
                                scheme: scheme,
                                langCode: currentLang,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SahayLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.paleSage,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 46,
                color: AppColors.steelBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noResults.isNotEmpty && l10n.noResults != 'noResults'
                  ? l10n.noResults
                  : 'No Schemes Match Your Filter',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noResultsDescription.isNotEmpty && l10n.noResultsDescription != 'noResultsDescription'
                  ? l10n.noResultsDescription
                  : 'Try searching with different keywords or clear selected filters to see all available schemes.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.deepNavy.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _selectedLevel = null;
                _selectedCategory = null;
                context.read<SchemeProvider>().clearFilters();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indianTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                l10n.clearFilter.isNotEmpty && l10n.clearFilter != 'clearFilter'
                    ? l10n.clearFilter
                    : 'Show All Schemes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = color ?? AppColors.indianTeal;

    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppColors.warmSand,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBg : AppColors.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected
                ? (color == AppColors.softSaffron ? AppColors.deepNavy : Colors.white)
                : AppColors.deepNavy,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final SchemeModel scheme;
  final String langCode;
  final VoidCallback onTap;

  const _SchemeCard({
    required this.scheme,
    required this.langCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCentral = scheme.governmentLevel == GovernmentLevel.central;
    final stripColor = isCentral ? AppColors.softSaffron : AppColors.indianTeal;

    final displayName = (langCode == 'hi' && scheme.nameHindi != null && scheme.nameHindi!.isNotEmpty)
        ? scheme.nameHindi!
        : scheme.name;

    final displayDesc = (langCode == 'hi' && scheme.descriptionHindi != null && scheme.descriptionHindi!.isNotEmpty)
        ? scheme.descriptionHindi!
        : scheme.description;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmSand,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Color-coded left strip: Soft Saffron for Central, Indian Teal for State
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: stripColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                  ),
                ),

                // Card Main Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges Row: Level badge and Category tag
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: stripColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCentral ? 'CENTRAL SCHEME' : 'STATE SCHEME',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.deepNavy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.paleSage,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scheme.category.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.indianTeal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppColors.indianTeal,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Scheme Title
                        Text(
                          displayName,
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 16,
                            color: AppColors.deepNavy,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Ministry name
                        Text(
                          scheme.ministry,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepNavy.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Description snippet
                        Text(
                          displayDesc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.deepNavy.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
