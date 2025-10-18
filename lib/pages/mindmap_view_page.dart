import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../models/course.dart';

class MindmapViewPage extends StatefulWidget {
  final CourseFile file;
  final String title;

  const MindmapViewPage({
    super.key,
    required this.file,
    required this.title,
  });

  @override
  State<MindmapViewPage> createState() => _MindmapViewPageState();
}

class _MindmapViewPageState extends State<MindmapViewPage> {
  late final WebViewController _controller;
  Future<String>? _contentFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _contentFuture = _getFileContent();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
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

  String _cleanMermaidCode(String content) {
    // Remove markdown code blocks if present
    content = content.replaceAll('```mermaid', '').replaceAll('```', '').trim();
    
    // Remove any leading/trailing whitespace and newlines
    content = content.trim();
    
    // If doesn't start with mindmap, try to find it
    if (!content.toLowerCase().startsWith('mindmap')) {
      final startIndex = content.toLowerCase().indexOf('mindmap');
      if (startIndex != -1) {
        content = content.substring(startIndex);
      } else {
        // If still no mindmap found, return empty to show error
        return '';
      }
    }
    
    // Remove any text before "mindmap" keyword
    final lines = content.split('\n');
    final mindmapIndex = lines.indexWhere((line) => line.trim().toLowerCase().startsWith('mindmap'));
    if (mindmapIndex > 0) {
      content = lines.skip(mindmapIndex).join('\n');
    }
    
    return content.trim();
  }

  String _createHtmlContent(String mermaidCode) {
    final cleanCode = _cleanMermaidCode(mermaidCode);
    
    // Check if we have valid mermaid code
    if (cleanCode.isEmpty) {
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; font-family: sans-serif;">
  <div style="text-align: center; padding: 20px;">
    <h2 style="color: #dc2626;">⚠️ Invalid Mind Map Format</h2>
    <p>The generated content is not valid Mermaid code.</p>
    <pre style="background: #f3f4f6; padding: 15px; border-radius: 8px; text-align: left; overflow: auto; max-width: 500px;">$mermaidCode</pre>
  </div>
</body>
</html>
      ''';
    }
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>
    mermaid.initialize({ 
      startOnLoad: true,
      theme: 'default',
      securityLevel: 'loose',
      mindmap: {
        padding: 20,
        maxNodeWidth: 200
      },
      themeVariables: {
        primaryColor: '#6366f1',
        primaryTextColor: '#fff',
        primaryBorderColor: '#4f46e5',
        lineColor: '#94a3b8',
        secondaryColor: '#8b5cf6',
        tertiaryColor: '#ec4899',
        background: '#ffffff',
        mainBkg: '#6366f1',
        secondBkg: '#8b5cf6',
        tertiaryBkg: '#ec4899',
        textColor: '#1e293b',
        fontSize: '16px'
      }
    });
  </script>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      padding: 20px;
    }
    .container {
      flex: 1;
      width: 100%;
      max-width: 1400px;
      margin: 0 auto;
      background: white;
      border-radius: 20px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      padding: 30px;
      display: flex;
      flex-direction: column;
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
      padding-bottom: 20px;
      border-bottom: 3px solid #e2e8f0;
    }
    .header h1 {
      margin: 0;
      color: #1e293b;
      font-size: 28px;
      font-weight: 700;
    }
    .header p {
      margin: 10px 0 0 0;
      color: #64748b;
      font-size: 14px;
    }
    .mermaid-container {
      flex: 1;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 20px;
      background: #f8fafc;
      border-radius: 12px;
      overflow: auto;
    }
    .mermaid {
      width: 100%;
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    /* Mermaid node styling */
    .node rect,
    .node circle,
    .node ellipse,
    .node polygon {
      stroke-width: 2px;
    }
    @media (max-width: 768px) {
      body {
        padding: 10px;
      }
      .container {
        padding: 15px;
      }
      .header h1 {
        font-size: 22px;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📊 Course Mind Map</h1>
      <p>Interactive visual representation of key concepts</p>
    </div>
    <div class="mermaid-container">
      <div class="mermaid">
$cleanCode
      </div>
    </div>
  </div>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
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
                    'Loading mind map...',
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
                      'Error loading mind map',
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

          final mermaidCode = snapshot.data ?? '';
          final htmlContent = _createHtmlContent(mermaidCode);
          
          // Load HTML content
          _controller.loadHtmlString(htmlContent);

          return Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rendering mind map...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
