import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sahay/models/user_document_model.dart';

/// Service managing user document metadata stored in Firestore under:
/// `users/{userId}/documents/{documentId}`
class DocumentService {
  final FirebaseFirestore? _injectedFirestore;

  // In-memory fallback for testing, offline resilience, and guest mode
  static final Map<String, Map<String, UserDocumentModel>> _memoryStore = {};

  DocumentService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore? get _firestore {
    try {
      return _injectedFirestore ?? FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const Set<String> allowedExtensions = {'pdf', 'jpg', 'jpeg', 'png'};

  /// Validate document file properties before uploading
  static String? validateFile({
    required String fileType,
    required int fileSize,
  }) {
    final cleanType = fileType.toLowerCase().replaceAll('.', '').trim();
    if (!allowedExtensions.contains(cleanType)) {
      return 'Unsupported file format ($fileType). Only PDF, JPG, and PNG are accepted.';
    }
    if (fileSize <= 0) {
      return 'File appears to be empty.';
    }
    if (fileSize > maxFileSizeBytes) {
      final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      return 'File size ($sizeMb MB) exceeds the maximum allowed limit of 5.0 MB.';
    }
    return null;
  }

  /// Reference to user's documents subcollection
  CollectionReference<Map<String, dynamic>>? _documentsRef(String userId) {
    final fs = _firestore;
    if (fs == null) return null;
    return fs.collection('users').doc(userId).collection('documents');
  }

  /// Fetch all documents owned by user
  Future<List<UserDocumentModel>> getUserDocuments(String userId) async {
    if (userId.isEmpty) return [];

    final ref = _documentsRef(userId);
    if (ref != null) {
      try {
        final querySnapshot = await ref.orderBy('uploadedAt', descending: true).get();
        final docs = querySnapshot.docs.map((doc) {
          return UserDocumentModel.fromMap(doc.data(), doc.id);
        }).toList();

        // Sync with local memory cache
        _memoryStore[userId] = {
          for (final d in docs) d.documentType: d,
        };
        return docs;
      } catch (e) {
        debugPrint('DocumentService: Firestore fetch error ($e), falling back to cache');
      }
    }

    // Fallback to local memory store
    final userDocs = _memoryStore[userId]?.values.toList() ?? [];
    userDocs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return userDocs;
  }

  /// Get document by canonical type
  Future<UserDocumentModel?> getDocument(String userId, String documentType) async {
    if (userId.isEmpty) return null;

    final ref = _documentsRef(userId);
    if (ref != null) {
      try {
        final query = await ref
            .where('documentType', isEqualTo: documentType)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final model = UserDocumentModel.fromMap(doc.data(), doc.id);
          _memoryStore.putIfAbsent(userId, () => {})[documentType] = model;
          return model;
        }
      } catch (e) {
        debugPrint('DocumentService: getDocument error ($e)');
      }
    }

    return _memoryStore[userId]?[documentType];
  }

  /// Save or update document metadata
  Future<UserDocumentModel> saveDocument(UserDocumentModel doc) async {
    final validationError = validateFile(
      fileType: doc.fileType,
      fileSize: doc.fileSize,
    );
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    // Update memory store
    _memoryStore.putIfAbsent(doc.userId, () => {})[doc.documentType] = doc;

    final ref = _documentsRef(doc.userId);
    if (ref != null) {
      try {
        final docRef = ref.doc(doc.documentId);
        await docRef.set(doc.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('DocumentService: Firestore save non-fatal error ($e)');
      }
    }

    return doc;
  }

  /// Delete document by ID
  Future<void> deleteDocument(String userId, String documentId, String documentType) async {
    if (userId.isEmpty) return;

    _memoryStore[userId]?.remove(documentType);

    final ref = _documentsRef(userId);
    if (ref != null) {
      try {
        await ref.doc(documentId).delete();
      } catch (e) {
        debugPrint('DocumentService: Firestore delete error ($e)');
      }
    }
  }

  /// Clear all documents for a user (Privacy / Zero retention / Account Deletion)
  Future<void> deleteAllUserDocuments(String userId) async {
    if (userId.isEmpty) return;

    _memoryStore.remove(userId);

    final ref = _documentsRef(userId);
    if (ref != null) {
      try {
        final snapshots = await ref.get();
        for (final doc in snapshots.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('DocumentService: deleteAllUserDocuments error ($e)');
      }
    }
  }

  /// Reset memory store (for testing)
  @visibleForTesting
  static void clearMemoryStore() {
    _memoryStore.clear();
  }
}

