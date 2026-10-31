import 'package:flutter/foundation.dart';
import 'package:sahay/models/api_response_models.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/services/backend_scheme_service.dart';
import 'package:sahay/services/category_service.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/utils/indian_states.dart';

class SchemeProvider extends ChangeNotifier {
  List<SchemeModel> _schemes = [];
  List<SchemeModel> _filteredSchemes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _categoryFilter;
  GovernmentLevel? _levelFilter;
  String? _stateFilter;

  // Getters
  List<SchemeModel> get schemes => List.unmodifiable(_schemes);
  List<SchemeModel> get filteredSchemes => List.unmodifiable(_filteredSchemes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  GovernmentLevel? get levelFilter => _levelFilter;
  String? get stateFilter => _stateFilter;
  int get totalSchemesCount => _schemes.length;
  int get filteredSchemesCount => _filteredSchemes.length;

  List<SchemeModel> get popularSchemes =>
      _schemes.where((scheme) => scheme.isPopular).toList();

  // Load baseline curated schemes (for backward compatibility)
  Future<void> loadSchemes(SchemeDataService dataService) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _schemes = await dataService.getAllSchemes();
      _applyFilters();
    } catch (e, stackTrace) {
      debugPrint('SchemeProvider error: $e\n$stackTrace');
      _error = e.toString();
      _filteredSchemes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load complete ~100 scheme catalogue
  Future<void> loadFullCatalogue([SchemeDataService? dataService]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final service = dataService ?? const SchemeDataService();
    try {
      _schemes = await service.getCompleteCatalogue();
      _applyFilters();
    } catch (e, stackTrace) {
      debugPrint('SchemeProvider.loadFullCatalogue error: $e\n$stackTrace');
      _error = e.toString();
      _filteredSchemes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search
  void searchSchemes(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    }
  }

  // Search with Live Hybrid Discovery
  Future<void> searchSchemesWithDiscovery(
    String query, {
    bool forceDynamic = false,
    BackendSchemeService? service,
  }) async {
    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final backendService = service ?? BackendSchemeService();
    try {
      final req = SchemeSearchApiRequest(
        query: query,
        category: _categoryFilter,
        governmentLevel: _levelFilter,
        forceDynamicDiscovery: forceDynamic,
      );
      final response = await backendService.searchSchemes(req);
      _schemes = response.results;
      _filteredSchemes = response.results;
    } catch (e) {
      _error = e.toString();
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter
  void filterByCategory(String? category) {
    final normalized = (category == null || category.trim().isEmpty || category.toLowerCase() == 'all')
        ? null
        : CategoryService.normalizeCategory(category.trim());

    if (_categoryFilter != normalized) {
      _categoryFilter = normalized;
      _applyFilters();
      notifyListeners();
    }
  }

  void filterByLevel(GovernmentLevel? level) {
    if (_levelFilter != level) {
      _levelFilter = level;
      _applyFilters();
      notifyListeners();
    }
  }

  void filterByState(String? state) {
    final normalized = (state == null || state.trim().isEmpty || state.toLowerCase() == 'all')
        ? null
        : state.trim();

    if (_stateFilter != normalized) {
      _stateFilter = normalized;
      _applyFilters();
      notifyListeners();
    }
  }

  // Reset
  void clearFilters() {
    bool hasActiveFilter = _searchQuery.isNotEmpty ||
        _categoryFilter != null ||
        _levelFilter != null ||
        _stateFilter != null;

    if (hasActiveFilter) {
      _searchQuery = '';
      _categoryFilter = null;
      _levelFilter = null;
      _stateFilter = null;
      _applyFilters();
      notifyListeners();
    }
  }

  // Lookup
  SchemeModel? getSchemeById(String id) {
    try {
      return _schemes.firstWhere((scheme) => scheme.schemeId == id);
    } catch (_) {
      return null;
    }
  }

  // Filter logic
  void _applyFilters() {
    List<SchemeModel> result = List.of(_schemes);

    if (_levelFilter != null) {
      result = result
          .where((scheme) => scheme.governmentLevel == _levelFilter)
          .toList();
    }

    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      result = result
          .where((scheme) => CategoryService.matchesCategory(scheme.category, _categoryFilter!))
          .toList();
    }

    if (_stateFilter != null && _stateFilter!.isNotEmpty) {
      final stateUpper = _stateFilter!.trim().toUpperCase();
      result = result.where((scheme) {
        if (scheme.applicableStates.contains('ALL_INDIA') ||
            scheme.governmentLevel == GovernmentLevel.central) {
          return true;
        }
        return scheme.applicableStates.any((s) =>
            s.toUpperCase() == stateUpper ||
            (IndianStates.findByCode(s)?.nameEnglish.toUpperCase() == stateUpper));
      }).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((scheme) {
        final matchesName = scheme.name.toLowerCase().contains(query);
        final matchesHindiName =
            scheme.nameHindi?.toLowerCase().contains(query) ?? false;
        final matchesDescription =
            scheme.description.toLowerCase().contains(query);
        final matchesCategory =
            scheme.category.toLowerCase().contains(query);
        final matchesMinistry =
            scheme.ministry.toLowerCase().contains(query);
        final matchesBenefits =
            scheme.benefits.toLowerCase().contains(query);

        return matchesName ||
            matchesHindiName ||
            matchesDescription ||
            matchesCategory ||
            matchesMinistry ||
            matchesBenefits;
      }).toList();
    }

    _filteredSchemes = result;
  }
}
