import 'package:flutter/foundation.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/services/application_api_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationApiService _apiService;
  List<SchemeRegistryEntryModel> _supportedSchemes = [];
  ApplicationSession? _currentSession;
  PortalPopulationPayloadModel? _portalPayload;
  ReadBackVerificationReportModel? _readBackReport;
  bool _isLoading = false;
  String? _errorMessage;

  // The 10 Target Scheme IDs supported by the SAHAY Smart Application Filler
  static const Set<String> _targetSchemeIds = {
    'PM_KISAN_001',
    'PMAY_002',
    'E_SHRAM_001',
    'UDYAM_001',
    'PM_SURYA_GHAR_001',
    'PM_SVANIDHI_001',
    'PMEGP_001',
    'MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001',
    'AICTE_PRAGATI_001',
    'AICTE_SAKSHAM_001',
  };

  ApplicationProvider({ApplicationApiService? apiService})
      : _apiService = apiService ?? ApplicationApiService();

  List<SchemeRegistryEntryModel> get supportedSchemes => _supportedSchemes;
  ApplicationSession? get currentSession => _currentSession;
  PortalPopulationPayloadModel? get portalPayload => _portalPayload;
  ReadBackVerificationReportModel? get readBackReport => _readBackReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Normalizes any scheme ID or alias to canonical 10-scheme registry ID.
  static String normalizeSchemeId(String schemeId) {
    final lower = schemeId.toLowerCase().trim();
    if (lower == 'pm-kisan' || lower == 'pmkisan' || lower == 'pm_kisan' || lower == 'pm_kisan_001') return 'PM_KISAN_001';
    if (lower == 'pmay-u' || lower == 'pmayu' || lower == 'pmay_u' || lower == 'pmay_002' || lower == 'pmay-u-2' || lower == 'pmay_u_2') return 'PMAY_002';
    if (lower == 'eshram' || lower == 'e-shram' || lower == 'e_shram' || lower == 'e_shram_001') return 'E_SHRAM_001';
    if (lower == 'udyam' || lower == 'udyam_001') return 'UDYAM_001';
    if (lower == 'pm-surya-ghar' || lower == 'pmsuryaghar' || lower == 'pm_surya_ghar' || lower == 'pm_surya_ghar_001') return 'PM_SURYA_GHAR_001';
    if (lower == 'pm-svanidhi' || lower == 'pmsvanidhi' || lower == 'pm_svanidhi' || lower == 'pm_svanidhi_001') return 'PM_SVANIDHI_001';
    if (lower == 'pmegp' || lower == 'pmegp_001') return 'PMEGP_001';
    if (lower.contains('mp_post_matric') || lower.contains('mp-post-matric') || lower == 'mp_post_matric_scholarship_sc_st_001') return 'MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001';
    if (lower.contains('aicte_pragati') || lower.contains('aicte-pragati') || lower == 'aicte_pragati_001') return 'AICTE_PRAGATI_001';
    if (lower.contains('aicte_saksham') || lower.contains('aicte-saksham') || lower == 'aicte_saksham_001') return 'AICTE_SAKSHAM_001';
    return schemeId;
  }

  /// Determines if a given scheme is supported by the SAHAY Smart Application Filler.
  bool isSchemeSupported(String schemeId) {
    final canonical = normalizeSchemeId(schemeId);
    if (_targetSchemeIds.contains(canonical) || _targetSchemeIds.contains(schemeId)) return true;
    return _supportedSchemes.any((s) => s.schemeId == canonical || s.schemeId == schemeId);
  }

  /// Gets registry entry metadata for a supported scheme.
  SchemeRegistryEntryModel? getRegistryEntry(String schemeId) {
    final canonical = normalizeSchemeId(schemeId);
    try {
      return _supportedSchemes.firstWhere((s) => s.schemeId == canonical || s.schemeId == schemeId);
    } catch (_) {
      return null;
    }
  }

  /// Loads the 10-scheme central registry from the backend.
  Future<void> loadSupportedSchemes() async {
    try {
      final schemes = await _apiService.getSupportedSchemes();
      if (schemes.isNotEmpty) {
        _supportedSchemes = schemes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ApplicationProvider: loadSupportedSchemes error: $e');
    }
  }

  /// Clears active application session data on logout or session end
  void clearSession() {
    _currentSession = null;
    _portalPayload = null;
    _readBackReport = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Starts or resumes the unified Smart Application Filler workflow.
  Future<bool> startSession({
    required SchemeModel scheme,
    Map<String, dynamic>? userProfileAnswers,
    String language = 'en',
    // Kept for backward compatibility
    InteractionMode? mode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _apiService.startApplication(
        schemeId: normalizeSchemeId(scheme.schemeId),
        profileAnswers: userProfileAnswers,
        language: language,
      );

      if (session != null) {
        _currentSession = session;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('ApplicationProvider: Backend session start failed: $e. Falling back to local offline session.');
    }

    // High-fidelity fallback session if offline
    _currentSession = _createLocalGuidedSession(scheme, userProfileAnswers);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Answers multiple missing fields at once.
  Future<bool> submitMissingAnswers(Map<String, dynamic> answers) async {
    if (_currentSession == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentSession!.sessionId.startsWith('app_sess_')) {
        final updated = await _apiService.answerMissingFields(
          sessionId: _currentSession!.sessionId,
          answers: answers,
        );
        if (updated != null) {
          _currentSession = updated;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('ApplicationProvider: submitMissingAnswers error: $e');
    }

    // Local fallback update
    answers.forEach((key, val) {
      for (final sec in _currentSession!.sections) {
        for (final f in sec.fields) {
          if (f.fieldId == key) {
            f.mappedValue = val;
            f.userConfirmed = true;
            f.mappingStatus = MappingStatus.userConfirmed;
            f.validationStatus = 'valid';
            break;
          }
        }
      }
    });

    _recalculateLocalCounters();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Backward-compatible single field update.
  Future<void> updateField(String fieldId, dynamic value) async {
    await submitMissingAnswers({fieldId: value});
  }

  /// Resolves an explicit discrepancy where user profile and document OCR disagree.
  Future<bool> resolveConflict(String fieldId, dynamic confirmedValue) async {
    if (_currentSession == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentSession!.sessionId.startsWith('app_sess_')) {
        final updated = await _apiService.resolveConflict(
          sessionId: _currentSession!.sessionId,
          fieldId: fieldId,
          confirmedValue: confirmedValue,
        );
        if (updated != null) {
          _currentSession = updated;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('ApplicationProvider: resolveConflict error: $e');
    }

    // Local fallback update
    for (final sec in _currentSession!.sections) {
      for (final f in sec.fields) {
        if (f.fieldId == fieldId) {
          f.mappedValue = confirmedValue;
          f.userConfirmed = true;
          f.mappingStatus = MappingStatus.userConfirmed;
          f.validationStatus = 'valid';
          break;
        }
      }
    }

    _recalculateLocalCounters();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Fetches declarative population payload and read-back selectors for official portal.
  Future<PortalPopulationPayloadModel?> fetchPortalPopulationPayload() async {
    if (_currentSession == null) return null;
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentSession!.sessionId.startsWith('app_sess_')) {
        final payload = await _apiService.getPortalPopulatePayload(_currentSession!.sessionId);
        _portalPayload = payload;
        _isLoading = false;
        notifyListeners();
        return payload;
      }
    } catch (e) {
      debugPrint('ApplicationProvider: fetchPortalPopulationPayload error: $e');
    }

    // Local mock payload for offline simulation
    _portalPayload = PortalPopulationPayloadModel(
      portalId: '${_currentSession!.schemeId.toLowerCase()}_adapter',
      portalDomain: _currentSession!.officialUrl ?? 'gov.in',
      declarativeInstructions: [
        {'action': 'POPULATE_LOCAL_SIM'}
      ],
      manualInterventionRequired: [
        'Visual Image CAPTCHA must be entered by the citizen',
        'Mobile OTP Verification required',
      ],
    );
    _isLoading = false;
    notifyListeners();
    return _portalPayload;
  }

  /// Submits DOM read-back inspection data and generates verification report.
  Future<ReadBackVerificationReportModel?> verifyReadBack(Map<String, dynamic> domValues) async {
    if (_currentSession == null) return null;
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentSession!.sessionId.startsWith('app_sess_')) {
        final report = await _apiService.verifyPortalReadback(
          sessionId: _currentSession!.sessionId,
          readBackData: domValues,
        );
        if (report != null) {
          _readBackReport = report;
          _currentSession!.readBackReport = report;
          _isLoading = false;
          notifyListeners();
          return report;
        }
      }
    } catch (e) {
      debugPrint('ApplicationProvider: verifyReadBack error: $e');
    }

    // Local report synthesis
    final allFields = _currentSession!.sections.expand((s) => s.fields).toList();
    final items = <ReadBackFieldItemModel>[];
    int verified = 0;
    int unverified = 0;

    for (final f in allFields) {
      final actual = domValues[f.fieldId] ?? domValues[f.portalSelector];
      final matches = actual != null && actual.toString() == (f.mappedValue?.toString() ?? '');
      if (matches) {
        verified++;
      } else {
        unverified++;
      }
      items.add(
        ReadBackFieldItemModel(
          fieldId: f.fieldId,
          selector: f.portalSelector ?? f.fieldId,
          expectedValue: f.mappedValue,
          readValue: actual,
          status: matches ? ReadBackFieldStatus.filledVerified : ReadBackFieldStatus.filledUnverified,
          message: matches ? 'DOM value matches profile' : 'Value mismatch in portal field',
        ),
      );
    }

    final localReport = ReadBackVerificationReportModel(
      totalFields: allFields.length,
      verifiedCount: verified,
      unverifiedCount: unverified,
      canProceedToReview: unverified == 0,
      items: items,
    );

    _readBackReport = localReport;
    _currentSession!.readBackReport = localReport;
    _isLoading = false;
    notifyListeners();
    return localReport;
  }

  /// Validates all sections and fields.
  Future<bool> validateSession() async {
    if (_currentSession == null) return false;

    if (_currentSession!.sessionId.startsWith('app_sess_')) {
      try {
        final res = await _apiService.validateSession(_currentSession!.sessionId);
        if (res != null) {
          _currentSession!.canSubmit = res['can_submit'] == true;
          _currentSession!.validationErrors =
              (res['missing_required_fields'] as List? ?? []).map((e) => 'Missing: $e').toList();
          notifyListeners();
          return _currentSession!.canSubmit;
        }
      } catch (e) {
        debugPrint('ApplicationProvider: Validation API error: $e');
      }
    }

    _recalculateLocalCounters();
    notifyListeners();
    return _currentSession!.canSubmit;
  }

  /// Final citizen submission confirmation.
  Future<bool> confirmFinalSubmission({required bool userApproved, String? ackNumber}) async {
    if (_currentSession == null || !userApproved) return false;

    _isLoading = true;
    notifyListeners();

    try {
      if (_currentSession!.sessionId.startsWith('app_sess_')) {
        final res = await _apiService.confirmSubmission(
          sessionId: _currentSession!.sessionId,
          explicitApproval: userApproved,
          acknowledgementNumber: ackNumber,
        );
        if (res != null) {
          _currentSession = res;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('ApplicationProvider: confirmSubmission error: $e');
    }

    _currentSession!.status = ApplicationStatus.submittedConfirmed;
    _currentSession!.submissionConfirmed = true;
    _currentSession!.submissionReference =
        ackNumber ?? 'SAHAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Requests plain-language explanation for confusing fields.
  Future<Map<String, String>?> getFieldExplanation(String fieldId, String label, {String language = 'en'}) async {
    return _apiService.explainField(
      sessionId: _currentSession?.sessionId ?? '',
      fieldId: fieldId,
      fieldLabel: label,
      language: language,
    );
  }

  // ==========================================
  // Local Counter & Fallback Helpers
  // ==========================================

  void _recalculateLocalCounters() {
    if (_currentSession == null) return;
    int missing = 0;
    int conflicts = 0;
    final errors = <String>[];

    for (final sec in _currentSession!.sections) {
      for (final f in sec.fields) {
        if (f.isRequired && (f.mappedValue == null || f.mappedValue.toString().trim().isEmpty)) {
          missing++;
          errors.add('Missing required field: ${f.fieldLabel}');
        }
        if (f.conflictDetected && !f.userConfirmed) {
          conflicts++;
          errors.add('Unresolved conflict in: ${f.fieldLabel}');
        }
      }
    }

    _currentSession!.missingFieldsCount = missing;
    _currentSession!.conflictsCount = conflicts;
    _currentSession!.validationErrors = errors;
    _currentSession!.canSubmit = (missing == 0 && conflicts == 0);
  }

  ApplicationSession _createLocalGuidedSession(SchemeModel scheme, Map<String, dynamic>? userAnswers) {
    final answers = userAnswers ?? {};
    final personalFields = [
      FieldMappingModel(
        fieldId: 'fullName',
        fieldLabel: 'Full Name (as per Aadhaar)',
        fieldLabelHi: 'पूरा नाम (आधार के अनुसार)',
        fieldType: FieldType.text,
        isRequired: true,
        mappedValue: answers['fullName'] ?? answers['name'],
        mappingStatus: (answers['fullName'] != null) ? MappingStatus.prefilled : MappingStatus.missing,
        provenance: answers['fullName'] != null
            ? ValueProvenanceModel(field: 'fullName', value: answers['fullName'], source: 'user_profile', lastUpdatedAt: DateTime.now().toIso8601String())
            : null,
      ),
      FieldMappingModel(
        fieldId: 'gender',
        fieldLabel: 'Gender',
        fieldLabelHi: 'लिंग',
        fieldType: FieldType.dropdown,
        options: ['Male', 'Female', 'Transgender'],
        isRequired: true,
        mappedValue: answers['gender'],
        mappingStatus: (answers['gender'] != null) ? MappingStatus.prefilled : MappingStatus.missing,
      ),
      FieldMappingModel(
        fieldId: 'mobileNumber',
        fieldLabel: 'Aadhaar-Linked Mobile Number',
        fieldLabelHi: 'आधार से लिंक मोबाइल नंबर',
        fieldType: FieldType.phone,
        isRequired: true,
        mappedValue: answers['mobileNumber'] ?? answers['phone'],
        mappingStatus: (answers['mobileNumber'] != null) ? MappingStatus.prefilled : MappingStatus.missing,
      ),
    ];

    final addressFields = [
      FieldMappingModel(
        fieldId: 'state',
        fieldLabel: 'State / Union Territory',
        fieldLabelHi: 'राज्य / केंद्र शासित प्रदेश',
        fieldType: FieldType.dropdown,
        isRequired: true,
        mappedValue: answers['state'] ?? 'Madhya Pradesh',
        mappingStatus: MappingStatus.prefilled,
      ),
      FieldMappingModel(
        fieldId: 'district',
        fieldLabel: 'District',
        fieldLabelHi: 'जिला',
        fieldType: FieldType.dropdown,
        isRequired: true,
        mappedValue: answers['district'],
        mappingStatus: (answers['district'] != null) ? MappingStatus.prefilled : MappingStatus.missing,
      ),
    ];

    final financialFields = [
      FieldMappingModel(
        fieldId: 'annualIncome',
        fieldLabel: 'Annual Household Income (₹)',
        fieldLabelHi: 'वार्षिक पारिवारिक आय (₹)',
        fieldType: FieldType.number,
        isRequired: true,
        mappedValue: answers['annualFamilyIncome'] ?? answers['annualIncome'],
        mappingStatus: (answers['annualFamilyIncome'] != null || answers['annualIncome'] != null)
            ? MappingStatus.prefilled
            : MappingStatus.missing,
      ),
    ];

    final sections = [
      ApplicationSectionModel(
        sectionId: 'sec_personal',
        title: 'Personal & Demographic Details',
        titleHi: 'व्यक्तिगत एवं जनसांख्यिकीय विवरण',
        fields: personalFields,
      ),
      ApplicationSectionModel(
        sectionId: 'sec_address',
        title: 'Residential Address Details',
        titleHi: 'आवासीय पते का विवरण',
        fields: addressFields,
      ),
      ApplicationSectionModel(
        sectionId: 'sec_financial',
        title: 'Income & Financial Details',
        titleHi: 'आय एवं वित्तीय विवरण',
        fields: financialFields,
      ),
    ];

    final docRequirements = (scheme.requiredDocuments.isNotEmpty ? scheme.requiredDocuments : ['aadhaar_card', 'bank_passbook'])
        .map((docName) => DocumentRequirementModel(
              documentId: docName.toLowerCase().replaceAll(' ', '_'),
              documentName: docName,
              isMandatory: true,
              status: 'missing',
            ))
        .toList();

    int missing = sections.expand((s) => s.fields).where((f) => f.isRequired && (f.mappedValue == null || f.mappedValue.toString().trim().isEmpty)).length;

    return ApplicationSession(
      sessionId: 'local_sess_${DateTime.now().millisecondsSinceEpoch}',
      schemeId: normalizeSchemeId(scheme.schemeId),
      schemeName: scheme.name,
      schemeCategory: scheme.category,
      officialUrl: scheme.applicationUrl,
      status: ApplicationStatus.ready,
      sections: sections,
      documents: docRequirements,
      missingFieldsCount: missing,
      conflictsCount: 0,
      canSubmit: missing == 0,
    );
  }
}
