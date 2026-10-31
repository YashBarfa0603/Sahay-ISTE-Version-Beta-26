import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a citizen's private document metadata stored in Firestore.
class UserDocumentModel {
  final String documentId;
  final String userId;
  final String documentType; // Canonical identifier e.g. 'aadhaar_card'
  final String documentName; // User-facing name e.g. 'Aadhaar Card'
  final String storagePath;
  final String? downloadUrl;
  final String fileType; // 'pdf', 'jpg', 'png'
  final int fileSize; // In bytes
  final DateTime uploadedAt;
  final DateTime updatedAt;
  final String verificationStatus; // 'uploaded', 'unverified'
  final String? notes;
  final Uint8List? cachedBytes;

  const UserDocumentModel({
    required this.documentId,
    required this.userId,
    required this.documentType,
    required this.documentName,
    required this.storagePath,
    this.downloadUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    required this.updatedAt,
    this.verificationStatus = 'unverified',
    this.notes,
    this.cachedBytes,
  });

  /// Formatted file size string (e.g. "1.2 MB", "450 KB")
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isImage =>
      fileType.toLowerCase() == 'jpg' ||
      fileType.toLowerCase() == 'jpeg' ||
      fileType.toLowerCase() == 'png';

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'documentType': documentType,
      'documentName': documentName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'fileType': fileType.toLowerCase(),
      'fileSize': fileSize,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'verificationStatus': verificationStatus,
      'notes': notes,
    };
  }

  factory UserDocumentModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return UserDocumentModel(
      documentId: (map['documentId']?.toString() ?? id ?? '').trim(),
      userId: (map['userId']?.toString() ?? '').trim(),
      documentType: (map['documentType']?.toString() ?? 'other_document').trim(),
      documentName: (map['documentName']?.toString() ?? 'Document').trim(),
      storagePath: (map['storagePath']?.toString() ?? '').trim(),
      downloadUrl: map['downloadUrl']?.toString(),
      fileType: (map['fileType']?.toString() ?? 'pdf').toLowerCase().trim(),
      fileSize: (map['fileSize'] as num?)?.toInt() ?? 0,
      uploadedAt: parseDate(map['uploadedAt']),
      updatedAt: parseDate(map['updatedAt']),
      verificationStatus: map['verificationStatus']?.toString() ?? 'unverified',
      notes: map['notes']?.toString(),
    );
  }

  UserDocumentModel copyWith({
    String? documentId,
    String? userId,
    String? documentType,
    String? documentName,
    String? storagePath,
    String? downloadUrl,
    String? fileType,
    int? fileSize,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    String? verificationStatus,
    String? notes,
    Uint8List? cachedBytes,
  }) {
    return UserDocumentModel(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      documentName: documentName ?? this.documentName,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      notes: notes ?? this.notes,
      cachedBytes: cachedBytes ?? this.cachedBytes,
    );
  }
}

