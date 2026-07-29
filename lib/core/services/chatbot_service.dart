import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_keys.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';
import 'pdf_generator_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;
  final Map<String, dynamic>? metadata;
  final AppointmentModel? appointment;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.type = ChatMessageType.text,
    this.metadata,
    this.appointment,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum ChatMessageType {
  text,
  doctorList,
  appointmentConfirmation,
  appointmentBooked,
}

/// Appointment booking state for multi-step flow
class AppointmentBookingState {
  String? selectedDoctorId;
  String? selectedDoctorName;
  String? selectedSpecialty;
  DateTime? selectedDate;
  String? selectedTimeSlot;
  String? selectedHospital;
  bool awaitingConfirmation;
  
  AppointmentBookingState({
    this.selectedDoctorId,
    this.selectedDoctorName,
    this.selectedSpecialty,
    this.selectedDate,
    this.selectedTimeSlot,
    this.selectedHospital,
    this.awaitingConfirmation = false,
  });
  
  void reset() {
    selectedDoctorId = null;
    selectedDoctorName = null;
    selectedSpecialty = null;
    selectedDate = null;
    selectedTimeSlot = null;
    selectedHospital = null;
    awaitingConfirmation = false;
  }
  
  bool get isComplete => 
    selectedDoctorId != null && 
    selectedDate != null && 
    selectedTimeSlot != null;
}

class ChatbotService {
  static ChatbotService? _instance;
  GenerativeModel? _model;
  ChatSession? _chat;
  final List<ChatMessage> _messages = [];
  bool _isInitialized = false;
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Appointment booking state
  final AppointmentBookingState _bookingState = AppointmentBookingState();

  // Singleton pattern
  static ChatbotService get instance {
    _instance ??= ChatbotService._internal();
    return _instance!;
  }

  ChatbotService._internal();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isInitialized => _isInitialized;
  AppointmentBookingState get bookingState => _bookingState;

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

      debugPrint('🔄 Initializing Gemini with API key: ${apiKey.substring(0, 10)}...');

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.text('''
You are MediBot, a helpful medical assistant for a telemedicine app called MediConnect.

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

5. **Appointment Booking**: Help patients book appointments with doctors. When they want to book:
   - Ask which specialty or doctor they prefer
   - Suggest available dates and time slots
   - Confirm the appointment details before booking
   - Use [BOOK_APPOINTMENT] tag when user confirms booking
   - Use [SHOW_DOCTORS:specialty] tag to show doctor list (e.g., [SHOW_DOCTORS:Cardiologist])
   - Use [CHECK_SCHEDULE:doctorId] tag to check a doctor's available slots

6. **Schedule Information**: Provide doctor availability when asked:
   - Use [GET_SCHEDULE:doctorId] to fetch schedule
   - Tell patients about available slots

SPECIAL COMMANDS (use these in your response when needed):
- [SHOW_DOCTORS:specialty] - Shows list of doctors for that specialty
- [BOOK_APPOINTMENT] - Triggers appointment booking confirmation
- [CONFIRM_BOOKING] - Confirms and books the appointment

IMPORTANT GUIDELINES:
- Always be empathetic and reassuring
- Never diagnose conditions - only suggest possible specialties
- For emergencies (chest pain, difficulty breathing, severe bleeding), immediately advise calling emergency services
- Always recommend booking an appointment with a doctor for proper diagnosis
- Keep responses concise but informative
- Use simple language that patients can understand
- Ask clarifying questions when symptoms are vague
- When booking appointments, always ask for confirmation before finalizing
- FORMATTING INSTRUCTION: Do NOT use markdown bold asterisks like **Heading:**. Use bullet points like • Heading: or bullet lists (• ) for headings, section titles, and tips.

Start by greeting the patient warmly and asking how you can help them today.
'''),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );

      _chat = _model!.startChat();
      _isInitialized = true;
      debugPrint('✅ Chatbot initialized successfully with Gemini API');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing chatbot: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = true; // Still mark as initialized to use demo mode
    }
  }

  /// Get doctors by specialty from Firebase with flexible case-insensitive matching
  Future<List<DoctorModel>> getDoctorsBySpecialty(String specialty) async {
    try {
      final snapshot = await _firestore.collection('doctors').get();
      final lowerSpecialty = specialty.toLowerCase().trim();

      return snapshot.docs
          .map((doc) => DoctorModel.fromJson(doc.data(), doc.id))
          .where((doc) {
            final spec = doc.specialization.toLowerCase();
            final docName = doc.name.toLowerCase();
            return spec.contains(lowerSpecialty) ||
                   docName.contains(lowerSpecialty) ||
                   lowerSpecialty.contains(spec);
          })
          .toList();
    } catch (e) {
      debugPrint('Error fetching doctors by specialty: $e');
      return [];
    }
  }

  /// Get all active doctors from Firebase (full database access)
  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      final snapshot = await _firestore.collection('doctors').get();
      return snapshot.docs
          .map((doc) => DoctorModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all doctors: $e');
      return [];
    }
  }

  /// Get doctor by ID
  Future<DoctorModel?> getDoctorById(String doctorId) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        return DoctorModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching doctor: $e');
      return null;
    }
  }

  /// Get available time slots for a doctor on a specific date
  Future<List<String>> getAvailableSlots(String doctorId, DateTime date) async {
    try {
      // Get doctor's scheduled appointments for that date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final appointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .where('status', isNotEqualTo: 'cancelled')
          .get();
      
      final bookedSlots = appointments.docs
          .map((doc) => doc.data()['timeSlot'] as String)
          .toSet();
      
      // Default available slots (9 AM to 6 PM)
      final allSlots = [
        '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
        '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
        '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
        '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM',
      ];
      
      return allSlots.where((slot) => !bookedSlots.contains(slot)).toList();
    } catch (e) {
      debugPrint('Error fetching available slots: $e');
      return [];
    }
  }

  AppointmentModel? _lastCreatedAppointment;
  AppointmentModel? get lastCreatedAppointment => _lastCreatedAppointment;

  /// Book an appointment
  Future<AppointmentModel?> bookAppointment() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return null;
      }
      
      if (!_bookingState.isComplete) {
        debugPrint('Booking state incomplete');
        return null;
      }

      // Get patient info
      final patientDoc = await _firestore.collection('users').doc(user.uid).get();
      final patientName = patientDoc.data()?['name'] ?? 'Patient';
      
      final docRef = _firestore.collection('appointments').doc();

      // Create appointment
      final appointment = AppointmentModel(
        appointmentId: docRef.id,
        doctorId: _bookingState.selectedDoctorId!,
        patientId: user.uid,
        doctorName: _bookingState.selectedDoctorName ?? 'Doctor',
        patientName: patientName,
        specialization: _bookingState.selectedSpecialty ?? 'General Consultation',
        date: _bookingState.selectedDate ?? DateTime.now(),
        timeSlotId: DateTime.now().millisecondsSinceEpoch.toString(),
        timeSlot: _bookingState.selectedTimeSlot ?? '10:00 AM',
        hospitalName: _bookingState.selectedHospital ?? 'City General Hospital',
        status: AppointmentStatus.upcoming,
        reason: 'Booked via MediBot AI Assistant',
        consultationFee: 500.0,
      );
      
      await docRef.set(appointment.toJson());

      // Send appointment PDF notification to patient
      await PdfGeneratorService.saveAndNotifyAppointmentPdf(appointment);
      
      _lastCreatedAppointment = appointment;

      // Reset booking state
      _bookingState.reset();
      
      return appointment;
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      return null;
    }
  }

  /// Process special commands in bot response
  Future<String> _processSpecialCommands(String response) async {
    String processedResponse = response;
    
    // Check for [SHOW_DOCTORS:specialty] command
    final showDoctorsRegex = RegExp(r'\[SHOW_DOCTORS:([^\]]+)\]');
    final showDoctorsMatch = showDoctorsRegex.firstMatch(response);
    
    if (showDoctorsMatch != null) {
      final specialty = showDoctorsMatch.group(1)!;
      final doctors = await getDoctorsBySpecialty(specialty);
      
      if (doctors.isNotEmpty) {
        String doctorList = '\n\n**Available ${specialty}s:**\n';
        for (int i = 0; i < doctors.length; i++) {
          doctorList += '${i + 1}. **Dr. ${doctors[i].name}**\n';
          doctorList += '   • Fee: ৳${doctors[i].consultationFee.toStringAsFixed(0)}\n';
          doctorList += '   • Rating: ${doctors[i].rating}⭐\n';
          if (doctors[i].hospitals.isNotEmpty) {
            doctorList += '   • Hospital: ${doctors[i].hospital}\n';
          }
        }
        doctorList += '\nWould you like to book an appointment with any of these doctors?';
        processedResponse = processedResponse.replaceAll(showDoctorsMatch.group(0)!, doctorList);
      } else {
        processedResponse = processedResponse.replaceAll(
          showDoctorsMatch.group(0)!, 
          '\n\nNo $specialty doctors are currently available. Would you like to try a different specialty?'
        );
      }
    }
    
    // Check for [BOOK_APPOINTMENT] or [CONFIRM_BOOKING] command
    if (response.contains('[BOOK_APPOINTMENT]') || response.contains('[CONFIRM_BOOKING]')) {
      if (_bookingState.isComplete && _bookingState.awaitingConfirmation) {
        final appointment = await bookAppointment();
        if (appointment != null) {
          processedResponse = processedResponse
              .replaceAll('[BOOK_APPOINTMENT]', '')
              .replaceAll('[CONFIRM_BOOKING]', '');
          processedResponse += '\n\n✅ **Appointment Booked Successfully!**\n📄 PDF Receipt saved to your profile!';
        } else {
          processedResponse = processedResponse
              .replaceAll('[BOOK_APPOINTMENT]', '')
              .replaceAll('[CONFIRM_BOOKING]', '');
          processedResponse += '\n\n❌ Could not book appointment. Please try again.';
        }
      }
    }
    
    return processedResponse;
  }

  /// Send a message and get a response
  Future<String> sendMessage(String message) async {
    if (message.trim().isEmpty) {
      return 'Please enter a message.';
    }

    // Add user message to history
    _messages.add(ChatMessage(text: message, isUser: true));

    try {
      // Handle confirmation responses
      final lowerMessage = message.toLowerCase().trim();
      if (_bookingState.awaitingConfirmation) {
        if (lowerMessage == 'yes' || lowerMessage == 'confirm' || lowerMessage == 'book' || lowerMessage == 'ok') {
          final appointment = await bookAppointment();
          String response;
          if (appointment != null) {
            response = '''✅ **Appointment Booked Successfully!**

Your appointment has been confirmed:
• Doctor: ${appointment.doctorName}
• Date: ${_formatDate(appointment.date)}
• Time: ${appointment.timeSlot}
• Hospital: ${appointment.hospitalName ?? 'City General Hospital'}

📄 **Your Appointment PDF slip has been generated and saved to your profile!**''';
            _messages.add(ChatMessage(text: response, isUser: false, appointment: appointment));
          } else {
            response = '❌ Sorry, I couldn\'t book the appointment. Please try again.';
            _messages.add(ChatMessage(text: response, isUser: false));
          }
          return response;
        } else if (lowerMessage == 'no' || lowerMessage == 'cancel' || lowerMessage == 'nevermind') {
          _bookingState.reset();
          const response = 'No problem! I\'ve cancelled the booking. Is there anything else I can help you with?';
          _messages.add(ChatMessage(text: response, isUser: false));
          return response;
        }
      }

      // Check if API is configured
      if (_model == null || _chat == null) {
        debugPrint('Model or chat is null, using demo response');
        return await _getSmartDemoResponse(message);
      }

      // Add context about available doctors if user is asking about booking
      String contextEnhancedMessage = message;
      if (_shouldFetchDoctorContext(message)) {
        final doctors = await getAllDoctors();
        if (doctors.isNotEmpty) {
          String doctorContext = '\n[CONTEXT: Available doctors in our system: ';
          doctorContext += doctors.map((d) => '${d.name} (${d.specialization})').join(', ');
          doctorContext += ']';
          contextEnhancedMessage = message + doctorContext;
        }
      }

      debugPrint('Sending message to Gemini API...');
      final response = await _chat!.sendMessage(Content.text(contextEnhancedMessage));
      var responseText = response.text ?? 'I apologize, but I could not process your request. Please try again.';
      
      debugPrint('Received response from Gemini API');
      
      // Process any special commands in the response
      responseText = await _processSpecialCommands(responseText);
      
      // Add bot response to history
      _messages.add(ChatMessage(text: responseText, isUser: false));
      
      return responseText;
    } catch (e, stackTrace) {
      debugPrint('❌ Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Try demo response as fallback
      return await _getSmartDemoResponse(message);
    }
  }

  bool _shouldFetchDoctorContext(String message) {
    final keywords = ['book', 'appointment', 'doctor', 'schedule', 'available', 'find'];
    final lower = message.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  /// Smart demo response with Firebase data when API fails
  Future<String> _getSmartDemoResponse(String message) async {
    final lowerMessage = message.toLowerCase();
    String response;

    // Check for appointment/booking related queries
    if (lowerMessage.contains('book') || lowerMessage.contains('appointment')) {
      final doctors = await getAllDoctors();
      if (doctors.isNotEmpty) {
        response = '''I'd be happy to help you book an appointment! 🏥

**Available Doctors:**
''';
        for (int i = 0; i < doctors.take(5).length; i++) {
          response += '''
${i + 1}. **Dr. ${doctors[i].name}** - ${doctors[i].specialization}
   💰 Fee: ৳${doctors[i].consultationFee.toStringAsFixed(0)} | ⭐ ${doctors[i].rating}
''';
        }
        response += '''
Please tell me which doctor you'd like to see, or describe your symptoms and I'll recommend a specialist.''';
      } else {
        response = '''I'd be happy to help you book an appointment! 🏥

To find the right doctor, please tell me:
1. What symptoms are you experiencing?
2. Or which specialty you're looking for?

You can also browse doctors directly in the **Search Doctors** section of the app.''';
      }
    } else if (lowerMessage.contains('doctor') || lowerMessage.contains('find')) {
      // Fetch real doctors from Firebase
      final doctors = await getAllDoctors();
      if (doctors.isNotEmpty) {
        response = '''Here are some doctors available in our system:

''';
        for (int i = 0; i < doctors.take(5).length; i++) {
          response += '''• Dr. ${doctors[i].name}
   • Specialty: ${doctors[i].specialization}
   • Fee: ৳${doctors[i].consultationFee.toStringAsFixed(0)}
   • Rating: ${doctors[i].rating}⭐

''';
        }
        response += 'Would you like to book an appointment with any of these doctors?';
      } else {
        response = '''To find a doctor, you can:

• Browse by Specialty - Go to Search Doctors in the app
• Tell me your symptoms - I'll recommend the right specialist

What symptoms are you experiencing?''';
      }
    } else if (lowerMessage.contains('schedule') || lowerMessage.contains('available') || lowerMessage.contains('slot')) {
      response = '''To check a doctor's schedule:

• Go to Search Doctors in the app
• Select a doctor to view their profile
• Click Book Appointment to see available slots

Or tell me which doctor you're interested in, and I can help you book!''';
    } else if (lowerMessage.contains('headache') || lowerMessage.contains('head pain')) {
      response = '''I understand you're experiencing a headache. Let me help you.

• Quick Relief Tips:
• Rest in a quiet, dark room
• Stay hydrated - drink plenty of water
• Apply a cold compress to your forehead
• Take over-the-counter pain relievers if needed

• When to see a doctor:
If your headache is severe, sudden, or accompanied by fever, vision changes, or neck stiffness.

• Recommended Specialist: General Physician or Neurologist

Would you like me to help you find a doctor and book an appointment?''';
    } else if (lowerMessage.contains('fever') || lowerMessage.contains('temperature')) {
      response = '''I'm sorry to hear you have a fever. Here's what you can do:

• Immediate Care:
• Rest and stay hydrated
• Take paracetamol/acetaminophen as directed
• Use a cool compress on your forehead
• Wear light clothing

• See a doctor if:
• Fever exceeds 103°F (39.4°C)
• Lasts more than 3 days
• Accompanied by severe symptoms

• Recommended Specialist: General Physician

Would you like me to help you book an appointment?''';
    } else if (lowerMessage.contains('emergency') || lowerMessage.contains('urgent')) {
      response = '''🚨 Emergency Guidance:

Call emergency services immediately!

• Emergency Numbers:
• Ambulance: 999 / 112
• Or use the Book Ambulance feature in our app

• While waiting:
• Stay calm
• Don't move if you're injured
• Keep someone with you if possible

Is this an emergency situation?''';
    } else if (lowerMessage.contains('hello') || lowerMessage.contains('hi') || lowerMessage.contains('hey')) {
      response = '''Hello! 👋 I'm MediBot, your medical assistant.

I can help you with:
• 📋 Describing your symptoms
• 👨‍⚕️ Finding the right doctor
• 📅 Booking appointments
• 🩹 Basic first aid guidance
• 💊 General health tips

How can I assist you today?''';
    } else {
      response = '''Thank you for your message. I can help you with:

• Symptom Assessment - Describe what you're feeling
• Find Doctors - I'll recommend specialists based on your needs
• Book Appointments - Schedule a visit with a doctor
• First Aid Tips - Basic guidance for common issues

What would you like help with today?''';
    }

    _messages.add(ChatMessage(text: response, isUser: false));
    return response;
  }

  /// Get initial greeting message
  String getGreeting() {
    const greeting = '''Hello! 👋 I'm MediBot, your AI health assistant.

I'm here to help you:
• 🔍 Understand your symptoms
• 👨‍⚕️ Find the right doctor
• 📅 Book appointments
• 🩹 Get first aid guidance
• 💊 Answer health questions

• Note: I provide guidance only. For proper diagnosis, please consult a doctor.

How can I assist you today?''';

    if (_messages.isEmpty) {
      _messages.add(ChatMessage(text: greeting, isUser: false));
    }
    
    return greeting;
  }

  /// Set booking state for appointment
  void setBookingDoctor(String doctorId, String doctorName, String specialty) {
    _bookingState.selectedDoctorId = doctorId;
    _bookingState.selectedDoctorName = doctorName;
    _bookingState.selectedSpecialty = specialty;
  }

  void setBookingDate(DateTime date) {
    _bookingState.selectedDate = date;
  }

  void setBookingTimeSlot(String timeSlot) {
    _bookingState.selectedTimeSlot = timeSlot;
  }

  void setBookingHospital(String hospital) {
    _bookingState.selectedHospital = hospital;
  }

  void setAwaitingConfirmation(bool value) {
    _bookingState.awaitingConfirmation = value;
  }

  /// Clear chat history
  void clearHistory() {
    _messages.clear();
    _bookingState.reset();
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }

  /// Dispose resources
  void dispose() {
    _messages.clear();
    _bookingState.reset();
    _chat = null;
    _model = null;
    _isInitialized = false;
    _instance = null;
  }
}
