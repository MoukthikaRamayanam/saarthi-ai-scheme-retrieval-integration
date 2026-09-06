import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String schemeName;
  final String? schemeId;
  final List<String> requiredDocuments;

  const DocumentUploadScreen({
    super.key,
    required this.schemeName,
    this.schemeId,
    required this.requiredDocuments,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  static const Color primaryTeal = Color(0xFF0B4F4A);
  static const int maxFileSizeBytes = 10 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'pdf', 'jpg', 'jpeg', 'png'};

  final Map<String, List<PlatformFile>> _selectedFiles = {};

  bool _isMultiFileRequirement(String documentName) {
    final normalizedName = documentName.toLowerCase();
    final indicatesMultiple =
        normalizedName.contains('additional') ||
        normalizedName.contains('other');
    final indicatesDocuments =
        normalizedName.contains('document') ||
        normalizedName.contains('supporting');
    return indicatesMultiple && indicatesDocuments;
  }

  int get _selectedCount =>
      _selectedFiles.values.where((files) => files.isNotEmpty).length;

  Future<void> _chooseFile(String documentName, {bool addMore = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions.toList(),
      allowMultiple: _isMultiFileRequirement(documentName),
      withData: false,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final validFiles = <PlatformFile>[];
    for (final file in result.files) {
      final extension = (file.extension ?? '').toLowerCase();

      if (!allowedExtensions.contains(extension)) {
        _showError('Only PDF, JPG, JPEG, and PNG files are allowed.');
        continue;
      }

      if (file.size > maxFileSizeBytes) {
        _showError('Each file must be 10 MB or smaller.');
        continue;
      }

      validFiles.add(file);
    }

    if (validFiles.isEmpty) return;

    setState(() {
      if (_isMultiFileRequirement(documentName) && addMore) {
        final existingFiles = _selectedFiles[documentName] ?? [];
        final existingNames = existingFiles
            .map((file) => file.name.toLowerCase())
            .toSet();
        final newFiles = validFiles.where(
          (file) => !existingNames.contains(file.name.toLowerCase()),
        );
        _selectedFiles[documentName] = [...existingFiles, ...newFiles];
      } else {
        _selectedFiles[documentName] = validFiles;
      }
    });
  }

  void _removeFile(String documentName, PlatformFile file) {
    setState(() {
      final remainingFiles = [...?_selectedFiles[documentName]]..remove(file);
      if (remainingFiles.isEmpty) {
        _selectedFiles.remove(documentName);
      } else {
        _selectedFiles[documentName] = remainingFiles;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  void _showReadyMessage() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ready for OCR'),
        content: const Text(
          'Documents are ready for OCR processing.\n\n'
          'OCR integration is the next module.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final totalDocuments = widget.requiredDocuments.length;
    final allDocumentsSelected =
        totalDocuments > 0 && _selectedCount == totalDocuments;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Document Upload',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                children: [
                  Text(
                    widget.schemeName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (widget.schemeId != null &&
                      widget.schemeId!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Scheme ID: ${widget.schemeId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Required Documents',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select clear PDF, JPG or PNG files. Document contents '
                    'will be verified during OCR processing.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.requiredDocuments.isEmpty)
                    _buildEmptyState()
                  else
                    ...widget.requiredDocuments.map(_buildDocumentCard),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$_selectedCount of $totalDocuments documents selected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: allDocumentsSelected
                          ? _showReadyMessage
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Continue to OCR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String documentName) {
    final files = _selectedFiles[documentName] ?? [];
    final isMultiFile = _isMultiFileRequirement(documentName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              documentName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Accepted: PDF, JPG, PNG | Max 10 MB',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            if (files.isEmpty)
              OutlinedButton.icon(
                onPressed: () => _chooseFile(documentName),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(isMultiFile ? 'Choose Files' : 'Choose File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryTeal,
                  side: const BorderSide(color: primaryTeal),
                ),
              )
            else ...[
              ...files.map(
                (file) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: primaryTeal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${file.name} (${_formatFileSize(file.size)})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _removeFile(documentName, file),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isMultiFile)
                    OutlinedButton(
                      onPressed: () => _chooseFile(documentName, addMore: true),
                      child: const Text('Add More Files'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => _chooseFile(documentName),
                      child: const Text('Change File'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: const Text(
        'No required documents are available for this scheme.',
        style: TextStyle(fontSize: 12.5, color: Color(0xFF9A3412)),
      ),
    );
  }
}
