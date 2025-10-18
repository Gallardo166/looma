# Supabase Setup Instructions

This Flutter app now supports multiple file uploads to Supabase Storage. Follow these steps to set up your Supabase project:

## 1. Create a Supabase Project

1. Go to [https://app.supabase.com/](https://app.supabase.com/)
2. Sign up or log in to your account
3. Click "New Project"
4. Choose your organization and enter project details:
   - Name: `looma-courses` (or any name you prefer)
   - Database Password: Create a strong password
   - Region: Choose the closest region to your users
5. Click "Create new project"

## 2. Get Your Project Credentials

1. Once your project is created, go to **Settings** > **API**
2. Copy the following values:
   - **Project URL** (looks like: `https://your-project-id.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

## 3. Configure the App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:
   ```dart
   static const String supabaseUrl = 'https://your-project-id.supabase.co';
   static const String supabaseAnonKey = 'eyJ...your-actual-key...';
   ```

## 4. Set Up Storage Bucket

1. In your Supabase dashboard, go to **Storage**
2. Click **Create a new bucket**
3. Enter bucket name: `course-files`
4. Make it **Public** (so files can be accessed via URLs)
5. Click **Create bucket**

## 5. Set Up Storage Policies (Optional but Recommended)

For better security, you can set up Row Level Security (RLS) policies:

1. Go to **Storage** > **Policies**
2. Click **New Policy** for the `course-files` bucket
3. Create policies for:
   - **INSERT**: Allow authenticated users to upload files
   - **SELECT**: Allow anyone to view files (since bucket is public)
   - **UPDATE**: Allow users to update their own files
   - **DELETE**: Allow users to delete their own files

## 6. Test the Setup

1. Run the app: `flutter run`
2. Try adding a new course with multiple files
3. Check if files appear in your Supabase Storage dashboard

## Features Added

- ✅ Multiple file selection and upload
- ✅ Progress indicators during upload
- ✅ Support for various file types (PDF, images, documents, etc.)
- ✅ File preview with icons and sizes
- ✅ Public URLs for file access
- ✅ Error handling and user feedback
- ✅ Backward compatibility with existing single PDF uploads

## File Types Supported

- **Documents**: PDF, DOC, DOCX, TXT
- **Images**: JPG, JPEG, PNG, GIF
- **Videos**: MP4, AVI, MOV
- **Audio**: MP3, WAV
- **Archives**: ZIP, RAR
- **Spreadsheets**: XLS, XLSX
- **Presentations**: PPT, PPTX
- **Other**: Any file type

## Troubleshooting

### Upload Fails
- Check your Supabase credentials in `supabase_config.dart`
- Ensure the `course-files` bucket exists and is public
- Check your internet connection

### Files Not Displaying
- Verify the bucket is set to public
- Check if files were uploaded successfully in Supabase dashboard
- Ensure public URLs are being generated correctly

### App Crashes on Startup
- Make sure you've replaced the placeholder credentials
- Check that your Supabase project is active
- Verify the URL format is correct (should start with `https://`)

## Security Notes

- The anon key is safe to use in client-side applications
- For production, consider implementing user authentication
- Set up proper RLS policies for better security
- Monitor your storage usage and costs
