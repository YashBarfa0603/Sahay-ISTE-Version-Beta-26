// User model
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String mobileNumber;

  final int? age;
  final String? state;
  final String? district;
  final String? occupation;
  final String? preferredLanguage;
  final String? gender;
  final String? residenceType;

  final bool profileComplete;
  final String authProvider;
  final DateTime? consentAcceptedAt;
  final String? consentVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Constructor
  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    this.age,
    this.state,
    this.district,
    this.occupation,
    this.preferredLanguage,
    this.gender,
    this.residenceType,
    this.profileComplete = false,
    this.authProvider = 'password',
    this.consentAcceptedAt,
    this.consentVersion,
    this.createdAt,
    this.updatedAt,
  });

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email.toLowerCase().trim(),
      'mobileNumber': mobileNumber,
      'age': age,
      'state': state,
      'district': district,
      'occupation': occupation,
      'preferredLanguage': preferredLanguage,
      'gender': gender,
      'residenceType': residenceType,
      'profileComplete': profileComplete,
      'authProvider': authProvider,
      'consentAcceptedAt': consentAcceptedAt?.toIso8601String(),
      'consentVersion': consentVersion ?? '1.0',
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Deserialization
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: (map['email']?.toString() ?? '').toLowerCase().trim(),
      mobileNumber: map['mobileNumber']?.toString() ?? '',
      age: map['age'] is int
          ? map['age'] as int
          : int.tryParse(map['age']?.toString() ?? ''),
      state: map['state']?.toString(),
      district: map['district']?.toString(),
      occupation: map['occupation']?.toString(),
      preferredLanguage: map['preferredLanguage']?.toString(),
      gender: map['gender']?.toString(),
      residenceType: map['residenceType']?.toString(),
      profileComplete: map['profileComplete'] is bool
          ? map['profileComplete'] as bool
          : (map['profileComplete'] == 'true' || map['profileComplete'] == 1),
      authProvider: map['authProvider']?.toString() ?? 'password',
      consentAcceptedAt: _parseDateTime(map['consentAcceptedAt']),
      consentVersion: map['consentVersion']?.toString() ?? '1.0',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  // Helper
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      final dynamic dyn = value;
      if (dyn.toDate != null) {
        return dyn.toDate() as DateTime;
      }
    } catch (_) {}
    return null;
  }

  // Copy
  UserModel copyWith({
    String? fullName,
    String? mobileNumber,
    int? age,
    String? state,
    String? district,
    String? occupation,
    String? preferredLanguage,
    String? gender,
    String? residenceType,
    bool? profileComplete,
    String? authProvider,
    DateTime? consentAcceptedAt,
    String? consentVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      age: age ?? this.age,
      state: state ?? this.state,
      district: district ?? this.district,
      occupation: occupation ?? this.occupation,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      gender: gender ?? this.gender,
      residenceType: residenceType ?? this.residenceType,
      profileComplete: profileComplete ?? this.profileComplete,
      authProvider: authProvider ?? this.authProvider,
      consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
      consentVersion: consentVersion ?? this.consentVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
