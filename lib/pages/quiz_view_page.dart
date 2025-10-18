import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/course.dart';

class QuizViewPage extends StatefulWidget {
  final CourseFile file;
  final String title;

  const QuizViewPage({
    super.key,
    required this.file,
    required this.title,
  });

  @override
  State<QuizViewPage> createState() => _QuizViewPageState();
}

class _QuizViewPageState extends State<QuizViewPage> {
  Future<String>? _contentFuture;
  Map<int, String>? _userAnswers;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _contentFuture = _getFileContent();
    _userAnswers = {};
  }

  Future<String> _getFileContent() async {
    if (widget.file.publicUrl == null) {
      throw Exception('File URL is not available');
    }

    final response = await http.get(Uri.parse(widget.file.publicUrl!));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load file: ${response.statusCode}');
    }
  }

  void _submitQuiz() {
    setState(() {
      _showResults = true;
    });
  }

  void _resetQuiz() {
    setState(() {
      _userAnswers = {};
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          if (_showResults)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Restart Quiz',
              onPressed: _resetQuiz,
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
                    'Loading quiz...',
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
                      'Error loading quiz',
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
                  ],
                ),
              ),
            );
          }

          final content = snapshot.data ?? '';
          return _buildQuizContent(context, content);
        },
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context, String jsonContent) {
    try {
      final cleanedJson = _extractJsonFromText(jsonContent);
      final Map<String, dynamic> quizData = jsonDecode(cleanedJson);
      final List<dynamic> questions = quizData['questions'] ?? [];

      if (questions.isEmpty) {
        return const Center(
          child: Text('No questions available'),
        );
      }

      final correctCount = _showResults
          ? questions.asMap().entries.where((entry) {
              final question = entry.value;
              final userAnswer = _userAnswers?[entry.key];
              return userAnswer == question['correctAnswer'];
            }).length
          : 0;

      return Column(
        children: [
          if (_showResults) _buildScoreCard(correctCount, questions.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return _buildQuestionCard(
                  context,
                  index,
                  question,
                );
              },
            ),
          ),
          if (!_showResults) _buildSubmitButton(questions.length),
        ],
      );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Error parsing quiz: $e'),
        ),
      );
    }
  }

  String _extractJsonFromText(String text) {
    final startIndex = text.indexOf('{');
    final endIndex = text.lastIndexOf('}');

    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      throw FormatException('No valid JSON found in text');
    }

    return text.substring(startIndex, endIndex + 1);
  }

  Widget _buildScoreCard(int correct, int total) {
    final percentage = (correct / total * 100).round();
    final MaterialColor scoreColor;
    final String scoreEmoji;

    if (percentage >= 80) {
      scoreColor = Colors.green;
      scoreEmoji = '🎉';
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      scoreEmoji = '👍';
    } else {
      scoreColor = Colors.red;
      scoreEmoji = '📚';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.shade100,
            scoreColor.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            scoreEmoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scoreColor.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$correct / $total',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: scoreColor.shade700,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: scoreColor.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    int index,
    Map<String, dynamic> question,
  ) {
    final questionText = question['question'] ?? '';
    final choices = question['choices'] as Map<String, dynamic>? ?? {};
    final correctAnswer = question['correctAnswer'] ?? '';
    final explanation = question['explanation'] ?? '';
    final userAnswer = _userAnswers?[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Choices
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: choices.entries.map((entry) {
                final choice = entry.key;
                final text = entry.value;
                final isSelected = userAnswer == choice;
                final isCorrect = choice == correctAnswer;
                final showCorrectness = _showResults;

                Color? backgroundColor;
                Color? borderColor;
                IconData? icon;

                if (showCorrectness) {
                  if (isCorrect) {
                    backgroundColor = Colors.green.shade50;
                    borderColor = Colors.green.shade400;
                    icon = Icons.check_circle;
                  } else if (isSelected) {
                    backgroundColor = Colors.red.shade50;
                    borderColor = Colors.red.shade400;
                    icon = Icons.cancel;
                  }
                } else if (isSelected) {
                  backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
                  borderColor = Theme.of(context).colorScheme.primary;
                }

                return GestureDetector(
                  onTap: _showResults
                      ? null
                      : () {
                          setState(() {
                            _userAnswers![index] = choice;
                          });
                        },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor ?? Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor ?? Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: borderColor ?? Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: icon != null
                                ? Icon(icon, size: 18, color: Colors.white)
                                : Text(
                                    choice,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Explanation (shown after submission)
          if (_showResults && explanation.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explanation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          explanation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(int totalQuestions) {
    final answeredCount = _userAnswers?.length ?? 0;
    final allAnswered = answeredCount == totalQuestions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!allAnswered)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Answered: $answeredCount / $totalQuestions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: allAnswered ? _submitQuiz : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                allAnswered ? 'Submit Quiz' : 'Answer all questions to submit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
