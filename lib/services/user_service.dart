import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/utils/auth_error_mapper.dart';

/// User service managing Firestore documents in the users collection.
class UserService {
  final FirebaseFirestore? _injectedFirestore;

  UserService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // Fetch profile
  Future<UserModel?> getProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('UserService: getProfile error $e');
      throw const AuthFailure(code: 'database-error', messageKey: 'database-error');
    }
  }

  // Create profile
  Future<void> createProfile(UserModel user) async {
    try {
      final docRef = _usersRef.doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        // Preserve existing
        return;
      }

      final data = user.toMap();
      data['authProvider'] = (user.authProvider == 'password' || user.authProvider == 'email')
          ? 'email'
          : user.authProvider;
      if (user.consentAcceptedAt != null) {
        data['consentAcceptedAt'] = Timestamp.fromDate(user.consentAcceptedAt!);
      }
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);
    } catch (e) {
      debugPrint('UserService: createProfile error $e');
      throw const AuthFailure(code: 'database-error', messageKey: 'database-error');
    }
  }

  // Update profile
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    try {
      final updateData = Map<String, dynamic>.from(fields);
      updateData.remove('uid');
      updateData.remove('createdAt');
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _usersRef.doc(uid).update(updateData);
    } catch (e) {
      debugPrint('UserService: updateProfile error $e');
      throw const AuthFailure(code: 'database-error', messageKey: 'database-error');
    }
  }

  // Delete profile
  Future<void> deleteProfile(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
    } catch (e) {
      debugPrint('UserService: deleteProfile error $e');
      throw const AuthFailure(code: 'database-error', messageKey: 'database-error');
    }
  }

  // Profile stream
  Stream<UserModel?> profileStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserModel.fromMap(snapshot.data()!);
    });
  }
}

