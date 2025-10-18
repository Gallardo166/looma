import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'supabase_service.dart';
import 'openai_service.dart';
import 'text_extraction_service.dart';
import '../models/course.dart';

class FileUploadResult {
  final String fileName;
  final String filePath;
  final String? publicUrl;
  final bool success;
  final String? error;

  FileUploadResult({
    required this.fileName,
    required this.filePath,
    this.publicUrl,
    required this.success,
    this.error,
  });
}

class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  factory FileUploadService() => _instance;
  FileUploadService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final OpenAIService _openAIService = OpenAIService();
  final TextExtractionService _textExtractionService = TextExtractionService();

  /// Upload multiple files to Supabase Storage
  Future<List<FileUploadResult>> uploadMultipleFiles({
    required List<PlatformFile> files,
    required String courseId,
    Function(int uploaded, int total)? onProgress,
  }) async {
    final results = <FileUploadResult>[];
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      onProgress?.call(i, files.length);
      
      try {
        final result = await _uploadSingleFile(
          file: file,
          courseId: courseId,
        );
        results.add(result);
      } catch (e) {
        results.add(FileUploadResult(
          fileName: file.name,
          filePath: '',
          success: false,
          error: e.toString(),
        ));
      }
    }
    
    onProgress?.call(files.length, files.length);
    return results;
  }

  /// Upload a single file to Supabase Storage
  Future<FileUploadResult> _uploadSingleFile({
    required PlatformFile file,
    required String courseId,
  }) async {
    try {
      // Generate unique file path
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = 'courses/$courseId/$fileName';

      // Prepare file data
      Uint8List fileBytes;
      if (file.bytes != null) {
        // Web platform - use bytes directly
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        // Mobile/Desktop platform - read file
        final fileObj = File(file.path!);
        fileBytes = await fileObj.readAsBytes();
      } else {
        throw Exception('No file data available');
      }

      // Upload to Supabase Storage
      await _supabaseService.storage
          .from(SupabaseService.courseFilesBucket)
          .uploadBinary(filePath, fileBytes);

      // Get public URL
      final publicUrl = _supabaseService.storage
          .from(SupabaseService.courseFilesBucket)
          .getPublicUrl(filePath);

      return FileUploadResult(
        fileName: file.name,
        filePath: filePath,
        publicUrl: publicUrl,
        success: true,
      );
    } catch (e) {
      return FileUploadResult(
        fileName: file.name,
        filePath: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Delete a file from Supabase Storage
  Future<bool> deleteFile(String filePath) async {
    try {
      await _supabaseService.storage
          .from(SupabaseService.courseFilesBucket)
          .remove([filePath]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get public URL for a file
  String getPublicUrl(String filePath) {
    return _supabaseService.storage
        .from(SupabaseService.courseFilesBucket)
        .getPublicUrl(filePath);
  }

  /// Complete course processing: upload files + AI processing
  Future<Course> processCourseWithAI({
    required String courseId,
    required String courseName,
    required List<PlatformFile> files,
    Function(String step, double progress)? onProgress,
  }) async {
    try {
      // Step 1: Upload original files
      onProgress?.call('Uploading files...', 0.1);
      final uploadResults = await uploadMultipleFiles(
        files: files,
        courseId: courseId,
        onProgress: (uploaded, total) {
          onProgress?.call('Uploading files... ($uploaded/$total)', 0.1 + (uploaded / total) * 0.3);
        },
      );

      // Convert upload results to CourseFile objects
      final uploadedFiles = <CourseFile>[];
      for (int i = 0; i < uploadResults.length; i++) {
        final result = uploadResults[i];
        final file = files[i];
        
        if (result.success) {
          uploadedFiles.add(CourseFile(
            fileName: result.fileName,
            filePath: result.filePath,
            publicUrl: result.publicUrl,
            fileType: _getFileType(file.name),
            fileSize: file.size,
          ));
        }
      }

      // Step 2: Extract text from uploaded files
      onProgress?.call('Extracting text from files...', 0.4);
      final textResult = await _textExtractionService.extractTextFromFiles(
        files: files,
        onProgress: (fileName) {
          onProgress?.call('Extracting text from $fileName...', 0.4);
        },
      );

      CourseFile? summaryFile;
      CourseFile? mindmapFile;
      CourseFile? audioFile;

      if (textResult.success && textResult.extractedText.isNotEmpty) {
        // Step 3: AI Processing
        onProgress?.call('Processing with AI...', 0.5);
        final aiResult = await _openAIService.processCourseFiles(
          courseName: courseName,
          extractedText: textResult.extractedText,
          onProgress: (step) {
            onProgress?.call(step, 0.5);
          },
        );

        if (aiResult.success) {
          // Step 4: Upload AI-generated files
          onProgress?.call('Uploading AI-generated content...', 0.8);
          
          // Upload summary
          if (aiResult.summary.isNotEmpty) {
            summaryFile = await _uploadAIGeneratedFile(
              courseId: courseId,
              fileName: 'summary.txt',
              content: aiResult.summary,
              fileType: 'text',
            );
          }

          // Upload mindmap
          if (aiResult.mindmap.isNotEmpty) {
            mindmapFile = await _uploadAIGeneratedFile(
              courseId: courseId,
              fileName: 'mindmap.txt',
              content: aiResult.mindmap,
              fileType: 'text',
            );
          }

          // Upload audio
          if (aiResult.audioBytes != null) {
            audioFile = await _uploadAIGeneratedAudio(
              courseId: courseId,
              fileName: 'audio_summary.mp3',
              audioBytes: aiResult.audioBytes!,
            );
          }
        }
      }

      onProgress?.call('Complete!', 1.0);

      return Course(
        id: courseId,
        name: courseName,
        files: uploadedFiles,
        summaryFile: summaryFile,
        mindmapFile: mindmapFile,
        audioFile: audioFile,
      );
    } catch (e) {
      // Return course with uploaded files even if AI processing fails
      final uploadedFiles = <CourseFile>[];
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        uploadedFiles.add(CourseFile(
          fileName: file.name,
          filePath: 'courses/$courseId/${file.name}',
          fileType: _getFileType(file.name),
          fileSize: file.size,
        ));
      }

      return Course(
        id: courseId,
        name: courseName,
        files: uploadedFiles,
      );
    }
  }

  /// Upload AI-generated text file
  Future<CourseFile?> _uploadAIGeneratedFile({
    required String courseId,
    required String fileName,
    required String content,
    required String fileType,
  }) async {
    try {
      final filePath = 'courses/$courseId/ai_generated/$fileName';
      final bytes = Uint8List.fromList(content.codeUnits);
      
      await _supabaseService.storage
          .from(SupabaseService.courseFilesBucket)
          .uploadBinary(filePath, bytes);

      final publicUrl = _supabaseService.storage
          .from(SupabaseService.courseFilesBucket)
          .getPublicUrl(filePath);

      return CourseFile(
        fileName: fileName,
        filePath: filePath,
        publicUrl: publicUrl,
        fileType: fileType,
        fileSize: bytes.length,
      );
    } catch (e) {
      return null;
    }
  }

  /// Upload AI-generated audio file
  Future<CourseFile?> _uploadAIGeneratedAudio({
    required String courseId,
    required String fileName,
    required Uint8List audioBytes,
  }) async {
    try {
      final filePath = 'courses/$courseId/ai_generated/$fileName';
      
      await _supabaseService.storage
          .from(SupabaseService.courseFilesBucket)
          .uploadBinary(filePath, audioBytes);

      final publicUrl = _supabaseService.storage
          .from(SupabaseService.courseFilesBucket)
          .getPublicUrl(filePath);

      return CourseFile(
        fileName: fileName,
        filePath: filePath,
        publicUrl: publicUrl,
        fileType: 'audio',
        fileSize: audioBytes.length,
      );
    } catch (e) {
      return null;
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'document';
      case 'txt':
        return 'text';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'video';
      case 'mp3':
      case 'wav':
        return 'audio';
      default:
        return 'file';
    }
  }
}
