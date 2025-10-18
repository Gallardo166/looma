import 'package:file_picker/file_picker.dart';

class TextExtractionResult {
  final String extractedText;
  final bool success;
  final String? error;

  TextExtractionResult({
    required this.extractedText,
    required this.success,
    this.error,
  });
}

class TextExtractionService {
  static final TextExtractionService _instance = TextExtractionService._internal();
  factory TextExtractionService() => _instance;
  TextExtractionService._internal();

  /// Extract text from multiple files
  Future<TextExtractionResult> extractTextFromFiles({
    required List<PlatformFile> files,
    Function(String fileName)? onProgress,
  }) async {
    final extractedTexts = <String>[];
    
    for (final file in files) {
      onProgress?.call(file.name);
      
      try {
        final result = await _extractTextFromFile(file);
        if (result.success && result.extractedText.isNotEmpty) {
          extractedTexts.add('=== ${file.name} ===\n${result.extractedText}\n\n');
        }
      } catch (e) {
        // Continue with other files even if one fails
        extractedTexts.add('=== ${file.name} ===\n[Error extracting text: ${e.toString()}]\n\n');
      }
    }

    if (extractedTexts.isEmpty) {
      return TextExtractionResult(
        extractedText: '',
        success: false,
        error: 'No text could be extracted from any files',
      );
    }

    return TextExtractionResult(
      extractedText: extractedTexts.join(),
      success: true,
    );
  }

  /// Extract text from a single file
  Future<TextExtractionResult> _extractTextFromFile(PlatformFile file) async {
    try {
      final fileExtension = file.name.split('.').last.toLowerCase();

      // Handle different file types
      if (fileExtension == 'pdf') {
        return await _extractFromPdf(file);
      } else if (fileExtension == 'txt') {
        return await _extractFromText(file);
      } else if (['doc', 'docx'].contains(fileExtension)) {
        return await _extractFromDocument(file);
      } else if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        return await _extractFromImage(file);
      } else {
        return TextExtractionResult(
          extractedText: '',
          success: false,
          error: 'Unsupported file type: $fileExtension',
        );
      }
    } catch (e) {
      return TextExtractionResult(
        extractedText: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Extract text from PDF files
  Future<TextExtractionResult> _extractFromPdf(PlatformFile file) async {
    try {
      if (file.bytes != null) {
        // For now, return a placeholder since PDF text extraction is complex
        // In a real implementation, you would use a proper PDF text extraction library
        return TextExtractionResult(
          extractedText: '[PDF content - text extraction not fully implemented for this file type. Please use text files for AI processing.]',
          success: true,
        );
      } else {
        return TextExtractionResult(
          extractedText: '',
          success: false,
          error: 'No file data available',
        );
      }
    } catch (e) {
      return TextExtractionResult(
        extractedText: '',
        success: false,
        error: 'PDF extraction failed: ${e.toString()}',
      );
    }
  }

  /// Extract text from plain text files
  Future<TextExtractionResult> _extractFromText(PlatformFile file) async {
    try {
      if (file.bytes != null) {
        final text = String.fromCharCodes(file.bytes!);
        return TextExtractionResult(
          extractedText: text,
          success: true,
        );
      } else {
        return TextExtractionResult(
          extractedText: '',
          success: false,
          error: 'No file data available',
        );
      }
    } catch (e) {
      return TextExtractionResult(
        extractedText: '',
        success: false,
        error: 'Text extraction failed: ${e.toString()}',
      );
    }
  }

  /// Extract text from document files (placeholder - would need additional libraries)
  Future<TextExtractionResult> _extractFromDocument(PlatformFile file) async {
    // For now, return a placeholder message
    // In a real implementation, you would use libraries like:
    // - docx_to_text for .docx files
    // - docx_parser for .doc files
    return TextExtractionResult(
      extractedText: '[Document content - text extraction not implemented for this file type]',
      success: true,
    );
  }

  /// Extract text from image files (placeholder - would need OCR)
  Future<TextExtractionResult> _extractFromImage(PlatformFile file) async {
    // For now, return a placeholder message
    // In a real implementation, you would use OCR libraries like:
    // - google_mlkit_text_recognition
    // - tesseract_ocr
    return TextExtractionResult(
      extractedText: '[Image content - OCR not implemented for this file type]',
      success: true,
    );
  }
}
