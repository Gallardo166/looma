import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();

  late SupabaseClient _client;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    _client = Supabase.instance.client;
    _initialized = true;
  }

  SupabaseClient get client {
    if (!_initialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client;
  }

  // Storage bucket name for course files
  static const String courseFilesBucket = SupabaseConfig.courseFilesBucket;

  // Get storage client
  SupabaseStorageClient get storage => client.storage;
}
