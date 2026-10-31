import 'package:flutter/foundation.dart';
import 'package:sahay/models/user_document_model.dart';
import 'package:sahay/services/document_service.dart';

/// Provider managing the citizen's private document metadata vault.
class UserDocumentProvider extends ChangeNotifier {
  final DocumentService _service;

  List<UserDocumentModel> _documents = [];
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  String? _currentUserId;

  UserDocumentProvider({DocumentService? service})
      : _service = service ?? DocumentService();

  List<UserDocumentModel> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  int get documentCount => _documents.length;

  /// Check whether a document of the given canonical type is uploaded
  bool hasDocument(String canonicalType) {
    final clean = canonicalType.toLowerCase().trim();
    return _documents.any((doc) => doc.documentType.toLowerCase().trim() == clean);
  }

  /// Get the uploaded document for a canonical type
  UserDocumentModel? getDocument(String canonicalType) {
    final clean = canonicalType.toLowerCase().trim();
    try {
      return _documents.firstWhere((doc) => doc.documentType.toLowerCase().trim() == clean);
    } catch (_) {
      return null;
    }
  }

  /// Load user's documents
  Future<void> loadDocuments(String userId) async {
    if (userId.isEmpty) {
      _documents = [];
      _currentUserId = null;
      notifyListeners();
      return;
    }

    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documents = await _service.getUserDocuments(userId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('UserDocumentProvider.loadDocuments error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch document file bytes for preview
  Future<Uint8List?> getDocumentBytes(String storagePath) async {
    return _service.getDocumentBytes(storagePath);
  }

  /// Upload/register a new document in the vault
  Future<bool> uploadDocument({
    required String userId,
    required String documentType,
    required String documentName,
    required String fileName,
    required int fileSize,
    Uint8List? fileBytes,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    _isLoading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final ext = fileName.split('.').last.toLowerCase().replaceAll('.', '').trim();
      final validationError = DocumentService.validateFile(
        fileType: ext,
        fileSize: fileSize,
      );
      if (validationError != null) {
        _errorMessage = validationError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      String storagePath = 'users/$userId/documents/$documentType/$fileName';
      String? downloadUrl;
      Uint8List? cachedBytes = fileBytes;

      if (fileBytes != null) {
        final result = await _service.uploadDocumentFile(
          userId: userId,
          documentType: documentType,
          fileName: fileName,
          fileBytes: fileBytes,
          onProgress: (p) {
            _uploadProgress = p;
            onProgress?.call(p);
            notifyListeners();
          },
        );
        storagePath = result.storagePath;
        downloadUrl = result.downloadUrl;
        cachedBytes = result.fileBytes;
      }

      final docId = '${userId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final newDoc = UserDocumentModel(
        documentId: docId,
        userId: userId,
        documentType: documentType,
        documentName: documentName,
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        fileType: ext,
        fileSize: fileSize,
        uploadedAt: now,
        updatedAt: now,
        verificationStatus: 'uploaded',
        notes: notes,
        cachedBytes: cachedBytes,
      );

      final saved = await _service.saveDocument(newDoc);

      // For standard canonical documents, replace same documentType.
      // For additional/custom documents, allow multiple distinct named documents.
      if (documentType != 'additional_document' && documentType != 'other_document') {
        _documents.removeWhere((d) => d.documentType == documentType);
      } else {
        _documents.removeWhere((d) =>
            d.documentType == documentType &&
            d.documentName.trim().toLowerCase() == documentName.trim().toLowerCase());
      }
      _documents.insert(0, saved);

      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Replace an existing document
  Future<bool> replaceDocument({
    required String documentId,
    required String userId,
    required String documentType,
    required String documentName,
    required String fileName,
    required int fileSize,
    Uint8List? fileBytes,
    String? oldStoragePath,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    _isLoading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final ext = fileName.split('.').last.toLowerCase().replaceAll('.', '').trim();
      final validationError = DocumentService.validateFile(
        fileType: ext,
        fileSize: fileSize,
      );
      if (validationError != null) {
        _errorMessage = validationError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      String storagePath = 'users/$userId/documents/$documentType/$fileName';
      String? downloadUrl;
      Uint8List? cachedBytes = fileBytes;

      // 1. Upload new file first
      if (fileBytes != null) {
        final result = await _service.uploadDocumentFile(
          userId: userId,
          documentType: documentType,
          fileName: fileName,
          fileBytes: fileBytes,
          onProgress: (p) {
            _uploadProgress = p;
            onProgress?.call(p);
            notifyListeners();
          },
        );
        storagePath = result.storagePath;
        downloadUrl = result.downloadUrl;
        cachedBytes = result.fileBytes;
      }

      final now = DateTime.now();
      final updated = UserDocumentModel(
        documentId: documentId,
        userId: userId,
        documentType: documentType,
        documentName: documentName,
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        fileType: ext,
        fileSize: fileSize,
        uploadedAt: now,
        updatedAt: now,
        verificationStatus: 'uploaded',
        notes: notes,
        cachedBytes: cachedBytes,
      );

      // 2. Save metadata to Firestore
      final saved = await _service.saveDocument(updated);

      // 3. Delete old file from storage only after new upload succeeds
      if (oldStoragePath != null && oldStoragePath.isNotEmpty && oldStoragePath != storagePath) {
        await _service.deleteStorageFile(oldStoragePath);
      }

      final index = _documents.indexWhere((d) => d.documentId == documentId);
      if (index >= 0) {
        _documents[index] = saved;
      } else {
        _documents.removeWhere((d) => d.documentType == documentType);
        _documents.insert(0, saved);
      }

      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a document from the vault
  Future<bool> deleteDocument({
    required String userId,
    required String documentId,
    required String documentType,
    String? storagePath,
  }) async {
    try {
      await _service.deleteDocument(userId, documentId, documentType, storagePath: storagePath);
      _documents.removeWhere((d) => d.documentId == documentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear all documents (session wipe or logout)
  void clear() {
    _documents.clear();
    _currentUserId = null;
    _errorMessage = null;
    _isLoading = false;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  /// Reset for test
  @visibleForTesting
  void setDocumentsForTesting(List<UserDocumentModel> docs) {
    _documents = List.from(docs);
    notifyListeners();
  }
}
