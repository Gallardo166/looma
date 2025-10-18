# OpenAI API Setup Instructions

This Flutter app now includes AI-powered content generation using OpenAI's API. Follow these steps to set up OpenAI integration:

## 1. Create an OpenAI Account

1. Go to [https://platform.openai.com/](https://platform.openai.com/)
2. Sign up for an account or log in if you already have one
3. Verify your email address

## 2. Get Your API Key

1. Once logged in, go to **API Keys** section in your dashboard
2. Click **"Create new secret key"**
3. Give it a name (e.g., "Looma App")
4. Copy the generated API key (starts with `sk-...`)
5. **Important**: Save this key securely - you won't be able to see it again

## 3. Add Credits to Your Account

1. Go to **Billing** section in your OpenAI dashboard
2. Add payment method and credits to your account
3. **Cost estimate**: 
   - Text processing: ~$0.01-0.05 per course
   - Audio generation: ~$0.02-0.10 per course
   - Total per course: ~$0.03-0.15

## 4. Configure the App

1. Open `lib/config/openai_config.dart`
2. Replace the placeholder API key:
   ```dart
   static const String apiKey = 'sk-your-actual-api-key-here';
   ```

## 5. Test the Integration

1. Run the app: `flutter run`
2. Create a new course with some files (PDFs work best)
3. Watch the AI processing in action!

## Features Added

### 🤖 **AI-Powered Content Generation**

- **Summary Generation**: Comprehensive overview of course material
- **Mindmap Creation**: Visual representation of concepts and relationships
- **Audio Summary**: Text-to-speech conversion of key points

### 📁 **File Processing Pipeline**

1. **File Upload**: Original files uploaded to Supabase Storage
2. **Text Extraction**: Extract text from PDFs, documents, and text files
3. **AI Processing**: Send extracted text to OpenAI for analysis
4. **Content Generation**: Create summary, mindmap, and audio files
5. **Storage**: Upload AI-generated content to Supabase

### 🎯 **Supported File Types for AI Processing**

- **PDF files**: Full text extraction and processing
- **Text files**: Direct processing
- **Document files**: Placeholder (would need additional libraries)
- **Image files**: Placeholder (would need OCR integration)

### 🎨 **Enhanced UI Features**

- **Progress Indicators**: Real-time progress during AI processing
- **AI Content Section**: Dedicated section for AI-generated materials
- **Smart Icons**: Different icons for AI-enhanced courses
- **Content Preview**: View AI-generated content in-app
- **Audio Playback**: Play AI-generated audio summaries

## Processing Flow

```
User uploads files
        ↓
Files uploaded to Supabase
        ↓
Text extracted from files
        ↓
Text sent to OpenAI API
        ↓
AI generates: Summary + Mindmap + Audio
        ↓
AI content uploaded to Supabase
        ↓
Course created with all content
```

## Error Handling

- **Graceful Degradation**: If AI processing fails, course is still created with uploaded files
- **User Feedback**: Clear progress indicators and error messages
- **Retry Logic**: Individual file failures don't stop the entire process

## Cost Management

- **Efficient Models**: Uses cost-effective GPT-4o-mini for text processing
- **Content Limits**: Audio summaries truncated if too long
- **Error Recovery**: Failed AI processing doesn't prevent course creation

## Security Notes

- **API Key**: Store securely, never commit to version control
- **Rate Limits**: OpenAI has rate limits - consider implementing queuing for high usage
- **Data Privacy**: Files are processed by OpenAI - ensure compliance with your data policies

## Troubleshooting

### AI Processing Fails
- Check your OpenAI API key is correct
- Verify you have sufficient credits in your account
- Check your internet connection
- Review error messages in the app

### No AI Content Generated
- Ensure uploaded files contain extractable text
- Check if files are in supported formats (PDF, TXT)
- Verify OpenAI API is responding correctly

### High Costs
- Monitor usage in OpenAI dashboard
- Consider implementing content length limits
- Use more efficient prompts if needed

## Future Enhancements

- **OCR Integration**: Extract text from images
- **Document Processing**: Support for Word documents
- **Custom Prompts**: Allow users to customize AI prompts
- **Batch Processing**: Process multiple courses simultaneously
- **Content Caching**: Cache AI responses to reduce costs
