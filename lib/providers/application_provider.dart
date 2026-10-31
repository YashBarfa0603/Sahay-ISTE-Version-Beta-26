import 'package:flutter/foundation.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/services/application_api_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationApiService _apiService;
  ApplicationSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  ApplicationProvider({ApplicationApiService? apiService})
      : _apiService = apiService ?? ApplicationApiService();

  ApplicationSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Starts or resumes an application session for a target scheme.
  Future<bool> startSession({
    required SchemeModel scheme,
    InteractionMode? mode,
    String language = 'en',
    Map<String, dynamic>? userProfileAnswers,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Attempt backend multi-agent session creation
      final session = await _apiService.startApplication(
        schemeId: scheme.schemeId,
        mode: mode,
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

    // 2. Offline fallback: Create high-fidelity local guided session from SchemeModel
    _currentSession = _createLocalGuidedSession(scheme, userProfileAnswers);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Updates an individual field value.
  Future<void> updateField(String fieldId, dynamic value) async {
    if (_currentSession == null) return;

    // Optimistically update local session
    for (final sec in _currentSession!.sections) {
      for (final f in sec.fields) {
        if (f.fieldId == fieldId) {
          f.mappedValue = value;
          f.userConfirmed = true;
          f.mappingStatus = MappingStatus.userConfirmed;
          f.validationStatus = 'valid';
          break;
        }
      }
    }
    _recalculateLocalValidation();
    notifyListeners();

    // Sync to backend if session is active
    if (_currentSession!.sessionId.startsWith('app_sess_')) {
      try {
        final updated = await _apiService.answerField(
          sessionId: _currentSession!.sessionId,
          fieldId: fieldId,
          value: value,
        );
        if (updated != null) {
          _currentSession = updated;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('ApplicationProvider: Background field sync error: $e');
      }
    }
  }

  /// Confirms an explicit value when profile and document disagree.
  Future<void> resolveConflict(String fieldId, dynamic confirmedValue) async {
    if (_currentSession == null) return;

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
    _recalculateLocalValidation();
    notifyListeners();

    if (_currentSession!.sessionId.startsWith('app_sess_')) {
      try {
        final updated = await _apiService.confirmConflict(
          sessionId: _currentSession!.sessionId,
          fieldId: fieldId,
          confirmedValue: confirmedValue,
        );
        if (updated != null) {
          _currentSession = updated;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('ApplicationProvider: Background conflict confirmation error: $e');
      }
    }
  }

  /// Requests plain-language explanation for confusing fields.
  Future<Map<String, String>?> getFieldExplanation(String fieldId, String label, {String language = 'en'}) async {
    if (_currentSession != null && _currentSession!.sessionId.startsWith('app_sess_')) {
      return await _apiService.explainField(
        sessionId: _currentSession!.sessionId,
        fieldId: fieldId,
        fieldLabel: label,
        language: language,
      );
    }

    // Local fallback explanation
    if (language == 'hi') {
      return {
        'explanation': 'कृपया अपने आधिकारिक दस्तावेजों के अनुसार $label की सही प्रविष्टि करें।',
        'example': 'दस्तावेज़ में दर्ज सही जानकारी भरें।',
        'language': 'hi',
      };
    } else if (language.contains('hing')) {
      return {
        'explanation': '$label ki sahi details official documents ke mutabiq yahan enter karein.',
        'example': 'Aadhaar ya certificates check karke bharein.',
        'language': 'hinglish',
      };
    }
    return {
      'explanation': 'Please enter accurate information for $label matching your official government documents.',
      'example': 'Refer to your certificates before filling.',
      'language': 'en',
    };
  }

  /// Validates all sections and fields.
  Future<bool> validateSession() async {
    if (_currentSession == null) return false;

    if (_currentSession!.sessionId.startsWith('app_sess_')) {
      try {
        final res = await _apiService.validateSession(_currentSession!.sessionId);
        if (res != null) {
          _currentSession!.canSubmit = res['can_submit'] == true;
          _currentSession!.validationErrors = (res['missing_required_fields'] as List? ?? []).map((e) => 'Missing: $e').toList();
          notifyListeners();
          return _currentSession!.canSubmit;
        }
      } catch (e) {
        debugPrint('ApplicationProvider: Validation API call error: $e');
      }
    }

    _recalculateLocalValidation();
    notifyListeners();
    return _currentSession!.canSubmit;
  }

  /// Final citizen submission confirmation.
  Future<bool> confirmFinalSubmission({required bool userApproved, String? ackNumber}) async {
    if (_currentSession == null || !userApproved) return false;

    _isLoading = true;
    notifyListeners();

    bool success = true;
    if (_currentSession!.sessionId.startsWith('app_sess_')) {
      success = await _apiService.confirmSubmission(
        sessionId: _currentSession!.sessionId,
        explicitApproval: userApproved,
        acknowledgementNumber: ackNumber,
      );
    }

    _currentSession!.status = ApplicationStatus.submittedConfirmed;
    _currentSession!.submissionConfirmed = true;
    _currentSession!.submissionReference = ackNumber ?? 'SAHAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void _recalculateLocalValidation() {
    if (_currentSession == null) return;
    final missing = <String>[];
    for (final sec in _currentSession!.sections) {
      for (final f in sec.fields) {
        if (f.isRequired && (f.mappedValue == null || f.mappedValue.toString().trim().isEmpty)) {
          missing.add(f.fieldLabel);
        }
      }
    }
    _currentSession!.canSubmit = missing.isEmpty;
    _currentSession!.validationErrors = missing.map((m) => 'Missing required: $m').toList();
  }

  /// Creates a local fallback session when offline.
  ApplicationSession _createLocalGuidedSession(SchemeModel scheme, Map<String, dynamic>? userAnswers) {
    final answers = userAnswers ?? {};

    final personalFields = [
      FieldMappingModel(
        fieldId: 'fullName',
        fieldLabel: 'Full Name (as per Aadhaar)',
        fieldLabelHi: 'पूरा नाम (आधार के अनुसार)',
        mappedValue: answers['fullName'] ?? 'Citizen User',
        mappingStatus: answers.containsKey('fullName') ? MappingStatus.prefilled : MappingStatus.missing,
        sourceType: SourceType.userProfile,
      ),
      FieldMappingModel(
        fieldId: 'mobileNumber',
        fieldLabel: 'Active Mobile Number',
        fieldLabelHi: 'सक्रिय मोबाइल नंबर',
        fieldType: FieldType.phone,
        mappedValue: answers['mobileNumber'],
        mappingStatus: answers.containsKey('mobileNumber') ? MappingStatus.prefilled : MappingStatus.missing,
        sourceType: SourceType.userProfile,
      ),
      FieldMappingModel(
        fieldId: 'aadhaarNumber',
        fieldLabel: 'Aadhaar Number',
        fieldLabelHi: 'आधार संख्या',
        mappedValue: answers['aadhaarNumber'],
        mappingStatus: answers.containsKey('aadhaarNumber') ? MappingStatus.prefilled : MappingStatus.missing,
      ),
      FieldMappingModel(
        fieldId: 'gender',
        fieldLabel: 'Gender',
        fieldLabelHi: 'लिंग',
        fieldType: FieldType.dropdown,
        options: ['Male', 'Female', 'Transgender'],
        mappedValue: answers['gender'] ?? 'Male',
        mappingStatus: MappingStatus.prefilled,
      ),
    ];

    final residenceFields = [
      FieldMappingModel(
        fieldId: 'state',
        fieldLabel: 'State of Residence',
        fieldLabelHi: 'निवास का राज्य',
        fieldType: FieldType.dropdown,
        options: ['Madhya Pradesh', 'Uttar Pradesh', 'Maharashtra', 'Rajasthan', 'Bihar', 'Gujarat', 'Delhi'],
        mappedValue: answers['state'] ?? 'Madhya Pradesh',
        mappingStatus: MappingStatus.prefilled,
      ),
      FieldMappingModel(
        fieldId: 'district',
        fieldLabel: 'District',
        fieldLabelHi: 'ज़िला',
        mappedValue: answers['district'],
        mappingStatus: answers.containsKey('district') ? MappingStatus.prefilled : MappingStatus.missing,
      ),
    ];

    final financialFields = [
      FieldMappingModel(
        fieldId: 'annualFamilyIncome',
        fieldLabel: 'Annual Family Income (in ₹)',
        fieldLabelHi: 'वार्षिक पारिवारिक आय (₹ में)',
        fieldType: FieldType.number,
        mappedValue: answers['annualIncome'] ?? answers['annualFamilyIncome'],
        mappingStatus: (answers['annualIncome'] != null || answers['annualFamilyIncome'] != null)
            ? MappingStatus.prefilled
            : MappingStatus.missing,
        sourceType: SourceType.userProfile,
      ),
      FieldMappingModel(
        fieldId: 'bankAccountNumber',
        fieldLabel: 'Bank Account Number',
        fieldLabelHi: 'बैंक खाता संख्या',
        mappedValue: answers['bankAccountNumber'],
        mappingStatus: answers.containsKey('bankAccountNumber') ? MappingStatus.prefilled : MappingStatus.missing,
      ),
    ];

    final sections = [
      ApplicationSectionModel(
        sectionId: 'sec_personal',
        title: 'Personal & Demographic Details',
        titleHi: 'व्यक्तिगत और जनसांख्यिकीय विवरण',
        fields: personalFields,
      ),
      ApplicationSectionModel(
        sectionId: 'sec_residence',
        title: 'Address & Residence Details',
        titleHi: 'निवास और पता विवरण',
        fields: residenceFields,
      ),
      ApplicationSectionModel(
        sectionId: 'sec_financial',
        title: 'Income & Bank Details',
        titleHi: 'आय और बैंक विवरण',
        fields: financialFields,
      ),
    ];

    final docs = scheme.requiredDocuments
        .map((docName) => DocumentRequirementModel(
              documentId: docName.toLowerCase().replaceAll(' ', '_'),
              documentName: docName,
              isMandatory: true,
              status: 'missing',
            ))
        .toList();

    return ApplicationSession(
      sessionId: 'local_sess_${scheme.schemeId}',
      schemeId: scheme.schemeId,
      schemeName: scheme.name,
      schemeCategory: scheme.category,
      officialUrl: scheme.applicationUrl ?? scheme.officialSourceUrl,
      interactionMode: (scheme.schemeId == 'PM_KISAN_001' ||
              scheme.schemeId == 'PMAY_G_001' ||
              scheme.schemeId == 'PMAY_U_001' ||
              scheme.schemeId == 'AICTE_PRAGATI_001' ||
              (scheme.applicationUrl != null && scheme.applicationUrl!.contains('pmkisan.gov.in')))
          ? InteractionMode.directWeb
          : InteractionMode.guidedForm,
      status: ApplicationStatus.ready,
      sections: sections,
      documents: docs,
      canSubmit: false,
    );
  }
}

