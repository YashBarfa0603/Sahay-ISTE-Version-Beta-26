import 'package:flutter/foundation.dart';
import 'package:sahay/models/user_model.dart';

class UserProfileProvider extends ChangeNotifier {
  final Map<String, dynamic> _answers = <String, dynamic>{};

  Map<String, dynamic> get answers => Map.unmodifiable(_answers);
  int get answeredCount => _answers.length;
  bool get hasAnswers => _answers.isNotEmpty;

  // Set answer
  void setAnswer(String field, dynamic value) {
    if (value == null) {
      if (_answers.containsKey(field)) {
        _answers.remove(field);
        notifyListeners();
      }
      return;
    }

    if (_answers[field] != value) {
      _answers[field] = value;
      notifyListeners();
    }
  }

  // Set bulk
  void setAnswers(Map<String, dynamic> newAnswers) {
    bool hasChange = false;
    newAnswers.forEach((key, value) {
      if (value != null && _answers[key] != value) {
        _answers[key] = value;
        hasChange = true;
      } else if (value == null && _answers.containsKey(key)) {
        _answers.remove(key);
        hasChange = true;
      }
    });

    if (hasChange) {
      notifyListeners();
    }
  }

  // Get answer
  dynamic getAnswer(String field) {
    return _answers[field];
  }

  T? getTypedAnswer<T>(String field) {
    final val = _answers[field];
    if (val is T) return val;
    return null;
  }

  bool hasAnswer(String field) {
    return _answers.containsKey(field) && _answers[field] != null;
  }

  void removeAnswer(String field) {
    if (_answers.containsKey(field)) {
      _answers.remove(field);
      notifyListeners();
    }
  }

  // Reset
  void clearAllAnswers() {
    if (_answers.isNotEmpty) {
      _answers.clear();
      notifyListeners();
    }
  }

  // User mapping
  void populateFromUser(UserModel user) {
    final userMap = user.toMap();
    userMap.forEach((key, value) {
      if (value != null && key != 'uid') {
        _answers[key] = value;
      }
    });
    notifyListeners();
  }

  UserModel toUserModel({String? uid, String? fullName, String? email, String? mobileNumber}) {
    return UserModel(
      uid: uid ?? _answers['uid']?.toString() ?? 'anonymous_session',
      fullName: fullName ?? _answers['fullName']?.toString() ?? 'Citizen User',
      email: email ?? _answers['email']?.toString() ?? '',
      mobileNumber: mobileNumber ?? _answers['mobileNumber']?.toString() ?? '',
      age: _answers['age'] is int ? _answers['age'] as int : int.tryParse(_answers['age']?.toString() ?? ''),
      state: _answers['state']?.toString(),
      district: _answers['district']?.toString(),
      occupation: _answers['occupation']?.toString(),
      preferredLanguage: _answers['preferredLanguage']?.toString(),
      gender: _answers['gender']?.toString(),
      residenceType: _answers['residenceType']?.toString(),
    );
  }
}
