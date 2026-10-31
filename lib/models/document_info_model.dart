/// Represents educational guide and metadata for a canonical document type.
class DocumentInfoModel {
  final String documentType; // e.g. 'aadhaar_card'
  final String displayName; // e.g. 'Aadhaar Card'
  final String displayNameHindi; // e.g. 'आधार कार्ड'
  final String category; // 'Identity', 'Address', 'Income', 'Land', 'Education', 'Banking', 'Other'
  final String categoryHindi;
  final String description;
  final String descriptionHindi;
  final String purpose;
  final String purposeHindi;
  final List<String> provesInfo; // List of facts proven (e.g. 'Identity', 'Age/DOB')
  final List<String> provesInfoHindi;
  final String issuingAuthority;
  final String issuingAuthorityHindi;
  final List<String> howToObtain;
  final List<String> howToObtainHindi;
  final List<String> importantChecks;
  final List<String> importantChecksHindi;
  final String specimenTitle;
  final String specimenDescription;
  final List<String> acceptedFormats;
  final int maxSizeBytes;

  const DocumentInfoModel({
    required this.documentType,
    required this.displayName,
    required this.displayNameHindi,
    required this.category,
    required this.categoryHindi,
    required this.description,
    required this.descriptionHindi,
    required this.purpose,
    required this.purposeHindi,
    required this.provesInfo,
    required this.provesInfoHindi,
    required this.issuingAuthority,
    required this.issuingAuthorityHindi,
    required this.howToObtain,
    required this.howToObtainHindi,
    required this.importantChecks,
    required this.importantChecksHindi,
    required this.specimenTitle,
    required this.specimenDescription,
    this.acceptedFormats = const ['PDF', 'JPG', 'PNG'],
    this.maxSizeBytes = 5 * 1024 * 1024, // 5 MB
  });
}

