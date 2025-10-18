// Supabase Configuration
// Replace these values with your actual Supabase project credentials

class SupabaseConfig {
  // Get these values from your Supabase project dashboard
  // https://app.supabase.com/project/YOUR_PROJECT/settings/api
  
  static const String supabaseUrl = String.fromEnvironment("SUPABASE_URL");
  static const String supabaseAnonKey = String.fromEnvironment("SUPABASE_ANON_KEY");
  
  // Storage bucket name for course files
  static const String courseFilesBucket = 'course-files';
  
  // Instructions:
  // 1. Go to https://app.supabase.com/
  // 2. Create a new project or select an existing one
  // 3. Go to Settings > API
  // 4. Copy the Project URL and replace 'YOUR_SUPABASE_URL' above
  // 5. Copy the anon/public key and replace 'YOUR_SUPABASE_ANON_KEY' above
  // 6. Go to Storage in your Supabase dashboard
  // 7. Create a new bucket named 'course-files' (or change the bucket name above)
  // 8. Set the bucket to public if you want files to be publicly accessible
}
