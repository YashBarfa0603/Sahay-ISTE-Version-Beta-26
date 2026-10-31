import 'package:flutter/foundation.dart';
import 'package:sahay/models/user_document_model.dart';
import 'package:sahay/services/document_service.dart';

/// Provider managing the citizen's private document metadata vault.
class UserDocumentProvider extends ChangeNotifier {
  final DocumentService _service;

  List<UserDocumentModel> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  UserDocumentProvider({DocumentService? service})
      : _service = service ?? DocumentService();

  List<UserDocumentModel> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
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

  /// Upload/register a new document in the vault
  Future<bool> uploadDocument({
    required String userId,
    required String documentType,
    required String documentName,
    required String fileName,
    required int fileSize,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ext = fileName.split('.').last.toLowerCase();
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

      final docId = '${userId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final storagePath = 'users/$userId/documents/$docId.$ext';

      final newDoc = UserDocumentModel(
        documentId: docId,
        userId: userId,
        documentType: documentType,
        documentName: documentName,
        storagePath: storagePath,
        downloadUrl: null,
        fileType: ext,
        fileSize: fileSize,
        uploadedAt: now,
        updatedAt: now,
        verificationStatus: 'uploaded',
        notes: notes,
      );

      final saved = await _service.saveDocument(newDoc);

      // Remove any existing doc of same type and add newly uploaded one
      _documents.removeWhere((d) => d.documentType == documentType);
      _documents.insert(0, saved);

      _isLoading = false;
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
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ext = fileName.split('.').last.toLowerCase();
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

      final now = DateTime.now();
      final updated = UserDocumentModel(
        documentId: documentId,
        userId: userId,
        documentType: documentType,
        documentName: documentName,
        storagePath: 'users/$userId/documents/$documentId.$ext',
        downloadUrl: null,
        fileType: ext,
        fileSize: fileSize,
        uploadedAt: now,
        updatedAt: now,
        verificationStatus: 'uploaded',
        notes: notes,
      );

      final saved = await _service.saveDocument(updated);

      final index = _documents.indexWhere((d) => d.documentId == documentId);
      if (index >= 0) {
        _documents[index] = saved;
      } else {
        _documents.removeWhere((d) => d.documentType == documentType);
        _documents.insert(0, saved);
      }

      _isLoading = false;
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
  }) async {
    try {
      await _service.deleteDocument(userId, documentId, documentType);
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
    notifyListeners();
  }

  /// Reset for test
  @visibleForTesting
  void setDocumentsForTesting(List<UserDocumentModel> docs) {
    _documents = List.from(docs);
    notifyListeners();
  }
}
