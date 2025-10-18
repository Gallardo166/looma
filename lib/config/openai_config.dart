// OpenAI Configuration
// Replace these values with your actual OpenAI API credentials

class OpenAIConfig {
  // Get your API key from https://platform.openai.com/api-keys
  static const String apiKey = String.fromEnvironment("OPENAI_API_KEY");
  
  // OpenAI API endpoints
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatEndpoint = '$baseUrl/chat/completions';
  static const String audioEndpoint = '$baseUrl/audio/speech';
  
  // Model configurations
  static const String textModel = 'gpt-4o-mini'; // Cost-effective model for text processing
  static const String audioModel = 'tts-1'; // Text-to-speech model
  
  // Instructions:
  // 1. Go to https://platform.openai.com/
  // 2. Sign up or log in to your account
  // 3. Go to API Keys section
  // 4. Create a new API key
  // 5. Copy the key and replace 'YOUR_OPENAI_API_KEY' above
  // 6. Make sure you have sufficient credits in your OpenAI account
}
