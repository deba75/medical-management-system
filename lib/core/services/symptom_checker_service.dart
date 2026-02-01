import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/symptom_model.dart';
import '../config/api_keys.dart';

class SymptomCheckerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _sessionsCollection = 'symptom_check_sessions';
  final String _symptomsCollection = 'symptoms';

  // Get all symptoms
  Future<List<SymptomModel>> getAllSymptoms() async {
    try {
      final snapshot = await _firestore.collection(_symptomsCollection).get();

      if (snapshot.docs.isEmpty) {
        // Return default symptoms if none in database
        return CommonSymptoms.symptoms
            .map((s) => SymptomModel(
                  id: s['name'].toString().toLowerCase().replaceAll(' ', '_'),
                  name: s['name'] as String,
                  description: s['description'] as String,
                  bodyPart: s['bodyPart'] as String,
                  relatedConditions: [],
                  recommendedSpecialties: [],
                  requiresUrgentCare: false,
                  selfCareAdvice: [],
                  warningSignsForER: [],
                ))
            .toList();
      }

      return snapshot.docs
          .map((doc) => SymptomModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Return default symptoms on error
      return CommonSymptoms.symptoms
          .map((s) => SymptomModel(
                id: s['name'].toString().toLowerCase().replaceAll(' ', '_'),
                name: s['name'] as String,
                description: s['description'] as String,
                bodyPart: s['bodyPart'] as String,
                relatedConditions: [],
                recommendedSpecialties: [],
                requiresUrgentCare: false,
                selfCareAdvice: [],
                warningSignsForER: [],
              ))
          .toList();
    }
  }

  // Get symptoms by body part
  Future<List<SymptomModel>> getSymptomsByBodyPart(String bodyPart) async {
    final allSymptoms = await getAllSymptoms();
    return allSymptoms.where((s) => s.bodyPart == bodyPart).toList();
  }

  // Create a symptom check session
  Future<String> createSession(SymptomCheckSession session) async {
    try {
      final docRef = await _firestore.collection(_sessionsCollection).add(session.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create symptom check session: $e');
    }
  }

  // Analyze symptoms using AI
  Future<SymptomAnalysisResult> analyzeSymptoms(
    List<SelectedSymptom> symptoms,
    int age,
    String gender,
    List<String> preExistingConditions,
  ) async {
    try {
      // Build prompt for Gemini API
      final symptomsDescription = symptoms
          .map((s) => '- ${s.symptomName} (Severity: ${s.severityDisplay}, Duration: ${s.durationDays} days)')
          .join('\n');

      final prompt = '''
You are a medical assistant AI. Based on the following symptoms and patient information, provide a preliminary analysis.

Patient Information:
- Age: $age years
- Gender: $gender
- Pre-existing conditions: ${preExistingConditions.isEmpty ? 'None' : preExistingConditions.join(', ')}

Reported Symptoms:
$symptomsDescription

Please provide:
1. Up to 3 possible conditions that could explain these symptoms (with confidence score 0-100)
2. Recommended medical specialties to consult
3. Urgency level (low/medium/high/emergency)
4. General self-care advice
5. Whether the patient should seek immediate medical care

IMPORTANT: This is not a diagnosis. Always recommend consulting a healthcare professional.

Respond in JSON format:
{
  "possibleConditions": [
    {"name": "Condition Name", "description": "Brief description", "matchScore": 85, "matchedSymptoms": ["symptom1", "symptom2"]}
  ],
  "recommendedSpecialties": ["Specialty1", "Specialty2"],
  "urgencyLevel": "medium",
  "generalAdvice": ["Advice 1", "Advice 2"],
  "shouldSeekImmediateCare": false
}
''';

      // Call Gemini API
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${ApiKeys.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          final analysisJson = jsonDecode(jsonMatch.group(0)!);
          return SymptomAnalysisResult.fromJson(analysisJson);
        }
      }

      // Fallback result if API fails
      return _generateFallbackAnalysis(symptoms);
    } catch (e) {
      return _generateFallbackAnalysis(symptoms);
    }
  }

  // Generate fallback analysis
  SymptomAnalysisResult _generateFallbackAnalysis(List<SelectedSymptom> symptoms) {
    // Check for emergency symptoms
    final emergencySymptoms = ['Chest Pain', 'Shortness of Breath'];
    final hasEmergency = symptoms.any((s) => 
      emergencySymptoms.contains(s.symptomName) && 
      (s.severity == SymptomSeverity.severe || s.severity == SymptomSeverity.critical)
    );

    // Determine urgency based on severity
    String urgency = 'low';
    if (symptoms.any((s) => s.severity == SymptomSeverity.critical)) {
      urgency = 'emergency';
    } else if (symptoms.any((s) => s.severity == SymptomSeverity.severe)) {
      urgency = 'high';
    } else if (symptoms.any((s) => s.severity == SymptomSeverity.moderate)) {
      urgency = 'medium';
    }

    // Recommend specialties based on symptoms
    Set<String> specialties = {};
    for (var symptom in symptoms) {
      switch (symptom.symptomName.toLowerCase()) {
        case 'headache':
        case 'dizziness':
          specialties.add('Neurologist');
          break;
        case 'chest pain':
        case 'shortness of breath':
          specialties.add('Cardiologist');
          break;
        case 'stomach pain':
        case 'nausea':
        case 'diarrhea':
          specialties.add('Gastroenterologist');
          break;
        case 'joint pain':
        case 'back pain':
          specialties.add('Orthopedist');
          break;
        case 'skin rash':
          specialties.add('Dermatologist');
          break;
        case 'anxiety':
        case 'insomnia':
          specialties.add('Psychiatrist');
          break;
        default:
          specialties.add('General Physician');
      }
    }

    return SymptomAnalysisResult(
      possibleConditions: [
        PossibleCondition(
          name: 'Multiple conditions possible',
          description: 'Your symptoms may indicate various conditions. Please consult a doctor for proper diagnosis.',
          matchScore: 50,
          matchedSymptoms: symptoms.map((s) => s.symptomName).toList(),
        ),
      ],
      recommendedSpecialties: specialties.toList(),
      urgencyLevel: urgency,
      generalAdvice: [
        'Monitor your symptoms closely',
        'Stay hydrated and get adequate rest',
        'Keep a symptom diary to track changes',
        'Consult a doctor if symptoms persist or worsen',
      ],
      shouldSeekImmediateCare: hasEmergency || urgency == 'emergency',
      disclaimer: 'This is an automated preliminary assessment and NOT a medical diagnosis. '
          'Please consult a qualified healthcare professional for proper evaluation and treatment.',
    );
  }

  // Save analysis result
  Future<void> saveAnalysisResult(String sessionId, SymptomAnalysisResult result) async {
    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'analysisResult': result.toJson(),
      });
    } catch (e) {
      throw Exception('Failed to save analysis result: $e');
    }
  }

  // Get patient's symptom check history
  Stream<List<SymptomCheckSession>> getPatientHistory(String patientId) {
    return _firestore
        .collection(_sessionsCollection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SymptomCheckSession.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get session by ID
  Future<SymptomCheckSession?> getSessionById(String sessionId) async {
    try {
      final doc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      if (doc.exists) {
        return SymptomCheckSession.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch session: $e');
    }
  }

  // Seed symptoms database
  Future<void> seedSymptoms() async {
    for (var symptom in CommonSymptoms.symptoms) {
      final id = symptom['name'].toString().toLowerCase().replaceAll(' ', '_');
      await _firestore.collection(_symptomsCollection).doc(id).set({
        'name': symptom['name'],
        'description': symptom['description'],
        'bodyPart': symptom['bodyPart'],
        'relatedConditions': [],
        'recommendedSpecialties': [],
        'requiresUrgentCare': false,
        'selfCareAdvice': [],
        'warningSignsForER': [],
      });
    }
  }
}
