import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course.dart';

class CourseDetailPage extends StatelessWidget {
  final Course course;

  const CourseDetailPage({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(course.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Course Files Section
            if (course.files.isNotEmpty) ...[
              _buildFilesSection(context),
              const SizedBox(height: 24),
            ],
            
            // AI-Generated Content Section
            if (course.hasAIContent) ...[
              _buildAIContentSection(context),
              const SizedBox(height: 24),
            ],
            
            // Summary Section
            _buildSection(
              context,
              title: 'Summary of Content',
              icon: Icons.summarize_outlined,
              description: course.hasSummary 
                  ? 'AI-generated comprehensive overview of the course material'
                  : 'Get a comprehensive overview of the course material',
              onTap: () {
                if (course.hasSummary) {
                  _showAIContent(context, 'Summary', course.summaryFile!);
                } else {
                  _showComingSoon(context, 'Summary');
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Mindmap Section
            _buildSection(
              context,
              title: 'Mindmap of Content',
              icon: Icons.account_tree_outlined,
              description: course.hasMindmap
                  ? 'AI-generated visual representation of course concepts'
                  : 'Visual representation of course concepts and connections',
              onTap: () {
                if (course.hasMindmap) {
                  _showAIContent(context, 'Mindmap', course.mindmapFile!);
                } else {
                  _showComingSoon(context, 'Mindmap');
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Quizzes Section
            _buildSection(
              context,
              title: 'Quizzes',
              icon: Icons.quiz_outlined,
              description: 'Test your knowledge with interactive quizzes',
              onTap: () {
                _showComingSoon(context, 'Quizzes');
              },
            ),
            const SizedBox(height: 16),
            
            // Audio Recap Section
            _buildSection(
              context,
              title: 'Audio Recap',
              icon: Icons.record_voice_over_outlined,
              description: course.hasAudio
                  ? 'AI-generated audio summary of key points'
                  : 'Listen to audio summaries and key points',
              onTap: () {
                if (course.hasAudio) {
                  _playAudioFile(context, course.audioFile!);
                } else {
                  _showComingSoon(context, 'Audio Recap');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilesSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Files',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${course.files.length} file(s) uploaded',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Files List
            ...course.files.map((file) => _buildFileItem(context, file)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, CourseFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openFile(context, file),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                _getFileIcon(file.fileName),
                size: 24,
                color: _getFileColor(file.fileName),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_formatFileSize(file.fileSize)} • ${file.fileType.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'txt':
        return Colors.grey;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.purple;
      case 'mp3':
      case 'wav':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.brown;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade700;
      case 'ppt':
      case 'pptx':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _openFile(BuildContext context, CourseFile file) async {
    if (file.publicUrl != null) {
      final uri = Uri.parse(file.publicUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: show a dialog with the URL
        if (context.mounted) {
          _showFileUrlDialog(context, file);
        }
      }
    } else {
      if (context.mounted) {
        _showFileUrlDialog(context, file);
      }
    }
  }

  void _showFileUrlDialog(BuildContext context, CourseFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Type: ${file.fileType.toUpperCase()}'),
            Text('File Size: ${_formatFileSize(file.fileSize)}'),
            if (file.publicUrl != null) ...[
              const SizedBox(height: 8),
              const Text('Download URL:'),
              const SizedBox(height: 4),
              SelectableText(
                file.publicUrl!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (file.publicUrl != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openFile(context, file);
              },
              child: const Text('Open'),
            ),
        ],
      ),
    );
  }

  Widget _buildAIContentSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    color: Colors.purple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Generated Content',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      Text(
                        'Automatically generated study materials',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // AI Content Items
            if (course.hasSummary) ...[
              _buildAIContentItem(
                context,
                title: 'Summary',
                icon: Icons.summarize_outlined,
                description: 'Comprehensive overview of course material',
                onTap: () => _showAIContent(context, 'Summary', course.summaryFile!),
              ),
              const SizedBox(height: 8),
            ],
            
            if (course.hasMindmap) ...[
              _buildAIContentItem(
                context,
                title: 'Mindmap',
                icon: Icons.account_tree_outlined,
                description: 'Visual representation of concepts and connections',
                onTap: () => _showAIContent(context, 'Mindmap', course.mindmapFile!),
              ),
              const SizedBox(height: 8),
            ],
            
            if (course.hasAudio) ...[
              _buildAIContentItem(
                context,
                title: 'Audio Summary',
                icon: Icons.record_voice_over_outlined,
                description: 'Listen to key points and concepts',
                onTap: () => _playAudioFile(context, course.audioFile!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAIContentItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.purple.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.purple.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showAIContent(BuildContext context, String title, CourseFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title - AI Generated'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _getFileContent(file),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              if (file.publicUrl != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openFile(context, file),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open in Browser'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _playAudioFile(BuildContext context, CourseFile file) {
    if (file.publicUrl != null) {
      _openFile(context, file);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio file not available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _getFileContent(CourseFile file) {
    // This is a placeholder - in a real implementation, you would fetch the content
    // For now, return a message indicating the content is available
    return 'AI-generated content is available at: ${file.publicUrl ?? 'File path: ${file.filePath}'}\n\n'
           'File size: ${_formatFileSize(file.fileSize)}\n'
           'File type: ${file.fileType.toUpperCase()}';
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature - Coming Soon'),
        content: Text('This feature is under development and will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
