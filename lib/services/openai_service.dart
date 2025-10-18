import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/openai_config.dart';

class AIProcessingResult {
  final String summary;
  final String mindmap;
  final Uint8List? audioBytes;
  final bool success;
  final String? error;

  AIProcessingResult({
    required this.summary,
    required this.mindmap,
    this.audioBytes,
    required this.success,
    this.error,
  });
}

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
  };

  /// Process uploaded files and generate summary, mindmap, and audio
  Future<AIProcessingResult> processCourseFiles({
    required String courseName,
    required String extractedText,
    Function(String step)? onProgress,
  }) async {
    try {
      onProgress?.call('Analyzing content...');
      
      // Generate summary
      final summary = await _generateSummary(courseName, extractedText);
      onProgress?.call('Creating mindmap...');
      
      // Generate mindmap
      final mindmap = await _generateMindmap(courseName, extractedText);
      onProgress?.call('Generating audio summary...');
      
      // Generate audio summary
      final audioBytes = await _generateAudioSummary(summary);
      onProgress?.call('Processing complete!');
      
      return AIProcessingResult(
        summary: summary,
        mindmap: mindmap,
        audioBytes: audioBytes,
        success: true,
      );
    } catch (e) {
      return AIProcessingResult(
        summary: '',
        mindmap: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Generate a comprehensive summary of the course content
  Future<String> _generateSummary(String courseName, String content) async {
    final prompt = '''
Create a comprehensive summary for the course "$courseName" based on the following content:

$content

Please provide:
1. A clear overview of the main topics covered
2. Key concepts and their explanations
3. Important details and examples
4. Learning objectives
5. Practical applications

Format the summary in a clear, educational manner suitable for students.
''';

    final response = await _makeChatRequest(prompt);
    return response;
  }

  /// Generate a mindmap structure for the course content
  Future<String> _generateMindmap(String courseName, String content) async {
    final prompt = '''
Create a detailed mindmap structure for the course "$courseName" based on the following content:

$content

Please provide a hierarchical mindmap in the following format:
- Main Topic 1
  - Subtopic 1.1
    - Detail 1.1.1
    - Detail 1.1.2
  - Subtopic 1.2
- Main Topic 2
  - Subtopic 2.1
  - Subtopic 2.2

Use indentation with dashes to show the hierarchy. Focus on the most important concepts and their relationships.
''';

    final response = await _makeChatRequest(prompt);
    return response;
  }

  /// Generate audio summary using text-to-speech
  Future<Uint8List?> _generateAudioSummary(String summary) async {
    try {
      // Truncate summary if too long for TTS (limit to ~4000 characters)
      final textForAudio = summary.length > 4000 
          ? '${summary.substring(0, 4000)}... [Summary continues in full text]'
          : summary;

      final requestBody = {
        'model': OpenAIConfig.audioModel,
        'input': textForAudio,
        'voice': 'alloy', // You can change to 'echo', 'fable', 'onyx', 'nova', 'shimmer'
        'response_format': 'mp3',
      };

      final response = await http.post(
        Uri.parse(OpenAIConfig.audioEndpoint),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Audio generation failed: ${response.statusCode}');
      }
    } catch (e) {
      // Return null if audio generation fails, but don't fail the entire process
      return null;
    }
  }

  /// Make a chat completion request to OpenAI
  Future<String> _makeChatRequest(String prompt) async {
    final requestBody = {
      'model': OpenAIConfig.textModel,
      'messages': [
        {
          'role': 'system',
          'content': 'You are an expert educational content analyzer. Provide clear, comprehensive, and well-structured responses for course materials.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'max_tokens': 4000,
      'temperature': 0.7,
    };

    final response = await http.post(
      Uri.parse(OpenAIConfig.chatEndpoint),
      headers: _headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception('OpenAI API request failed: ${response.statusCode} - ${response.body}');
    }
  }
}
