import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/screens/questionnaire_screen.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/services/category_service.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/utils/indian_states.dart';
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
  Timer? _debounceTimer;
  GovernmentLevel? _selectedLevel;
  String? _selectedCategory;
  String? _selectedState;

  late final List<String> _categories = [
    'all',
    ...CategoryService.allCategories.map((c) => c.categoryId),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = CategoryService.normalizeCategory(widget.initialCategory!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schemeProvider = context.read<SchemeProvider>();
      if (schemeProvider.schemes.isEmpty && !schemeProvider.isLoading) {
        schemeProvider.loadFullCatalogue(SchemeDataService()).then((_) {
          _applyInitialFilters();
        });
      } else {
        _applyInitialFilters();
      }
    });
  }

  void _showStatePicker(BuildContext context, String currentLang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.warmSand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filteredStates = IndianStates.allStates.where((s) {
              final query = searchQuery.trim().toLowerCase();
              if (query.isEmpty) return true;
              return s.nameEnglish.toLowerCase().contains(query) ||
                  s.nameHindi.toLowerCase().contains(query) ||
                  s.code.toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentLang == 'hi' ? 'राज्य चुनें' : 'Select State',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.deepNavy),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        onChanged: (val) => setModalState(() => searchQuery = val),
                        decoration: InputDecoration(
                          hintText: currentLang == 'hi' ? 'राज्य खोजें...' : 'Search state...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.deepNavy),
                          filled: true,
                          fillColor: AppColors.paleSage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.all_inclusive_rounded, color: AppColors.indianTeal),
                      title: Text(
                        currentLang == 'hi' ? 'सभी राज्य (All States)' : 'All States',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: _selectedState == null ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedState == null ? AppColors.indianTeal : AppColors.deepNavy,
                        ),
                      ),
                      trailing: _selectedState == null
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.indianTeal)
                          : null,
                      onTap: () {
                        setState(() => _selectedState = null);
                        context.read<SchemeProvider>().filterByState(null);
                        Navigator.pop(modalCtx);
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredStates.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final state = filteredStates[index];
                          final isSelected = _selectedState == state.code;
                          final displayName = currentLang == 'hi'
                              ? '${state.nameHindi} (${state.nameEnglish})'
                              : state.nameEnglish;

                          return ListTile(
                            title: Text(
                              displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.indianTeal : AppColors.deepNavy,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.indianTeal)
                                : null,
                            onTap: () {
                              setState(() => _selectedState = state.code);
                              context.read<SchemeProvider>().filterByState(state.code);
                              Navigator.pop(modalCtx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _applyInitialFilters() {
    final schemeProvider = context.read<SchemeProvider>();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      schemeProvider.searchSchemes(widget.initialQuery!);
    }
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      schemeProvider.filterByCategory(_selectedCategory);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        context.read<SchemeProvider>().searchSchemes(query);
      }
    });
  }

  void _onLevelFilterChanged(GovernmentLevel? level) {
    setState(() => _selectedLevel = level);
    context.read<SchemeProvider>().filterByLevel(level);
  }

  void _onCategoryFilterChanged(String category) {
    final target = (category == 'all') ? null : CategoryService.normalizeCategory(category);
    setState(() => _selectedCategory = target);
    context.read<SchemeProvider>().filterByCategory(target);
  }

  String _getCategoryDisplayName(String catKey, SahayLocalizations l10n, String currentLang) {
    if (catKey == 'all') {
      return l10n.allSchemes.isNotEmpty && l10n.allSchemes != 'allSchemes'
          ? l10n.allSchemes
          : (currentLang == 'hi' ? 'सभी' : 'All');
    }
    return CategoryService.getCategoryTitle(catKey, lang: currentLang);
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
                  const SizedBox(width: 8),

                  // State Selector Chip
                  _FilterChip(
                    label: _selectedState == null
                        ? (currentLang == 'hi' ? 'राज्य: सभी' : 'State: All')
                        : 'State: $_selectedState',
                    isSelected: _selectedState != null,
                    color: AppColors.softSaffron,
                    onSelected: () => _showStatePicker(context, currentLang),
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
                        label: _getCategoryDisplayName(catKey, l10n, currentLang),
                        isSelected: isSelected,
                        onSelected: () => _onCategoryFilterChanged(catKey),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Category Banner Card if Category is selected
            if (_selectedCategory != null)
              _buildCategoryBanner(context, _selectedCategory!, currentLang, displayedSchemes.length),

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
                      _selectedCategory != null ||
                      _selectedState != null)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _selectedLevel = null;
                        _selectedCategory = null;
                        _selectedState = null;
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
                      ? _buildEmptyState(context, l10n, currentLang)
                      : RefreshIndicator(
                          color: AppColors.indianTeal,
                          onRefresh: () async {
                            await context.read<SchemeProvider>().loadFullCatalogue(SchemeDataService());
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

  Widget _buildCategoryBanner(
    BuildContext context,
    String categoryKey,
    String currentLang,
    int count,
  ) {
    final title = CategoryService.getCategoryTitle(categoryKey, lang: currentLang);
    final desc = CategoryService.getCategoryDescription(categoryKey, lang: currentLang);
    final color = CategoryService.getCategoryColor(categoryKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.deepNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count ${count == 1 ? 'Scheme' : 'Schemes'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.deepNavy),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  tooltip: currentLang == 'hi' ? 'श्रेणी हटाएं' : 'Clear Category',
                  onPressed: () => _onCategoryFilterChanged('all'),
                ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                desc,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.deepNavy.withValues(alpha: 0.8),
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SahayLocalizations l10n, String currentLang) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
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
                _selectedState = null;
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
            if (_searchController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<SchemeProvider>().searchSchemesWithDiscovery(
                    _searchController.text.trim(),
                    forceDynamic: true,
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.softSaffron, size: 18),
                label: Text(
                  currentLang == 'hi' ? 'AI खोज व नई योजनाएं खोजें' : 'AI Deep Scheme Discovery',
                  style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.softSaffron, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
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
                        // Badges Row: Level badge, Category tag, and Verification status pill
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: stripColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isCentral ? 'CENTRAL' : 'STATE',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.deepNavy,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9.5,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
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
                                  _buildVerificationPill(scheme, langCode),
                                ],
                              ),
                            ),
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

                        // Key Benefits Summary
                        if (scheme.benefits.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.paleSage.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.card_giftcard_rounded,
                                  size: 15,
                                  color: AppColors.indianTeal,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    (langCode == 'hi' && scheme.benefitsHindi != null && scheme.benefitsHindi!.isNotEmpty)
                                        ? scheme.benefitsHindi!
                                        : scheme.benefits,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.deepNavy,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Action Buttons: Check Eligibility & View Details
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => QuestionnaireScreen(targetSchemeId: scheme.schemeId),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.indianTeal,
                                  side: const BorderSide(color: AppColors.indianTeal, width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(
                                  langCode == 'hi' ? 'पात्रता जांचें' : 'Check Eligibility',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.indianTeal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: onTap,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.indianTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(
                                  langCode == 'hi' ? 'विवरण देखें' : 'View Details',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildVerificationPill(SchemeModel scheme, String langCode) {
    final status = scheme.badgeStatus;
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case VerificationBadgeStatus.verified:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.verified_rounded;
        label = langCode == 'hi' ? 'प्रमाणित' : 'VERIFIED';
        break;
      case VerificationBadgeStatus.partiallyVerified:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        icon = Icons.warning_amber_rounded;
        label = langCode == 'hi' ? 'आंशिक' : 'PARTIALLY VERIFIED';
        break;
      case VerificationBadgeStatus.unverified:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        icon = Icons.help_outline_rounded;
        label = langCode == 'hi' ? 'गैर-प्रमाणित' : 'UNVERIFIED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 8.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
