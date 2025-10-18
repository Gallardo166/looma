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
        allowMultiple: false,
        withData: true, // Load file data for web compatibility
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check if we have a valid name
        if (file.name.isNotEmpty) {
          // For web platforms, use bytes instead of path
          String fileIdentifier;
          if (file.path != null && file.path!.isNotEmpty) {
            // Desktop/mobile platforms - use path
            fileIdentifier = file.path!;
          } else {
            // Web platforms - use bytes hash as identifier
            if (file.bytes != null) {
              fileIdentifier = 'web:${file.bytes!.length}_${file.name}';
            } else {
              fileIdentifier = 'selected:${file.name}';
            }
          }
          
          setState(() {
            _selectedPdfPath = fileIdentifier;
            _selectedPdfName = file.name;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF selected: ${file.name}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to access the selected file. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: ${e.toString()}'),
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
      // Validate PDF path if one was selected
      if (_selectedPdfPath != null && _selectedPdfPath!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PDF file. Please select a different file.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final course = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _courseNameController.text.trim(),
        pdfPath: _selectedPdfPath?.isNotEmpty == true ? _selectedPdfPath : null,
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
