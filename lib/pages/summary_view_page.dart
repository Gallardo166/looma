import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../models/course.dart';
import '../widgets/enhanced_summary_widget.dart';

class SummaryViewPage extends StatefulWidget {
  final CourseFile file;
  final String title;

  const SummaryViewPage({
    super.key,
    required this.file,
    required this.title,
  });

  @override
  State<SummaryViewPage> createState() => _SummaryViewPageState();
}

class _SummaryViewPageState extends State<SummaryViewPage> {
  Future<String>? _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = _getFileContent();
  }

  Future<String> _getFileContent() async {
    if (widget.file.publicUrl == null) {
      throw Exception('File URL is not available');
    }

    final response = await http.get(Uri.parse(widget.file.publicUrl!));
    if (response.statusCode == 200) {
      // Use bodyBytes with UTF-8 decoding to handle encoding issues
      try {
        return utf8.decode(response.bodyBytes, allowMalformed: true);
      } catch (e) {
        // Fallback to latin1 if UTF-8 fails
        return latin1.decode(response.bodyBytes);
      }
    } else {
      throw Exception('Failed to load file: ${response.statusCode}');
    }
  }

  void _openInBrowser() async {
    if (widget.file.publicUrl != null) {
      final uri = Uri.parse(widget.file.publicUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          if (widget.file.publicUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: 'Open in Browser',
              onPressed: _openInBrowser,
            ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading content...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading content',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _contentFuture = _getFileContent();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final content = snapshot.data ?? 'No content available';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: EnhancedSummaryWidget(summaryJson: content),
            ),
          );
        },
      ),
    );
  }
}
