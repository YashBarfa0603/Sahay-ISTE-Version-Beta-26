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
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'age': age,
      'state': state,
      'district': district,
      'occupation': occupation,
      'preferredLanguage': preferredLanguage,
      'gender': gender,
      'residenceType': residenceType,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      age: map['age'],
      state: map['state'],
      district: map['district'],
      occupation: map['occupation'],
      preferredLanguage: map['preferredLanguage'],
      gender: map['gender'],
      residenceType: map['residenceType'],
    );
  }

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
      preferredLanguage:
          preferredLanguage ?? this.preferredLanguage,
      gender: gender ?? this.gender,
      residenceType: residenceType ?? this.residenceType,
    );
  }
}