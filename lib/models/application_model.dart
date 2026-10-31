import 'package:flutter/foundation.dart';

enum ApplicationStatus {
  preparing,
  ready,
  inProgress,
  fillingPortal,
  awaitingUserInput,
  awaitingConfirmation,
  validationRequired,
  readyForReview,
  readyForSubmission,
  submittedConfirmed,
  cancelled,
  failed,
}

enum FieldType {
  text,
  number,
  date,
  radio,
  checkbox,
  dropdown,
  address,
  phone,
  email,
  document,
}

enum MappingStatus {
  prefilled,
  userConfirmed,
  missing,
  conflict,
  invalid,
  ready,
}

enum SourceType {
  userProfile,
  uploadedDocument,
  userInput,
  officialPortal,
}

enum ReadBackFieldStatus {
  filledVerified,
  filledUnverified,
  manualActionRequired,
  failed,
  missing,
}

// Backward-compatibility alias
enum InteractionMode {
  directWeb,
  guidedForm,
}

// ==========================================
// Central 10-Scheme Registry Model
// ==========================================

class SchemeRegistryEntryModel {
  final String schemeId;
  final String schemeName;
  final List<String> alternateNames;
  final String category;
  final String stateOrCentral;
  final String officialSchemeUrl;
  final String officialApplicationUrl;
  final String applicationMode;
  final String portalDomain;
  final String adapterId;
  final List<String> supportedFields;
  final List<String> requiredDocuments;
  final String authenticationRequirements;
  final List<String> manualInterventionRequirements;
  final String portalCompatibilityStatus;
  final String lastTestedAt;
  final String lastVerifiedAt;
  final String applicationAvailabilityStatus;
  final List<String> knownLimitations;

  SchemeRegistryEntryModel({
    required this.schemeId,
    required this.schemeName,
    this.alternateNames = const [],
    required this.category,
    this.stateOrCentral = 'central',
    required this.officialSchemeUrl,
    required this.officialApplicationUrl,
    this.applicationMode = 'smart_filler',
    required this.portalDomain,
    required this.adapterId,
    this.supportedFields = const [],
    this.requiredDocuments = const [],
    required this.authenticationRequirements,
    this.manualInterventionRequirements = const [],
    this.portalCompatibilityStatus = 'fully_supported',
    this.lastTestedAt = '',
    this.lastVerifiedAt = '',
    this.applicationAvailabilityStatus = 'active_accepting_applications',
    this.knownLimitations = const [],
  });

  factory SchemeRegistryEntryModel.fromMap(Map<String, dynamic> map) {
    return SchemeRegistryEntryModel(
      schemeId: map['schemeId']?.toString() ?? '',
      schemeName: map['schemeName']?.toString() ?? '',
      alternateNames: (map['alternateNames'] as List?)?.map((e) => e.toString()).toList() ?? [],
      category: map['category']?.toString() ?? '',
      stateOrCentral: map['stateOrCentral']?.toString() ?? 'central',
      officialSchemeUrl: map['officialSchemeUrl']?.toString() ?? '',
      officialApplicationUrl: map['officialApplicationUrl']?.toString() ?? '',
      applicationMode: map['applicationMode']?.toString() ?? 'smart_filler',
      portalDomain: map['portalDomain']?.toString() ?? '',
      adapterId: map['adapterId']?.toString() ?? '',
      supportedFields: (map['supportedFields'] as List?)?.map((e) => e.toString()).toList() ?? [],
      requiredDocuments: (map['requiredDocuments'] as List?)?.map((e) => e.toString()).toList() ?? [],
      authenticationRequirements: map['authenticationRequirements']?.toString() ?? '',
      manualInterventionRequirements: (map['manualInterventionRequirements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      portalCompatibilityStatus: map['portalCompatibilityStatus']?.toString() ?? 'fully_supported',
      lastTestedAt: map['lastTestedAt']?.toString() ?? '',
      lastVerifiedAt: map['lastVerifiedAt']?.toString() ?? '',
      applicationAvailabilityStatus: map['applicationAvailabilityStatus']?.toString() ?? 'active_accepting_applications',
      knownLimitations: (map['knownLimitations'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

// ==========================================
// Value Provenance & Field Mapping Models
// ==========================================

class ValueProvenanceModel {
  final String field;
  final dynamic value;
  final String source;
  final String verificationStatus;
  final String? sourceDocumentId;
  final String lastUpdatedAt;

  ValueProvenanceModel({
    required this.field,
    this.value,
    required this.source,
    this.verificationStatus = 'self_reported',
    this.sourceDocumentId,
    required this.lastUpdatedAt,
  });

  factory ValueProvenanceModel.fromMap(Map<String, dynamic> map) {
    return ValueProvenanceModel(
      field: map['field']?.toString() ?? '',
      value: map['value'],
      source: map['source']?.toString() ?? 'user_profile',
      verificationStatus: map['verification_status']?.toString() ?? 'self_reported',
      sourceDocumentId: map['source_document_id']?.toString(),
      lastUpdatedAt: map['last_updated_at']?.toString() ?? '',
    );
  }
}

class FieldMappingModel {
  final String fieldId;
  final String fieldLabel;
  final String? fieldLabelHi;
  final FieldType fieldType;
  final bool isRequired;
  final List<String>? options;
  dynamic mappedValue;
  final SourceType? sourceType;
  final String? sourceDocumentId;
  final double confidence;
  MappingStatus mappingStatus;
  bool userConfirmed;
  String validationStatus;
  String? validationError;
  final String? explanation;
  final String? explanationHi;
  final String? explanationHinglish;
  final bool conflictDetected;
  final Map<String, dynamic>? conflictDetails;
  final ValueProvenanceModel? provenance;
  final String? portalSelector;
  ReadBackFieldStatus? readBackStatus;

  FieldMappingModel({
    required this.fieldId,
    required this.fieldLabel,
    this.fieldLabelHi,
    this.fieldType = FieldType.text,
    this.isRequired = true,
    this.options,
    this.mappedValue,
    this.sourceType,
    this.sourceDocumentId,
    this.confidence = 1.0,
    this.mappingStatus = MappingStatus.missing,
    this.userConfirmed = false,
    this.validationStatus = 'pending',
    this.validationError,
    this.explanation,
    this.explanationHi,
    this.explanationHinglish,
    this.conflictDetected = false,
    this.conflictDetails,
    this.provenance,
    this.portalSelector,
    this.readBackStatus,
  });

  factory FieldMappingModel.fromMap(Map<String, dynamic> map) {
    return FieldMappingModel(
      fieldId: map['field_id']?.toString() ?? '',
      fieldLabel: map['field_label']?.toString() ?? '',
      fieldLabelHi: map['field_label_hi']?.toString(),
      fieldType: _parseFieldType(map['field_type']),
      isRequired: map['is_required'] as bool? ?? true,
      options: (map['options'] as List?)?.map((e) => e.toString()).toList(),
      mappedValue: map['mapped_value'],
      sourceType: _parseSourceType(map['source_type']),
      sourceDocumentId: map['source_document_id']?.toString(),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      mappingStatus: _parseMappingStatus(map['mapping_status']),
      userConfirmed: map['user_confirmed'] as bool? ?? false,
      validationStatus: map['validation_status']?.toString() ?? 'pending',
      validationError: map['validation_error']?.toString(),
      explanation: map['explanation']?.toString(),
      explanationHi: map['explanation_hi']?.toString(),
      explanationHinglish: map['explanation_hinglish']?.toString(),
      conflictDetected: map['conflict_detected'] as bool? ?? false,
      conflictDetails: map['conflict_details'] is Map ? Map<String, dynamic>.from(map['conflict_details'] as Map) : null,
      provenance: map['provenance'] is Map ? ValueProvenanceModel.fromMap(Map<String, dynamic>.from(map['provenance'] as Map)) : null,
      portalSelector: map['portal_selector']?.toString(),
      readBackStatus: _parseReadBackStatus(map['read_back_status']),
    );
  }

  static FieldType _parseFieldType(dynamic val) {
    final str = val?.toString().toLowerCase() ?? '';
    switch (str) {
      case 'number':
        return FieldType.number;
      case 'date':
        return FieldType.date;
      case 'radio':
        return FieldType.radio;
      case 'checkbox':
        return FieldType.checkbox;
      case 'dropdown':
        return FieldType.dropdown;
      case 'address':
        return FieldType.address;
      case 'phone':
        return FieldType.phone;
      case 'email':
        return FieldType.email;
      case 'document':
        return FieldType.document;
      default:
        return FieldType.text;
    }
  }

  static SourceType? _parseSourceType(dynamic val) {
    final str = val?.toString().toLowerCase() ?? '';
    if (str.contains('profile')) return SourceType.userProfile;
    if (str.contains('doc')) return SourceType.uploadedDocument;
    if (str.contains('input')) return SourceType.userInput;
    if (str.contains('portal')) return SourceType.officialPortal;
    return null;
  }

  static MappingStatus _parseMappingStatus(dynamic val) {
    final str = val?.toString().toLowerCase() ?? '';
    if (str.contains('prefill')) return MappingStatus.prefilled;
    if (str.contains('confirm')) return MappingStatus.userConfirmed;
    if (str.contains('conflict')) return MappingStatus.conflict;
    if (str.contains('invalid')) return MappingStatus.invalid;
    if (str.contains('ready')) return MappingStatus.ready;
    return MappingStatus.missing;
  }

  static ReadBackFieldStatus? _parseReadBackStatus(dynamic val) {
    final str = val?.toString().toLowerCase() ?? '';
    if (str.contains('filled_verified')) return ReadBackFieldStatus.filledVerified;
    if (str.contains('filled_unverified')) return ReadBackFieldStatus.filledUnverified;
    if (str.contains('manual_action')) return ReadBackFieldStatus.manualActionRequired;
    if (str.contains('failed')) return ReadBackFieldStatus.failed;
    if (str.contains('missing')) return ReadBackFieldStatus.missing;
    return null;
  }
}

class ApplicationSectionModel {
  final String sectionId;
  final String title;
  final String? titleHi;
  final String? description;
  final List<FieldMappingModel> fields;

  ApplicationSectionModel({
    required this.sectionId,
    required this.title,
    this.titleHi,
    this.description,
    required this.fields,
  });

  factory ApplicationSectionModel.fromMap(Map<String, dynamic> map) {
    final rawFields = map['fields'] as List? ?? [];
    return ApplicationSectionModel(
      sectionId: map['section_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      titleHi: map['title_hi']?.toString(),
      description: map['description']?.toString(),
      fields: rawFields
          .map((f) => FieldMappingModel.fromMap(Map<String, dynamic>.from(f as Map)))
          .toList(),
    );
  }
}

class DocumentRequirementModel {
  final String documentId;
  final String documentName;
  final String? documentNameHi;
  final bool isMandatory;
  String status;
  final Map<String, dynamic>? extractedInfo;

  DocumentRequirementModel({
    required this.documentId,
    required this.documentName,
    this.documentNameHi,
    this.isMandatory = true,
    this.status = 'missing',
    this.extractedInfo,
  });

  factory DocumentRequirementModel.fromMap(Map<String, dynamic> map) {
    return DocumentRequirementModel(
      documentId: map['document_id']?.toString() ?? '',
      documentName: map['document_name']?.toString() ?? '',
      documentNameHi: map['document_name_hi']?.toString(),
      isMandatory: map['is_mandatory'] as bool? ?? true,
      status: map['status']?.toString() ?? 'missing',
      extractedInfo: map['extracted_info'] is Map ? Map<String, dynamic>.from(map['extracted_info'] as Map) : null,
    );
  }
}

// ==========================================
// Read-Back Verification Models
// ==========================================

class ReadBackFieldItemModel {
  final String fieldId;
  final String selector;
  final dynamic expectedValue;
  final dynamic readValue;
  final ReadBackFieldStatus status;
  final String? message;

  ReadBackFieldItemModel({
    required this.fieldId,
    required this.selector,
    this.expectedValue,
    this.readValue,
    required this.status,
    this.message,
  });

  factory ReadBackFieldItemModel.fromMap(Map<String, dynamic> map) {
    return ReadBackFieldItemModel(
      fieldId: map['field_id']?.toString() ?? '',
      selector: map['selector']?.toString() ?? '',
      expectedValue: map['expected_value'],
      readValue: map['read_value'],
      status: FieldMappingModel._parseReadBackStatus(map['status']) ?? ReadBackFieldStatus.missing,
      message: map['message']?.toString(),
    );
  }
}

class ReadBackVerificationReportModel {
  final int totalFields;
  final int verifiedCount;
  final int unverifiedCount;
  final int manualActionCount;
  final int failedCount;
  final bool canProceedToReview;
  final List<ReadBackFieldItemModel> items;

  ReadBackVerificationReportModel({
    required this.totalFields,
    required this.verifiedCount,
    required this.unverifiedCount,
    this.manualActionCount = 0,
    this.failedCount = 0,
    required this.canProceedToReview,
    this.items = const [],
  });

  factory ReadBackVerificationReportModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? [];
    return ReadBackVerificationReportModel(
      totalFields: map['total_fields'] as int? ?? 0,
      verifiedCount: map['verified_count'] as int? ?? 0,
      unverifiedCount: map['unverified_count'] as int? ?? 0,
      manualActionCount: map['manual_action_count'] as int? ?? 0,
      failedCount: map['failed_count'] as int? ?? 0,
      canProceedToReview: map['can_proceed_to_review'] as bool? ?? false,
      items: rawItems
          .map((i) => ReadBackFieldItemModel.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}

class PortalPopulationPayloadModel {
  final String portalId;
  final String portalDomain;
  final List<Map<String, dynamic>> declarativeInstructions;
  final List<Map<String, dynamic>> readBackSelectors;
  final List<String> manualInterventionRequired;

  PortalPopulationPayloadModel({
    required this.portalId,
    required this.portalDomain,
    this.declarativeInstructions = const [],
    this.readBackSelectors = const [],
    this.manualInterventionRequired = const [],
  });

  factory PortalPopulationPayloadModel.fromMap(Map<String, dynamic> map) {
    return PortalPopulationPayloadModel(
      portalId: map['portal_id']?.toString() ?? '',
      portalDomain: map['portal_domain']?.toString() ?? '',
      declarativeInstructions: (map['declarative_instructions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      readBackSelectors: (map['read_back_selectors'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      manualInterventionRequired: (map['manual_intervention_required'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// ==========================================
// Application Session Master Model
// ==========================================

class ApplicationSession {
  final String sessionId;
  final String schemeId;
  final String schemeName;
  final String schemeCategory;
  final String? officialUrl;
  final InteractionMode interactionMode;
  final String? portalAdapterId;
  ApplicationStatus status;
  final List<ApplicationSectionModel> sections;
  final List<DocumentRequirementModel> documents;
  int missingFieldsCount;
  int conflictsCount;
  List<String> validationErrors;
  List<String> warnings;
  bool canSubmit;
  bool submissionConfirmed;
  String? submissionReference;
  ReadBackVerificationReportModel? readBackReport;

  ApplicationSession({
    required this.sessionId,
    required this.schemeId,
    required this.schemeName,
    required this.schemeCategory,
    this.officialUrl,
    this.interactionMode = InteractionMode.guidedForm,
    this.portalAdapterId,
    required this.status,
    required this.sections,
    required this.documents,
    this.missingFieldsCount = 0,
    this.conflictsCount = 0,
    this.validationErrors = const [],
    this.warnings = const [],
    this.canSubmit = false,
    this.submissionConfirmed = false,
    this.submissionReference,
    this.readBackReport,
  });

  factory ApplicationSession.fromMap(Map<String, dynamic> map) {
    final rawSections = map['sections'] as List? ?? [];
    final rawDocs = map['documents'] as List? ?? [];

    return ApplicationSession(
      sessionId: map['session_id']?.toString() ?? '',
      schemeId: map['scheme_id']?.toString() ?? '',
      schemeName: map['scheme_name']?.toString() ?? '',
      schemeCategory: map['scheme_category']?.toString() ?? '',
      officialUrl: map['official_application_url']?.toString(),
      interactionMode: InteractionMode.guidedForm,
      portalAdapterId: map['portal_adapter_id']?.toString(),
      status: _parseAppStatus(map['status']),
      sections: rawSections
          .map((s) => ApplicationSectionModel.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      documents: rawDocs
          .map((d) => DocumentRequirementModel.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList(),
      missingFieldsCount: map['missing_fields_count'] as int? ?? 0,
      conflictsCount: map['conflicts_count'] as int? ?? 0,
      validationErrors: (map['validation_errors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      warnings: (map['warnings'] as List?)?.map((e) => e.toString()).toList() ?? [],
      canSubmit: map['can_submit'] as bool? ?? false,
      submissionConfirmed: map['submission_confirmed'] as bool? ?? false,
      submissionReference: map['submission_reference']?.toString(),
      readBackReport: map['read_back_report'] is Map
          ? ReadBackVerificationReportModel.fromMap(Map<String, dynamic>.from(map['read_back_report'] as Map))
          : null,
    );
  }

  static ApplicationStatus _parseAppStatus(dynamic val) {
    final str = val?.toString().toLowerCase() ?? '';
    if (str.contains('submit')) return ApplicationStatus.submittedConfirmed;
    if (str.contains('ready_for_rev')) return ApplicationStatus.readyForReview;
    if (str.contains('filling')) return ApplicationStatus.fillingPortal;
    if (str.contains('valid')) return ApplicationStatus.validationRequired;
    if (str.contains('awaiting_user')) return ApplicationStatus.awaitingUserInput;
    if (str.contains('ready')) return ApplicationStatus.ready;
    return ApplicationStatus.inProgress;
  }
}
