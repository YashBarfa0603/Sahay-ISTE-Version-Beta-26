import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/user_document_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/screens/auth/login_screen.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/services/document_service.dart';
import 'package:sahay/widgets/document_specimen_viewer.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';

/// Screen allowing registered citizens to view, manage, replace, and delete
/// their private documents in their personal document vault.
class MyDocumentsScreen extends StatefulWidget {
  final String? preselectedType;
  const MyDocumentsScreen({super.key, this.preselectedType});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isGuest && auth.user != null) {
        context.read<UserDocumentProvider>().loadDocuments(auth.user!.uid);
      }
      if (widget.preselectedType != null) {
        _showUploadDialog(preselectedType: widget.preselectedType);
      }
    });
  }

  void _showUploadDialog({
    UserDocumentModel? existingDoc,
    String? preselectedType,
  }) {
    final isHi = context.read<LocaleProvider>().languageCode == 'hi';
    final allDocs = DocumentCatalogueService.getAllDocuments();
    final auth = context.read<AuthProvider>();

    String selectedType = existingDoc?.documentType ?? preselectedType ?? 'aadhaar_card';
    String? selectedFileName;
    Uint8List? selectedFileBytes = existingDoc?.cachedBytes;
    int selectedFileSize = existingDoc?.fileSize ?? 0;
    String selectedFileFormat = existingDoc?.fileType ?? '';
    final notesController = TextEditingController(text: existingDoc?.notes ?? '');
    final customNameController = TextEditingController(
      text: (existingDoc?.documentType == 'additional_document' || existingDoc?.documentType == 'other_document')
          ? existingDoc?.documentName ?? ''
          : '',
    );
    String? localError;
    bool isUploading = false;
    double progressValue = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final docInfo = DocumentCatalogueService.getDocumentByType(selectedType);

            Future<void> pickRealFile() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  final ext = (file.extension ?? '').toLowerCase().replaceAll('.', '').trim();
                  final err = DocumentService.validateFile(
                    fileType: ext,
                    fileSize: file.size,
                  );

                  setModalState(() {
                    selectedFileName = file.name;
                    selectedFileBytes = file.bytes;
                    selectedFileSize = file.size;
                    selectedFileFormat = ext;
                    localError = err;
                  });
                }
              } catch (e) {
                setModalState(() {
                  localError = 'File picker error: $e';
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.warmIvory,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.indianTeal.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            existingDoc != null ? Icons.sync_rounded : Icons.cloud_upload_outlined,
                            color: AppColors.indianTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            existingDoc != null
                                ? (isHi ? 'दस्तावेज़ बदलें' : 'Replace Document')
                                : (isHi ? 'दस्तावेज़ जोड़ें (वैकल्पिक)' : 'Upload Document (Optional)'),
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 18,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Optional & Privacy Notice
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.paleSage,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.privacy_tip_outlined, size: 16, color: AppColors.forestGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isHi
                                  ? 'दस्तावेज़ अपलोड पूरी तरह से वैकल्पिक है। यह केवल आपके निजी संदर्भ हेतु संग्रहीत होता है।'
                                  : 'Document upload is strictly optional. It is stored exclusively in your private vault for reference.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.deepNavy,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Document Type Selector
                    Text(
                      isHi ? 'दस्तावेज़ का प्रकार चुनें:' : 'Select Document Type:',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: allDocs.map((d) {
                        return DropdownMenuItem(
                          value: d.documentType,
                          child: Text(
                            isHi ? d.displayNameHindi : d.displayName,
                            style: AppTextStyles.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: existingDoc != null
                          ? null // Lock type during replacement
                          : (val) {
                              if (val != null) {
                                setModalState(() => selectedType = val);
                              }
                            },
                    ),
                    if (selectedType == 'additional_document' || selectedType == 'other_document') ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            isHi ? 'दस्तावेज़ का नाम:' : 'Document Name:',
                            style: AppTextStyles.label,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(color: AppColors.mutedCoral, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: customNameController,
                        decoration: InputDecoration(
                          hintText: isHi
                              ? 'उदा. जन्म प्रमाण पत्र, मृत्यु प्रमाण पत्र'
                              : 'e.g. Birth Certificate, Death Certificate',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Real File Selection from Device
                    Text(
                      isHi ? 'फ़ाइल चयन (PDF, JPG, PNG — अधिकतम 5 MB):' : 'Select File (PDF, JPG, PNG — Max 5.0 MB):',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 8),

                    if (selectedFileName == null && existingDoc == null)
                      InkWell(
                        onTap: isUploading ? null : pickRealFile,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.indianTeal, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.upload_file_rounded, size: 36, color: AppColors.indianTeal),
                              const SizedBox(height: 8),
                              Text(
                                isHi ? 'डिवाइस से फ़ाइल चुनें' : 'Choose File from Device',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.indianTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isHi ? 'समर्थित प्रारूप: PDF, JPG, PNG (अधिकतम 5 MB)' : 'Supported formats: PDF, JPG, PNG (Max 5.0 MB)',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (selectedFileFormat == 'pdf')
                                    ? AppColors.mutedCoral.withValues(alpha: 0.15)
                                    : AppColors.indianTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                (selectedFileFormat == 'pdf')
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.image_rounded,
                                color: (selectedFileFormat == 'pdf')
                                    ? AppColors.mutedCoral
                                    : AppColors.indianTeal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedFileName ?? existingDoc?.documentName ?? 'document.$selectedFileFormat',
                                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${(selectedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB • ${selectedFileFormat.toUpperCase()}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: isUploading ? null : pickRealFile,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(isHi ? 'बदलें' : 'Change'),
                            ),
                          ],
                        ),
                      ),

                    // Upload Progress Indicator
                    if (isUploading) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressValue > 0 ? progressValue : null,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.indianTeal),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHi
                            ? 'निजी वॉल्ट में सुरक्षित अपलोड हो रहा है...'
                            : 'Uploading securely to private vault...',
                        style: AppTextStyles.caption.copyWith(color: AppColors.indianTeal, fontWeight: FontWeight.w600),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Optional Notes
                    Text(
                      isHi ? 'वैकल्पिक टिप्पणी (जैसे जारी होने का वर्ष):' : 'Optional Notes (e.g. Issue Year):',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        hintText: isHi ? 'उदा. 2024 में नवीनीकृत' : 'e.g. Renewed in 2024',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),

                    if (localError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mutedCoral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.mutedCoral),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.mutedCoral, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localError!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.mutedCoral,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Upload / Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isUploading
                            ? null
                            : () async {
                                final isCustomType = selectedType == 'additional_document' || selectedType == 'other_document';
                                final customName = customNameController.text.trim();

                                if (isCustomType && customName.isEmpty) {
                                  setModalState(() {
                                    localError = isHi
                                        ? 'कृपया दस्तावेज़ का नाम दर्ज करें।'
                                        : 'Please enter the document name.';
                                  });
                                  return;
                                }

                                if (selectedFileName == null && existingDoc == null) {
                                  setModalState(() {
                                    localError = isHi
                                        ? 'कृपया जारी रखने के लिए अपने डिवाइस से एक फ़ाइल चुनें।'
                                        : 'Please select a file from your device to proceed.';
                                  });
                                  return;
                                }

                                final fileExt = selectedFileFormat.isNotEmpty
                                    ? selectedFileFormat
                                    : (existingDoc?.fileType ?? 'pdf');

                                final err = DocumentService.validateFile(
                                  fileType: fileExt,
                                  fileSize: selectedFileSize,
                                );
                                if (err != null) {
                                  setModalState(() => localError = err);
                                  return;
                                }

                                setModalState(() {
                                  isUploading = true;
                                  localError = null;
                                  progressValue = 0.1;
                                });

                                final provider = context.read<UserDocumentProvider>();
                                final uid = auth.user?.uid ?? 'guest_user';
                                final docName = isCustomType
                                    ? customName
                                    : (isHi
                                        ? (docInfo?.displayNameHindi ?? selectedType)
                                        : (docInfo?.displayName ?? selectedType));

                                bool success = false;
                                final fileName = selectedFileName ??
                                    existingDoc?.documentName ??
                                    '$selectedType.$fileExt';

                                if (existingDoc != null) {
                                  success = await provider.replaceDocument(
                                    documentId: existingDoc.documentId,
                                    userId: uid,
                                    documentType: selectedType,
                                    documentName: docName,
                                    fileName: fileName,
                                    fileSize: selectedFileSize,
                                    fileBytes: selectedFileBytes,
                                    oldStoragePath: existingDoc.storagePath,
                                    notes: notesController.text.trim().isNotEmpty
                                        ? notesController.text.trim()
                                        : null,
                                    onProgress: (p) => setModalState(() => progressValue = p),
                                  );
                                } else {
                                  success = await provider.uploadDocument(
                                    userId: uid,
                                    documentType: selectedType,
                                    documentName: docName,
                                    fileName: fileName,
                                    fileSize: selectedFileSize,
                                    fileBytes: selectedFileBytes,
                                    notes: notesController.text.trim().isNotEmpty
                                        ? notesController.text.trim()
                                        : null,
                                    onProgress: (p) => setModalState(() => progressValue = p),
                                  );
                                }

                                if (modalCtx.mounted) {
                                  Navigator.of(modalCtx).pop();
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? (isHi
                                                ? 'दस्तावेज़ वॉल्ट में सुरक्षित सहेजा गया।'
                                                : 'Document securely saved to vault.')
                                            : (provider.errorMessage ?? 'Upload failed'),
                                      ),
                                      backgroundColor:
                                          success ? AppColors.forestGreen : AppColors.mutedCoral,
                                    ),
                                  );
                                }
                              },
                        icon: isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_rounded, color: Colors.white),
                        label: Text(
                          existingDoc != null
                              ? (isHi ? 'दस्तावेज़ अपडेट करें' : 'Update Document')
                              : (isHi ? 'वॉल्ट में सहेजें' : 'Save to Vault'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indianTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDocumentPreview(UserDocumentModel doc, bool isHi) {
    final docInfo = DocumentCatalogueService.getDocumentByType(doc.documentType);

    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          backgroundColor: AppColors.warmIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(
                doc.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: doc.isPdf ? AppColors.mutedCoral : AppColors.indianTeal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doc.documentName,
                  style: AppTextStyles.heading3.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In-App Image Preview if Image bytes are available
                if (doc.isImage && doc.cachedBytes != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      doc.cachedBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),

                // Metadata block
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow(isHi ? 'फ़ाइल प्रकार:' : 'File Format:', doc.fileType.toUpperCase()),
                      _buildMetaRow(isHi ? 'फ़ाइल आकार:' : 'File Size:', doc.formattedFileSize),
                      _buildMetaRow(
                        isHi ? 'अपलोड तिथि:' : 'Uploaded:',
                        '${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}',
                      ),
                      _buildMetaRow(isHi ? 'स्थिति:' : 'Status:', 'Uploaded to Vault'),
                      if (doc.notes != null && doc.notes!.isNotEmpty)
                        _buildMetaRow(isHi ? 'टिप्पणी:' : 'Notes:', doc.notes!),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Specimen Visualizer
                if (docInfo != null)
                  DocumentSpecimenViewer(
                    documentInfo: docInfo,
                    language: isHi ? 'hi' : 'en',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(isHi ? 'बंद करें' : 'Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dCtx).pop();
                _confirmReplaceDocument(doc, isHi);
              },
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: Text(isHi ? 'बदलें' : 'Replace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indianTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmReplaceDocument(UserDocumentModel doc, bool isHi) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor: AppColors.warmIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isHi ? 'दस्तावेज़ बदलें?' : 'Replace Document?',
          style: AppTextStyles.heading3.copyWith(fontSize: 18),
        ),
        content: Text(
          isHi
              ? 'नया दस्तावेज़ अपलोड करने पर पिछला दस्तावेज़ सुरक्षित रूप से बदल दिया जाएगा।'
              : 'Uploading a new version will replace the current file in your vault once the new upload succeeds.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(),
            child: Text(isHi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(confirmCtx).pop();
              _showUploadDialog(existingDoc: doc);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indianTeal,
              foregroundColor: Colors.white,
            ),
            child: Text(isHi ? 'आगे बढ़ें' : 'Proceed'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDocument(UserDocumentModel doc, bool isHi) {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          backgroundColor: AppColors.warmIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isHi ? 'दस्तावेज़ हटाएं?' : 'Delete Document?',
            style: AppTextStyles.heading3.copyWith(color: AppColors.mutedCoral),
          ),
          content: Text(
            isHi
                ? 'क्या आप वाकई "${doc.documentName}" को अपने निजी वॉल्ट से हटाना चाहते हैं?'
                : 'Are you sure you want to permanently delete "${doc.documentName}" from your vault?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(isHi ? 'रद्द करें' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dCtx).pop();
                final auth = context.read<AuthProvider>();
                final provider = context.read<UserDocumentProvider>();
                await provider.deleteDocument(
                  userId: auth.user?.uid ?? 'guest_user',
                  documentId: doc.documentId,
                  documentType: doc.documentType,
                  storagePath: doc.storagePath,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHi ? 'दस्तावेज़ हटा दिया गया।' : 'Document deleted.'),
                      backgroundColor: AppColors.deepNavy,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mutedCoral,
                foregroundColor: Colors.white,
              ),
              child: Text(isHi ? 'हटाएं' : 'Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy.withValues(alpha: 0.7))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.deepNavy),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHi = context.watch<LocaleProvider>().languageCode == 'hi';
    final auth = context.watch<AuthProvider>();
    final docProvider = context.watch<UserDocumentProvider>();
    final isGuest = auth.isGuest || auth.user == null;

    final categories = ['All', 'Identity', 'Land', 'Banking', 'Income', 'Address', 'Education', 'Other'];

    final filteredDocs = docProvider.documents.where((d) {
      if (_selectedCategory == 'All') return true;
      final info = DocumentCatalogueService.getDocumentByType(d.documentType);
      return info?.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: isHi ? 'मेरे दस्तावेज़ (वॉल्ट)' : 'My Documents Vault',
        showBackButton: true,
        showLanguageToggle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(),
        backgroundColor: AppColors.indianTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          isHi ? 'दस्तावेज़ जोड़ें' : 'Add Document',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest Mode Banner
              if (isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softSaffron.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.softSaffron),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, color: AppColors.deepNavy),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isHi ? 'अतिथि मोड — सत्र वॉल्ट' : 'Guest Mode — Session Vault',
                              style: AppTextStyles.heading3.copyWith(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHi
                            ? 'आप अतिथि के रूप में वॉल्ट का परीक्षण कर रहे हैं। स्थायी रूप से अपने दस्तावेज़ सहेजने के लिए एक निःशुल्क खाता बनाएं।'
                            : 'You are viewing the vault in guest mode. Sign in to permanently save your document metadata across devices.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.indianTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isHi ? 'साइन इन / खाता बनाएं' : 'Sign In / Create Account'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Header Vault Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.deepNavy, Color(0xFF1E3A4C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepNavy.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded, color: AppColors.softSaffron, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHi ? 'निजी सुरक्षा वॉल्ट' : 'Private Security Vault',
                                style: AppTextStyles.heading3.copyWith(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                '${docProvider.documentCount} ${isHi ? "दस्तावेज़ सुरक्षित" : "documents stored"}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.softSaffron),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isHi
                          ? 'जीरो-रिटेंशन सिद्धांत: आपके दस्तावेज़ केवल आपके निजी संदर्भ हेतु हैं। अपलोड पूरी तरह से वैकल्पिक है।'
                          : 'Zero-retention architecture: Documents are encrypted and accessible exclusively by you. Uploads remain strictly optional.',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.indianTeal,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.deepNavy,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 18),

              // Document List or Empty State
              if (docProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.indianTeal),
                  ),
                )
              else if (filteredDocs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.folder_open_rounded, size: 54, color: AppColors.indianTeal.withValues(alpha: 0.5)),
                      const SizedBox(height: 14),
                      Text(
                        isHi ? 'कोई दस्तावेज़ अपलोड नहीं है' : 'No Documents Uploaded Yet',
                        style: AppTextStyles.heading3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHi
                            ? 'दस्तावेज़ जोड़ना 100% वैकल्पिक है। आप बिना किसी दस्तावेज़ के भी योजनाओं की पात्रता जांच सकते हैं।'
                            : 'Document upload is 100% optional. You can still check scheme eligibility and generate PDF checklists without uploading.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.deepNavy.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _showUploadDialog(),
                        icon: const Icon(Icons.add_rounded, color: AppColors.indianTeal),
                        label: Text(
                          isHi ? 'पहला दस्तावेज़ जोड़ें' : 'Add First Document',
                          style: const TextStyle(color: AppColors.indianTeal, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.indianTeal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filteredDocs.map((doc) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Format Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: doc.isPdf
                                ? AppColors.mutedCoral.withValues(alpha: 0.12)
                                : AppColors.indianTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            doc.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                            color: doc.isPdf ? AppColors.mutedCoral : AppColors.indianTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Document Metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.documentName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    doc.formattedFileSize,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.deepNavy.withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.paleSage,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isHi ? 'वॉल्ट में सुरक्षित' : 'In Vault',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.forestGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions Menu
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.deepNavy),
                          onSelected: (val) {
                            if (val == 'preview') {
                              _showDocumentPreview(doc, isHi);
                            } else if (val == 'replace') {
                              _confirmReplaceDocument(doc, isHi);
                            } else if (val == 'delete') {
                              _confirmDeleteDocument(doc, isHi);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'preview',
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility_outlined, size: 18, color: AppColors.indianTeal),
                                  const SizedBox(width: 8),
                                  Text(isHi ? 'पूर्वावलोकन देखें' : 'Preview / Info'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'replace',
                              child: Row(
                                children: [
                                  const Icon(Icons.sync_rounded, size: 18, color: AppColors.deepNavy),
                                  const SizedBox(width: 8),
                                  Text(isHi ? 'दस्तावेज़ बदलें' : 'Replace File'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.mutedCoral),
                                  const SizedBox(width: 8),
                                  Text(
                                    isHi ? 'हटाएं' : 'Delete',
                                    style: const TextStyle(color: AppColors.mutedCoral),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 80), // Extra space for FAB
            ],
          ),
        ),
      ),
    );
  }
}
