import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/openai_config.dart';

class AIProcessingResult {
  final String summary;
  final String mindmap;
  final String quiz;
  final Uint8List? audioBytes;
  final bool success;
  final String? error;

  AIProcessingResult({
    required this.summary,
    required this.mindmap,
    required this.quiz,
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

  /// Process uploaded files and generate summary, mindmap, quiz, and audio
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
      onProgress?.call('Generating quiz questions...');
      
      // Generate quiz
      final quiz = await _generateQuiz(courseName, extractedText);
      onProgress?.call('Generating audio summary...');
      
      // Generate audio summary
      final audioBytes = await _generateAudioSummary(summary);
      onProgress?.call('Processing complete!');
      
      return AIProcessingResult(
        summary: summary,
        mindmap: mindmap,
        quiz: quiz,
        audioBytes: audioBytes,
        success: true,
      );
    } catch (e) {
      return AIProcessingResult(
        summary: '',
        mindmap: '',
        quiz: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Generate a comprehensive summary of the course content
  Future<String> _generateSummary(String courseName, String content) async {
    final prompt = '''
You are an AI that summarizes university lecture notes, from $content. 
- Extract the main topic.
- Generate concise bullet points under each subtopic.
- Create 3-5 review questions for topic.
- Provide a 2-3 sentence summary at the end.
- Use the Cornell Notes format: Cue column, Notes column, Summary.

Rules:
- Only use information present in $content
- Keep numbers and dates exactly as they appear
- Ignore images, headers, and footers
- Return output strictly in the following JSON format:

{
  "Topic": "",
  "Cue": "",
  "Notes": "",
  "Summary": ""
}

Here is an example:
{
  "Topic": "CS2030S Good-to-Knows",

  "Cue": 
  "- What are the primitive type hierarchies in Java?\n- What are primitive wrapper classes?\n- What is the difference between method overriding and overloading?\n- What is the function of 'final' in Java classes, methods, and fields?\n- What are the rules for abstract classes and interfaces?\n- What are the exception handling rules in method overriding?\n- What is a bridge method and when is it used?",

  "Notes": 
  "- Primitive type hierarchy: byte <: short <: int <: long <: float <: double; char <: int.\n- Primitive wrapper classes are immutable.\n- A reference value not initialized has the special value 'null'; using it causes NullPointerException.\n- Stack behavior: static methods have no 'this'; non-static and constructors have 'this'. When a method returns, its call frame is removed, but heap memory persists if referenced.\n- Method signature: name + number, type, and order of parameters.\n- Method descriptor = method signature + return type.\n\nOverriding:\n- Must have the same method descriptor.\n- Subclass return type <: parent return type (covariant returns).\n- Return types must be compatible (not for primitives).\n- Cannot override static methods.\n\nOverloading:\n- Methods with same name but different signatures in same class.\n- Can overload static methods and constructors.\n\n'final' keyword:\n- final class → prevents inheritance.\n- final method → prevents overriding.\n- final field → prevents reassignment.\n\nAbstract classes:\n- Cannot be instantiated.\n- Must be declared abstract if it has at least one abstract method.\n- May have no abstract methods.\n\nGenerics and arrays:\n- 'new Pair<S,T>[2]' and 'new T[2]' are illegal.\n- 'T[] array;' is allowed.\n\nInterfaces:\n- Classes can implement interfaces (e.g., class B implements I).\n\nAutoboxing/unboxing:\n- Integer i = 4 (autoboxing), int j = 1 (unboxing).\n\nException handling:\n- Catch blocks: handle subtypes before supertypes; otherwise causes compilation error.\n- Overriding methods must throw the same or a more specific checked exception, following Liskov Substitution Principle.\n\nPolymorphism and type casting:\n- Widening conversions (e.g., I i1 = new B();) compile.\n- Some casts (e.g., A a = (A) new B();) may not compile if no subtype relationship.\n\nBridge methods:\n- Used by compiler to ensure correct overriding with generics (e.g., B::fun(String) overrides A::fun(T)).\n- Bridge method calls the correct version (A::fun(Object)) when generics are involved.",

  "Summary": 
  "This section summarizes Java fundamentals relevant to CS2030S, including primitive types, method behavior, inheritance rules, and exception handling. It distinguishes overriding from overloading, explains how 'final' and 'abstract' modify inheritance, and clarifies the role of bridge methods in generics. The key takeaway is understanding how Java enforces type safety and polymorphism rules at both compile-time and runtime."
}
''';

    final response = await _makeChatRequest(prompt);
    return response;
  }

  /// Generate a mindmap structure for the course content in Mermaid format
  Future<String> _generateMindmap(String courseName, String content) async {
    final prompt = '''
Create a mind map for "$courseName" from this content: $content

CRITICAL: Return ONLY the Mermaid code. No explanation, no markdown blocks, no extra text.

Format:
mindmap
  root((Main Topic))
    Branch1
      Item1
      Item2
    Branch2
      Item3

Rules:
- Start with exactly "mindmap"
- Use root((Topic Name)) for center
- 3-5 main branches
- 2-4 items per branch  
- Max 3 words per node
- NO markdown blocks
- NO explanation text
- ONLY return the mermaid code

Example:
mindmap
  root((Photosynthesis))
    Light Reactions
      Chlorophyll
      ATP Production
    Calvin Cycle
      Carbon Fixation
      Glucose Formation
    Environmental Factors
      Light Intensity
      Temperature
''';

    final response = await _makeChatRequest(prompt);
    return response;
  }

  /// Generate quiz questions for the course content
  Future<String> _generateQuiz(String courseName, String content) async {
    final prompt = '''
Create 10 multiple-choice questions based on the following course content:

$content

Rules:
- Generate exactly 10 questions
- Each question must have 4 answer choices (A, B, C, D)
- Only one answer should be correct
- Questions should test understanding of key concepts
- Include a mix of difficulty levels
- Return output strictly in the following JSON format:

{
  "questions": [
    {
      "question": "Question text here?",
      "choices": {
        "A": "First choice",
        "B": "Second choice",
        "C": "Third choice",
        "D": "Fourth choice"
      },
      "correctAnswer": "A",
      "explanation": "Brief explanation of why this is correct"
    }
  ]
}
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
