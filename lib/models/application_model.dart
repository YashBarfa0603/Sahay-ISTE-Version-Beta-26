import 'package:flutter/foundation.dart';

enum InteractionMode {
  directWeb,
  guidedForm,
}

enum ApplicationStatus {
  preparing,
  ready,
  inProgress,
  awaitingUserInput,
  awaitingConfirmation,
  validationRequired,
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
  List<String> validationErrors;
  List<String> warnings;
  bool canSubmit;
  bool submissionConfirmed;
  String? submissionReference;

  ApplicationSession({
    required this.sessionId,
    required this.schemeId,
    required this.schemeName,
    required this.schemeCategory,
    this.officialUrl,
    required this.interactionMode,
    this.portalAdapterId,
    required this.status,
    required this.sections,
    required this.documents,
    this.validationErrors = const [],
    this.warnings = const [],
    this.canSubmit = false,
    this.submissionConfirmed = false,
    this.submissionReference,
  });

  factory ApplicationSession.fromMap(Map<String, dynamic> map) {
    final rawSections = map['sections'] as List? ?? [];
    final rawDocs = map['documents'] as List? ?? [];
    final modeStr = map['interaction_mode']?.toString().toLowerCase() ?? '';

    return ApplicationSession(
      sessionId: map['session_id']?.toString() ?? '',
      schemeId: map['scheme_id']?.toString() ?? '',
      schemeName: map['scheme_name']?.toString() ?? '',
      schemeCategory: map['scheme_category']?.toString() ?? '',
      officialUrl: map['official_application_url']?.toString(),
      interactionMode: modeStr.contains('web') ? InteractionMode.directWeb : InteractionMode.guidedForm,
      portalAdapterId: map['portal_adapter_id']?.toString(),
      status: _parseAppStatus(map['status']),
      sections: rawSections
          .map((s) => ApplicationSectionModel.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      documents: rawDocs
          .map((d) => DocumentRequirementModel.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList(),
      validationErrors: (map['validation_errors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      warnings: (map['warnings'] as List?)?.map((e) => e.toString()).toList() ?? [],
      canSubmit: map['can_submit'] as bool? ?? false,
      submissionConfirmed: map['submission_confirmed'] as bool? ?? false,
      submissionReference: map['submission_reference']?.toString(),
    );
  }

  static ApplicationStatus _parseAppStatus(dynamic val) {
    final str = val?.toString().toLowerCase() ?? '';
    if (str.contains('submit')) return ApplicationStatus.submittedConfirmed;
    if (str.contains('ready_for_sub')) return ApplicationStatus.readyForSubmission;
    if (str.contains('valid')) return ApplicationStatus.validationRequired;
    if (str.contains('progress')) return ApplicationStatus.inProgress;
    if (str.contains('ready')) return ApplicationStatus.ready;
    return ApplicationStatus.inProgress;
  }
}

