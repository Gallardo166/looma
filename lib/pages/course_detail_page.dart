import 'package:flutter/material.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Section
            _buildSection(
              context,
              title: 'Summary of Content',
              icon: Icons.summarize_outlined,
              description: 'Get a comprehensive overview of the course material',
              onTap: () {
                _showComingSoon(context, 'Summary');
              },
            ),
            const SizedBox(height: 16),
            
            // Mindmap Section
            _buildSection(
              context,
              title: 'Mindmap of Content',
              icon: Icons.account_tree_outlined,
              description: 'Visual representation of course concepts and connections',
              onTap: () {
                _showComingSoon(context, 'Mindmap');
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
              description: 'Listen to audio summaries and key points',
              onTap: () {
                _showComingSoon(context, 'Audio Recap');
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
