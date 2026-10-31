import 'package:sahay/services/backend_scheme_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/services/eligibility_engine.dart';

class EligibilityProvider extends ChangeNotifier {
  final EligibilityEngine _engine;

  List<EligibilityModel> _results = [];
  bool _isEvaluating = false;
  bool _hasEvaluated = false;

  EligibilityProvider({EligibilityEngine? engine})
      : _engine = engine ?? const EligibilityEngine();

  // Getters
  List<EligibilityModel> get results => List.unmodifiable(_results);
  List<EligibilityModel> get qualifyingSchemes => _results
      .where((element) => element.result == EligibilityResult.mayQualify)
      .toList();

  List<EligibilityModel> get needsInfoSchemes => _results
      .where((element) =>
          element.result == EligibilityResult.needsMoreInformation)
      .toList();

  List<EligibilityModel> get notQualifyingSchemes => _results
      .where((element) =>
          element.result == EligibilityResult.doesNotQualify)
      .toList();

  bool get isEvaluating => _isEvaluating;
  bool get hasEvaluated => _hasEvaluated;
  int get qualifyingCount => qualifyingSchemes.length;
  int get needsInfoCount => needsInfoSchemes.length;
  int get notQualifyingCount => notQualifyingSchemes.length;
  int get totalEvaluatedCount => _results.length;

  // Evaluate all
  void evaluateAll(
    List<SchemeModel> schemes,
    Map<String, dynamic> userAnswers,
  ) {
    if (schemes.isEmpty) {
      _results = [];
      _hasEvaluated = true;
      _isEvaluating = false;
      notifyListeners();
      return;
    }

    _isEvaluating = true;
    notifyListeners();

    try {
      _results = _engine.evaluateAllSchemes(schemes, userAnswers);
      _hasEvaluated = true;
    } catch (e, stackTrace) {
      debugPrint('EligibilityProvider error: $e\n$stackTrace');
      _results = [];
    } finally {
      _isEvaluating = false;
      notifyListeners();
    }
  }

  // Evaluate single
  EligibilityModel evaluateSingle(
    SchemeModel scheme,
    Map<String, dynamic> userAnswers,
  ) {
    final result = _engine.evaluateScheme(scheme, userAnswers);
    final existingIndex =
        _results.indexWhere((r) => r.schemeId == scheme.schemeId);

    if (existingIndex >= 0) {
      _results[existingIndex] = result;
    } else {
      _results.add(result);
    }

    _hasEvaluated = true;
    notifyListeners();
    return result;
  }

  // Lookup
  EligibilityModel? getResultForScheme(String schemeId) {
    try {
      return _results.firstWhere((r) => r.schemeId == schemeId);
    } catch (_) {
      return null;
    }
  }

  // Warnings
  List<String> getBorderlineWarnings(
    String schemeId,
    Map<String, dynamic> userAnswers,
  ) {
    final result = getResultForScheme(schemeId);
    if (result == null) return const [];
    return _engine.detectBorderlineConditions(result, userAnswers);
  }


  // Evaluate single with optional backend explanation
  Future<EligibilityModel> evaluateSingleWithBackend(
    SchemeModel scheme,
    Map<String, dynamic> userAnswers, {
    BackendSchemeService? service,
    String language = 'en',
  }) async {
    final backendService = service ?? BackendSchemeService();
    final backendResult = await backendService.evaluateSchemeDetailed(
      schemeId: scheme.schemeId,
      userAnswers: userAnswers,
      language: language,
    );
    final result = backendResult ?? _engine.evaluateScheme(scheme, userAnswers);
    final existingIndex = _results.indexWhere((r) => r.schemeId == scheme.schemeId);
    if (existingIndex >= 0) {
      _results[existingIndex] = result;
    } else {
      _results.add(result);
    }
    _hasEvaluated = true;
    notifyListeners();
    return result;
  }

  // Reset
  void clearResults() {
    if (_results.isNotEmpty || _hasEvaluated || _isEvaluating) {
      _results = [];
      _hasEvaluated = false;
      _isEvaluating = false;
      notifyListeners();
    }
  }
}
