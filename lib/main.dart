import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty ||
      supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    // Fail early with a readable error in debug
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const AuthScreen();
    }
    return const UploadScreen();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signInOrSignUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = await auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        // Create account if sign-in failed
        await auth.signUp(email: email, password: password);
        await auth.signInWithPassword(email: email, password: password);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UploadScreen()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to continue')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _signInOrSignUp,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _uploading = false;
  String? _uploadedUrl;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() {
      _uploading = true;
      _error = null;
      _uploadedUrl = null;
    });
    try {
      // Lazy import to avoid desktop/web specific warnings
      // ignore: avoid_dynamic_calls
      final filePicker = await _loadFilePicker();
      final result = await filePicker();
      if (result == null) {
        setState(() => _uploading = false);
        return;
      }

      final fileBytes = result.bytes!;
      final fileName = result.name;

      final bucket = dotenv.env['SUPABASE_BUCKET'] ?? 'uploads';
      final storage = Supabase.instance.client.storage;
      final String path = _generateObjectPath(fileName);

      final mimeType = _detectMimeType(fileName);

      final uploadResponse = await storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final publicUrl = storage.from(bucket).getPublicUrl(path);

      setState(() {
        _uploadedUrl = publicUrl;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  // Separating these helpers keeps the widget readable
  Future<Future<dynamic> Function()> _loadFilePicker() async {
    // Defer import so tree-shaking selects platform implementation
    // ignore: import_of_legacy_library_into_null_safe
    // ignore: avoid_dynamic_calls
    return () async {
      // Dynamically import file_picker
      // Workaround for code generation: call through a closure
      return await _pickFile();
    };
  }

  Future<_PickedFile?> _pickFile() async {
    // Using package:file_picker interface
    try {
      // ignore: depend_on_referenced_packages
      final filePicker = await FilePicker.platform.pickFiles(withData: true);
      if (filePicker == null || filePicker.files.isEmpty) return null;
      final f = filePicker.files.first;
      if (f.bytes == null) return null;
      return _PickedFile(name: f.name, bytes: f.bytes!);
    } catch (_) {
      rethrow;
    }
  }

  String _generateObjectPath(String originalName) {
    final id = const Uuid().v4();
    final sanitized = originalName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return 'uploads/$id-$sanitized';
  }

  String _detectMimeType(String fileName) {
    final type = lookupMimeType(fileName);
    return type ?? 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload to Supabase Storage'),
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: const Text('Pick file and upload'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_uploadedUrl != null) ...[
              const Text('Uploaded file is publicly accessible at:'),
              const SizedBox(height: 8),
              SelectableText(
                _uploadedUrl!,
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Lightweight model to pass picked data around
class _PickedFile {
  final String name;
  final List<int> bytes;

  _PickedFile({required this.name, required this.bytes});
}
