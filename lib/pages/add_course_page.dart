import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/course.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  String? _selectedPdfPath;
  String? _selectedPdfName;

  void _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedPdfPath = result.files.single.path;
          _selectedPdfName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removePdfFile() {
    setState(() {
      _selectedPdfPath = null;
      _selectedPdfName = null;
    });
  }

  void _saveCourse() {
    if (_formKey.currentState!.validate()) {
      final course = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _courseNameController.text.trim(),
        pdfPath: _selectedPdfPath,
      );
      Navigator.pop(context, course);
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Add Course'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'Enter course name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPdfPath != null 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey.shade300,
                    width: _selectedPdfPath != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedPdfPath != null 
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
                      : null,
                ),
                child: _selectedPdfPath != null
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedPdfName!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PDF file attached',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _removePdfFile,
                                icon: const Icon(Icons.close, size: 20),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: _pickPdfFile,
                        borderRadius: BorderRadius.circular(8),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tap to attach PDF',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'or drag and drop',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveCourse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Course',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
