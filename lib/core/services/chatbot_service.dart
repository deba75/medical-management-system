import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatbotService {
  static ChatbotService? _instance;
  GenerativeModel? _model;
  ChatSession? _chat;
  final List<ChatMessage> _messages = [];
  bool _isInitialized = false;

  // Singleton pattern
  static ChatbotService get instance {
    _instance ??= ChatbotService._internal();
    return _instance!;
  }

  ChatbotService._internal();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isInitialized => _isInitialized;

  /// Initialize the chatbot with Gemini API
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final apiKey = ApiKeys.geminiApiKey;
      
      if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        debugPrint('⚠️ Gemini API key not configured. Using demo mode.');
        _isInitialized = true;
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.text('''
You are MediBot, a helpful medical assistant for a telemedicine app called TeleMedicine.

Your primary roles are:
1. **Symptom Assessment**: Help patients describe their symptoms clearly and ask follow-up questions to understand their condition better.

2. **Doctor Recommendations**: Based on symptoms, suggest the appropriate medical specialty:
   - Chest pain, heart issues → Cardiologist
   - Skin problems → Dermatologist
   - Bone/joint pain → Orthopedic
   - Children's health → Pediatrician
   - Mental health → Psychiatrist
   - Eye problems → Ophthalmologist
   - Dental issues → Dentist
   - General issues → General Physician
   - Women's health → Gynecologist
   - Nerve issues → Neurologist

3. **First Aid Guidance**: Provide basic first aid instructions for common situations like:
   - Minor cuts and wounds
   - Burns
   - Fever management
   - Headache relief
   - Allergic reactions

4. **Health Tips**: Offer general health and wellness advice.

IMPORTANT GUIDELINES:
- Always be empathetic and reassuring
- Never diagnose conditions - only suggest possible specialties
- For emergencies (chest pain, difficulty breathing, severe bleeding), immediately advise calling emergency services
- Always recommend booking an appointment with a doctor for proper diagnosis
- Keep responses concise but informative
- Use simple language that patients can understand
- Ask clarifying questions when symptoms are vague

Start by greeting the patient warmly and asking how you can help them today.
'''),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );

      _chat = _model!.startChat();
      _isInitialized = true;
      debugPrint('✅ Chatbot initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing chatbot: $e');
      _isInitialized = true; // Still mark as initialized to use demo mode
    }
  }

  /// Send a message and get a response
  Future<String> sendMessage(String message) async {
    if (message.trim().isEmpty) {
      return 'Please enter a message.';
    }

    // Add user message to history
    _messages.add(ChatMessage(text: message, isUser: true));

    try {
      // Check if API is configured
      if (_model == null || _chat == null) {
        return _getDemoResponse(message);
      }

      final response = await _chat!.sendMessage(Content.text(message));
      final responseText = response.text ?? 'I apologize, but I could not process your request. Please try again.';
      
      // Add bot response to history
      _messages.add(ChatMessage(text: responseText, isUser: false));
      
      return responseText;
    } catch (e) {
      debugPrint('Error sending message: $e');
      final errorResponse = 'I\'m having trouble connecting right now. Please try again in a moment.';
      _messages.add(ChatMessage(text: errorResponse, isUser: false));
      return errorResponse;
    }
  }

  /// Demo response when API is not configured
  String _getDemoResponse(String message) {
    final lowerMessage = message.toLowerCase();
    String response;

    if (lowerMessage.contains('hello') || lowerMessage.contains('hi') || lowerMessage.contains('hey')) {
      response = '''Hello! 👋 I'm MediBot, your medical assistant.

I can help you with:
• Describing your symptoms
• Finding the right doctor specialty
• Basic first aid guidance
• General health tips

How can I assist you today?''';
    } else if (lowerMessage.contains('headache') || lowerMessage.contains('head pain')) {
      response = '''I understand you're experiencing a headache. Let me help you.

**Quick Relief Tips:**
• Rest in a quiet, dark room
• Stay hydrated - drink plenty of water
• Apply a cold compress to your forehead
• Take over-the-counter pain relievers if needed

**When to see a doctor:**
If your headache is severe, sudden, or accompanied by fever, vision changes, or neck stiffness.

**Recommended Specialist:** General Physician or Neurologist

Would you like me to help you find a doctor?''';
    } else if (lowerMessage.contains('fever') || lowerMessage.contains('temperature')) {
      response = '''I'm sorry to hear you have a fever. Here's what you can do:

**Immediate Care:**
• Rest and stay hydrated
• Take paracetamol/acetaminophen as directed
• Use a cool compress on your forehead
• Wear light clothing

**See a doctor if:**
• Fever exceeds 103°F (39.4°C)
• Lasts more than 3 days
• Accompanied by severe symptoms

**Recommended Specialist:** General Physician

Shall I help you book an appointment?''';
    } else if (lowerMessage.contains('chest') || lowerMessage.contains('heart')) {
      response = '''⚠️ **Important:** Chest pain can be serious.

**If you're experiencing:**
• Severe chest pain
• Difficulty breathing
• Pain radiating to arm or jaw

**Please call emergency services immediately!**

For mild discomfort, a **Cardiologist** would be the right specialist.

Are you experiencing severe symptoms right now?''';
    } else if (lowerMessage.contains('skin') || lowerMessage.contains('rash') || lowerMessage.contains('acne')) {
      response = '''For skin-related concerns, I recommend seeing a **Dermatologist**.

**General skin care tips:**
• Keep the area clean and dry
• Avoid scratching
• Use mild, fragrance-free products

Can you describe your skin condition in more detail?''';
    } else if (lowerMessage.contains('doctor') || lowerMessage.contains('appointment') || lowerMessage.contains('book')) {
      response = '''I'd be happy to help you find a doctor! 🏥

To recommend the right specialist, please tell me:
1. What symptoms are you experiencing?
2. How long have you had these symptoms?
3. Any other relevant health information?

Or you can go directly to the **Search Doctors** section in the app to browse available doctors by specialty.''';
    } else if (lowerMessage.contains('emergency') || lowerMessage.contains('urgent')) {
      response = '''🚨 **For Medical Emergencies:**

**Call emergency services immediately!**

**Emergency Numbers:**
• Ambulance: 999 / 112
• Or use the "Book Ambulance" feature in our app

**While waiting:**
• Stay calm
• Don't move if you're injured
• Keep someone with you if possible

Is this an emergency situation?''';
    } else {
      response = '''Thank you for your message. To better assist you, could you please:

1. **Describe your symptoms** in detail
2. **Tell me how long** you've been experiencing them
3. **Mention any medications** you're currently taking

This will help me suggest the right specialist for you.

You can also ask me about:
• First aid tips
• Finding the right doctor
• General health advice''';
    }

    _messages.add(ChatMessage(text: response, isUser: false));
    return response;
  }

  /// Get initial greeting message
  String getGreeting() {
    const greeting = '''Hello! 👋 I'm MediBot, your AI health assistant.

I'm here to help you:
• Understand your symptoms
• Find the right doctor
• Get first aid guidance
• Answer health questions

**Note:** I provide guidance only. For proper diagnosis, please consult a doctor.

How can I assist you today?''';

    if (_messages.isEmpty) {
      _messages.add(ChatMessage(text: greeting, isUser: false));
    }
    
    return greeting;
  }

  /// Clear chat history
  void clearHistory() {
    _messages.clear();
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }

  /// Dispose resources
  void dispose() {
    _messages.clear();
    _chat = null;
    _model = null;
    _isInitialized = false;
    _instance = null;
  }
}
