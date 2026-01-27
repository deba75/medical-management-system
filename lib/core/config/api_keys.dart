/// API Keys Configuration
/// 
/// ⚠️ SECURITY WARNING:
/// In production, use environment variables or secure storage.
/// Never commit real API keys to version control.
/// 
/// To get your Gemini API key:
/// 1. Go to https://aistudio.google.com/app/apikey
/// 2. Sign in with your Google account
/// 3. Create an API key
/// 4. Replace the placeholder below with your key

class ApiKeys {
  // Gemini API key for MediBot chatbot
  static const String geminiApiKey = 'AIzaSyCf7M00ff41AmZHWgeQi8Wvc2-T3TtPcYY';
  
  // Check if API key is configured
  static bool get isGeminiConfigured => 
      geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE';
}
