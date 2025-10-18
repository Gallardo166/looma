class CourseFile {
  final String fileName;
  final String filePath;
  final String? publicUrl;
  final String fileType;
  final int fileSize;

  CourseFile({
    required this.fileName,
    required this.filePath,
    this.publicUrl,
    required this.fileType,
    required this.fileSize,
  });

  @override
  String toString() {
    return 'CourseFile(fileName: $fileName, filePath: $filePath, fileType: $fileType, fileSize: $fileSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseFile && 
           other.fileName == fileName && 
           other.filePath == filePath && 
           other.fileType == fileType &&
           other.fileSize == fileSize;
  }

  @override
  int get hashCode => fileName.hashCode ^ filePath.hashCode ^ fileType.hashCode ^ fileSize.hashCode;
}

class Course {
  final String id;
  final String name;
  final List<CourseFile> files;
  final String? pdfPath; // Keep for backward compatibility
  final CourseFile? summaryFile;
  final CourseFile? mindmapFile;
  final CourseFile? audioFile;

  Course({
    required this.id,
    required this.name,
    this.files = const [],
    this.pdfPath, // Deprecated: use files instead
    this.summaryFile,
    this.mindmapFile,
    this.audioFile,
  });

  // Helper getter for backward compatibility
  bool get hasPdf => pdfPath != null || files.any((file) => file.fileType.toLowerCase() == 'pdf');

  // Helper getter to get all PDF files
  List<CourseFile> get pdfFiles => files.where((file) => file.fileType.toLowerCase() == 'pdf').toList();

  // Helper getter to get all non-PDF files
  List<CourseFile> get otherFiles => files.where((file) => file.fileType.toLowerCase() != 'pdf').toList();

  // Helper getters for AI-generated content
  bool get hasAIContent => summaryFile != null || mindmapFile != null || audioFile != null;
  bool get hasSummary => summaryFile != null;
  bool get hasMindmap => mindmapFile != null;
  bool get hasAudio => audioFile != null;

  @override
  String toString() {
    return 'Course(id: $id, name: $name, files: ${files.length}, hasAIContent: $hasAIContent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && 
           other.id == id && 
           other.name == name && 
           other.files == files &&
           other.pdfPath == pdfPath &&
           other.summaryFile == summaryFile &&
           other.mindmapFile == mindmapFile &&
           other.audioFile == audioFile;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ files.hashCode ^ 
                     (pdfPath?.hashCode ?? 0) ^ 
                     (summaryFile?.hashCode ?? 0) ^ 
                     (mindmapFile?.hashCode ?? 0) ^ 
                     (audioFile?.hashCode ?? 0);
}
