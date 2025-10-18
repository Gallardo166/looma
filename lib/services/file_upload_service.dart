import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'supabase_service.dart';

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
}
