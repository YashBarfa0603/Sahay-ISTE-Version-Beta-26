import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/user_document_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/screens/auth/login_screen.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/services/document_service.dart';
import 'package:sahay/widgets/document_specimen_viewer.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:sahay/widgets/sahay_assistance_fab.dart';

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
    final l10n = SahayLocalizations.of(context);
    final currentLang = l10n.locale.languageCode;
    final isHi = currentLang == 'hi';
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
                                ? (isHi ? 'à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤¬à¤¦à¤²à¥‡à¤‚' : 'Replace Document')
                                : (isHi ? 'à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤œà¥‹à¤¡à¤¼à¥‡à¤‚ (à¤µà¥ˆà¤•à¤²à¥à¤ªà¤¿à¤•)' : 'Upload Document (Optional)'),
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
                                  ? 'à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤…à¤ªà¤²à¥‹à¤¡ à¤ªà¥‚à¤°à¥€ à¤¤à¤°à¤¹ à¤¸à¥‡ à¤µà¥ˆà¤•à¤²à¥à¤ªà¤¿à¤• à¤¹à¥ˆà¥¤ à¤¯à¤¹ à¤•à¥‡à¤µà¤² à¤†à¤ªà¤•à¥‡ à¤¨à¤¿à¤œà¥€ à¤¸à¤‚à¤¦à¤°à¥à¤­ à¤¹à¥‡à¤¤à¥ à¤¸à¤‚à¤—à¥à¤°à¤¹à¥€à¤¤ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆà¥¤'
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
                      l10n.selectDocumentType,
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
                            DocumentCatalogueService.getDisplayName(d.documentType, currentLang),
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
                            l10n.documentName,
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
                          hintText: l10n.customDocumentNameHint,
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
                      l10n.selectFilePrompt,
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
                                l10n.chooseFileFromDevice,
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.indianTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isHi ? 'à¤¸à¤®à¤°à¥à¤¥à¤¿à¤¤ à¤ªà¥à¤°à¤¾à¤°à¥‚à¤ª: PDF, JPG, PNG (à¤…à¤§à¤¿à¤•à¤¤à¤® 5 MB)' : 'Supported formats: PDF, JPG, PNG (Max 5.0 MB)',
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
                                    '${(selectedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB â€¢ ${selectedFileFormat.toUpperCase()}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: isUploading ? null : pickRealFile,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(l10n.change),
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
                            ? 'à¤¨à¤¿à¤œà¥€ à¤µà¥‰à¤²à¥à¤Ÿ à¤®à¥‡à¤‚ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤…à¤ªà¤²à¥‹à¤¡ à¤¹à¥‹ à¤°à¤¹à¤¾ à¤¹à¥ˆ...'
                            : 'Uploading securely to private vault...',
                        style: AppTextStyles.caption.copyWith(color: AppColors.indianTeal, fontWeight: FontWeight.w600),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Optional Notes
                    Text(
                      l10n.optionalNotes,
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        hintText: l10n.optionalNotesHint,
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
                                    localError = l10n.customDocumentNameRequired;
                                  });
                                  return;
                                }

                                if (selectedFileName == null && existingDoc == null) {
                                  setModalState(() {
                                    localError = isHi
                                        ? 'à¤•à¥ƒà¤ªà¤¯à¤¾ à¤œà¤¾à¤°à¥€ à¤°à¤–à¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤…à¤ªà¤¨à¥‡ à¤¡à¤¿à¤µà¤¾à¤‡à¤¸ à¤¸à¥‡ à¤à¤• à¤«à¤¼à¤¾à¤‡à¤² à¤šà¥à¤¨à¥‡à¤‚à¥¤'
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
                                    : DocumentCatalogueService.getDisplayName(selectedType, currentLang);

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
                                                ? 'à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤µà¥‰à¤²à¥à¤Ÿ à¤®à¥‡à¤‚ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤¸à¤¹à¥‡à¤œà¤¾ à¤—à¤¯à¤¾à¥¤'
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
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            existingDoc != null
                                ? l10n.updateDocument
                                : l10n.saveToVault,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
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

  void _showDocumentPreview(UserDocumentModel doc, SahayLocalizations l10n) {
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
                      _buildMetaRow(l10n.fileType, doc.fileType.toUpperCase()),
                      _buildMetaRow(l10n.fileSize, doc.formattedFileSize),
                      _buildMetaRow(
                        l10n.uploadDate,
                        '${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}',
                      ),
                      _buildMetaRow(l10n.status, l10n.uploadedToVault),
                      if (doc.notes != null && doc.notes!.isNotEmpty)
                        _buildMetaRow(l10n.notes, doc.notes!),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Specimen Visualizer
                if (docInfo != null)
                  DocumentSpecimenViewer(
                    documentInfo: docInfo,
                    language: l10n.locale.languageCode,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(l10n.close),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dCtx).pop();
                _confirmReplaceDocument(doc, l10n);
              },
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: Text(l10n.change),
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

  void _confirmReplaceDocument(UserDocumentModel doc, SahayLocalizations l10n) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor: AppColors.warmIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.replaceDocument,
          style: AppTextStyles.heading3.copyWith(fontSize: 18),
        ),
        content: Text(
          l10n.locale.languageCode == 'hi'
              ? 'à¤¨à¤¯à¤¾ à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤…à¤ªà¤²à¥‹à¤¡ à¤•à¤°à¤¨à¥‡ à¤ªà¤° à¤ªà¤¿à¤›à¤²à¤¾ à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤°à¥‚à¤ª à¤¸à¥‡ à¤¬à¤¦à¤² à¤¦à¤¿à¤¯à¤¾ à¤œà¤¾à¤à¤—à¤¾à¥¤'
              : 'Uploading a new version will replace the current file in your vault once the new upload succeeds.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(),
            child: Text(l10n.cancel),
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
            child: Text(l10n.proceed),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDocument(UserDocumentModel doc, SahayLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          backgroundColor: AppColors.warmIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l10n.deleteDocument,
            style: AppTextStyles.heading3.copyWith(color: AppColors.mutedCoral),
          ),
          content: Text(
            l10n.locale.languageCode == 'hi'
                ? 'à¤•à¥à¤¯à¤¾ à¤†à¤ª à¤µà¤¾à¤•à¤ˆ "${doc.documentName}" à¤•à¥‹ à¤…à¤ªà¤¨à¥‡ à¤¨à¤¿à¤œà¥€ à¤µà¥‰à¤²à¥à¤Ÿ à¤¸à¥‡ à¤¹à¤Ÿà¤¾à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚?'
                : 'Are you sure you want to permanently delete "${doc.documentName}" from your vault?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(l10n.cancel),
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
                      content: Text(
                        l10n.locale.languageCode == 'hi'
                            ? 'à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤¹à¤Ÿà¤¾ à¤¦à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾à¥¤'
                            : 'Document deleted.',
                      ),
                      backgroundColor: AppColors.deepNavy,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mutedCoral,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.delete),
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
    final l10n = SahayLocalizations.of(context);
    final isHi = l10n.locale.languageCode == 'hi';
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
        title: l10n.myDocumentsVault,
        showBackButton: true,
        showLanguageToggle: true,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SahayAssistanceFAB(
            currentScreen: 'document_vault',
            mini: true,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'my_documents_add_fab',
            onPressed: () => _showUploadDialog(),
            backgroundColor: AppColors.indianTeal,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l10n.uploadDocument,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
                              isHi ? 'à¤…à¤¤à¤¿à¤¥à¤¿ à¤®à¥‹à¤¡ â€” à¤¸à¤¤à¥à¤° à¤µà¥‰à¤²à¥à¤Ÿ' : 'Guest Mode â€” Session Vault',
                              style: AppTextStyles.heading3.copyWith(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHi
                            ? 'à¤†à¤ª à¤…à¤¤à¤¿à¤¥à¤¿ à¤•à¥‡ à¤°à¥‚à¤ª à¤®à¥‡à¤‚ à¤µà¥‰à¤²à¥à¤Ÿ à¤•à¤¾ à¤ªà¤°à¥€à¤•à¥à¤·à¤£ à¤•à¤° à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤¸à¥à¤¥à¤¾à¤¯à¥€ à¤°à¥‚à¤ª à¤¸à¥‡ à¤…à¤ªà¤¨à¥‡ à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤¸à¤¹à¥‡à¤œà¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤à¤• à¤¨à¤¿à¤ƒà¤¶à¥à¤²à¥à¤• à¤–à¤¾à¤¤à¤¾ à¤¬à¤¨à¤¾à¤à¤‚à¥¤'
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('${l10n.signIn} / ${l10n.signUp}'),
                          ),
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
                                isHi ? 'à¤¨à¤¿à¤œà¥€ à¤¸à¥à¤°à¤•à¥à¤·à¤¾ à¤µà¥‰à¤²à¥à¤Ÿ' : 'Private Security Vault',
                                style: AppTextStyles.heading3.copyWith(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                '${docProvider.documentCount} ${isHi ? "à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤" : "documents stored"}',
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
                          ? 'à¤œà¥€à¤°à¥‹-à¤°à¤¿à¤Ÿà¥‡à¤‚à¤¶à¤¨ à¤¸à¤¿à¤¦à¥à¤§à¤¾à¤‚à¤¤: à¤†à¤ªà¤•à¥‡ à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤•à¥‡à¤µà¤² à¤†à¤ªà¤•à¥‡ à¤¨à¤¿à¤œà¥€ à¤¸à¤‚à¤¦à¤°à¥à¤­ à¤¹à¥‡à¤¤à¥ à¤¹à¥ˆà¤‚à¥¤ à¤…à¤ªà¤²à¥‹à¤¡ à¤ªà¥‚à¤°à¥€ à¤¤à¤°à¤¹ à¤¸à¥‡ à¤µà¥ˆà¤•à¤²à¥à¤ªà¤¿à¤• à¤¹à¥ˆà¥¤'
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
                        isHi ? 'à¤•à¥‹à¤ˆ à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤…à¤ªà¤²à¥‹à¤¡ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆ' : 'No Documents Uploaded Yet',
                        style: AppTextStyles.heading3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHi
                            ? 'à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤œà¥‹à¤¡à¤¼à¤¨à¤¾ 100% à¤µà¥ˆà¤•à¤²à¥à¤ªà¤¿à¤• à¤¹à¥ˆà¥¤ à¤†à¤ª à¤¬à¤¿à¤¨à¤¾ à¤•à¤¿à¤¸à¥€ à¤¦à¤¸à¥à¤¤à¤¾à¤µà¥‡à¤œà¤¼ à¤•à¥‡ à¤­à¥€ à¤¯à¥‹à¤œà¤¨à¤¾à¤“à¤‚ à¤•à¥€ à¤ªà¤¾à¤¤à¥à¤°à¤¤à¤¾ à¤œà¤¾à¤‚à¤š à¤¸à¤•à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤'
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
                          l10n.uploadDocument,
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
                                      l10n.inVault,
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
                              _showDocumentPreview(doc, l10n);
                            } else if (val == 'replace') {
                              _confirmReplaceDocument(doc, l10n);
                            } else if (val == 'delete') {
                              _confirmDeleteDocument(doc, l10n);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'preview',
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility_outlined, size: 18, color: AppColors.indianTeal),
                                  const SizedBox(width: 8),
                                  Text(l10n.previewInfo),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'replace',
                              child: Row(
                                children: [
                                  const Icon(Icons.sync_rounded, size: 18, color: AppColors.deepNavy),
                                  const SizedBox(width: 8),
                                  Text(l10n.replaceFile),
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
                                    l10n.delete,
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
