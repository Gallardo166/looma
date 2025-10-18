import 'package:flutter/material.dart';
import 'models/course.dart';
import 'pages/add_course_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Looma Courses',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CoursesHomePage(),
    );
  }
}

class CoursesHomePage extends StatefulWidget {
  const CoursesHomePage({super.key});

  @override
  State<CoursesHomePage> createState() => _CoursesHomePageState();
}

class _CoursesHomePageState extends State<CoursesHomePage> {
  List<Course> _courses = [];

  void _addCourse(Course course) {
    setState(() {
      _courses.add(course);
    });
  }

  void _navigateToAddCourse() async {
    final result = await Navigator.push<Course>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCoursePage(),
      ),
    );

    if (result != null) {
      _addCourse(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('My Courses'),
        centerTitle: true,
      ),
      body: _courses.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No courses yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first course',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.book_outlined),
                    title: Text(course.name),
                    subtitle: Text('Course ID: ${course.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCourse,
        tooltip: 'Add Course',
        child: const Icon(Icons.add),
      ),
    );
  }
}
