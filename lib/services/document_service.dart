import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:sahay/models/user_document_model.dart';

/// Result from uploading a document to storage.
class DocumentUploadResult {
  final String storagePath;
  final String? downloadUrl;
  final Uint8List? fileBytes;
  final String fileName;
  final String fileType;
  final int fileSize;

  const DocumentUploadResult({
    required this.storagePath,
    this.downloadUrl,
    this.fileBytes,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });
}

/// Service managing user document files in Firebase Storage and metadata in Firestore under:
/// `users/{userId}/documents/{documentId}`
class DocumentService {
  final FirebaseFirestore? _injectedFirestore;
  final FirebaseStorage? _injectedStorage;

  // In-memory fallback for testing, offline resilience, and guest mode
  static final Map<String, Map<String, UserDocumentModel>> _memoryStore = {};
  static final Map<String, Uint8List> _fileBytesStore = {};

  DocumentService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _injectedFirestore = firestore,
        _injectedStorage = storage;

  FirebaseFirestore? get _firestore {
    try {
      return _injectedFirestore ?? FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get _storage {
    try {
      return _injectedStorage ?? FirebaseStorage.instance;
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

  /// Upload a document file to Firebase Storage under the private path:
  /// `users/{userId}/documents/{documentType}/{fileName}`
  /// Falls back gracefully to local in-memory storage if Firebase Storage is unavailable.
  Future<DocumentUploadResult> uploadDocumentFile({
    required String userId,
    required String documentType,
    required String fileName,
    required Uint8List fileBytes,
    void Function(double progress)? onProgress,
  }) async {
    final ext = fileName.split('.').last.toLowerCase().replaceAll('.', '').trim();
    final validationError = validateFile(fileType: ext, fileSize: fileBytes.length);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final storagePath = 'users/$userId/documents/$documentType/$sanitizedName';
    String? downloadUrl;

    // Cache locally for resilient preview and offline access
    _fileBytesStore[storagePath] = fileBytes;

    final storage = _storage;
    if (storage != null) {
      try {
        final ref = storage.ref().child(storagePath);
        final mime = ext == 'pdf'
            ? 'application/pdf'
            : (ext == 'png' ? 'image/png' : 'image/jpeg');

        final metadata = SettableMetadata(
          contentType: mime,
          customMetadata: {
            'userId': userId,
            'documentType': documentType,
            'originalFileName': fileName,
          },
        );

        final uploadTask = ref.putData(fileBytes, metadata);
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen((event) {
            if (event.totalBytes > 0) {
              final pct = event.bytesTransferred / event.totalBytes;
              onProgress(pct);
            }
          });
        }

        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint('DocumentService: Storage upload fallback notice ($e)');
        onProgress?.call(1.0);
      }
    } else {
      onProgress?.call(1.0);
    }

    return DocumentUploadResult(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      fileBytes: fileBytes,
      fileName: sanitizedName,
      fileType: ext,
      fileSize: fileBytes.length,
    );
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteStorageFile(String storagePath) async {
    if (storagePath.isEmpty) return;
    _fileBytesStore.remove(storagePath);
    final storage = _storage;
    if (storage != null) {
      try {
        final ref = storage.ref().child(storagePath);
        await ref.delete();
      } catch (e) {
        debugPrint('DocumentService: Storage delete non-fatal error ($e)');
      }
    }
  }

  /// Retrieve file bytes from cache or Firebase Storage
  Future<Uint8List?> getDocumentBytes(String storagePath) async {
    if (storagePath.isEmpty) return null;
    if (_fileBytesStore.containsKey(storagePath)) {
      return _fileBytesStore[storagePath];
    }

    final storage = _storage;
    if (storage != null) {
      try {
        final ref = storage.ref().child(storagePath);
        final data = await ref.getData(maxFileSizeBytes);
        if (data != null) {
          _fileBytesStore[storagePath] = data;
          return data;
        }
      } catch (e) {
        debugPrint('DocumentService: getDocumentBytes error ($e)');
      }
    }
    return null;
  }

  /// Fetch all documents owned by user
  Future<List<UserDocumentModel>> getUserDocuments(String userId) async {
    if (userId.isEmpty) return [];

    final ref = _documentsRef(userId);
    if (ref != null) {
      try {
        final querySnapshot = await ref.orderBy('uploadedAt', descending: true).get();
        final docs = querySnapshot.docs.map((doc) {
          final model = UserDocumentModel.fromMap(doc.data(), doc.id);
          // Attach cached bytes if available
          if (_fileBytesStore.containsKey(model.storagePath)) {
            return model.copyWith(cachedBytes: _fileBytesStore[model.storagePath]);
          }
          return model;
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
          final fullModel = _fileBytesStore.containsKey(model.storagePath)
              ? model.copyWith(cachedBytes: _fileBytesStore[model.storagePath])
              : model;
          _memoryStore.putIfAbsent(userId, () => {})[documentType] = fullModel;
          return fullModel;
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

  /// Delete document by ID and canonical type
  Future<void> deleteDocument(String userId, String documentId, String documentType, {String? storagePath}) async {
    if (userId.isEmpty) return;

    final doc = _memoryStore[userId]?.remove(documentType);
    final targetPath = storagePath ?? doc?.storagePath;
    if (targetPath != null && targetPath.isNotEmpty) {
      await deleteStorageFile(targetPath);
    }

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

    final docs = _memoryStore.remove(userId)?.values.toList() ?? [];
    for (final doc in docs) {
      if (doc.storagePath.isNotEmpty) {
        await deleteStorageFile(doc.storagePath);
      }
    }

    final ref = _documentsRef(userId);
    if (ref != null) {
      try {
        final snapshots = await ref.get();
        for (final doc in snapshots.docs) {
          final data = doc.data();
          final path = data['storagePath']?.toString();
          if (path != null && path.isNotEmpty) {
            await deleteStorageFile(path);
          }
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
    _fileBytesStore.clear();
  }
}
