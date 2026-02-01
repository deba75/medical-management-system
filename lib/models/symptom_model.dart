import 'package:cloud_firestore/cloud_firestore.dart';

enum SymptomSeverity { mild, moderate, severe, critical }

class SymptomModel {
  final String id;
  final String name;
  final String description;
  final String bodyPart;
  final List<String> relatedConditions;
  final List<String> recommendedSpecialties;
  final bool requiresUrgentCare;
  final List<String> selfCareAdvice;
  final List<String> warningSignsForER;

  SymptomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.bodyPart,
    required this.relatedConditions,
    required this.recommendedSpecialties,
    required this.requiresUrgentCare,
    required this.selfCareAdvice,
    required this.warningSignsForER,
  });

  factory SymptomModel.fromJson(Map<String, dynamic> json, String id) {
    return SymptomModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      bodyPart: json['bodyPart'] ?? '',
      relatedConditions: List<String>.from(json['relatedConditions'] ?? []),
      recommendedSpecialties: List<String>.from(json['recommendedSpecialties'] ?? []),
      requiresUrgentCare: json['requiresUrgentCare'] ?? false,
      selfCareAdvice: List<String>.from(json['selfCareAdvice'] ?? []),
      warningSignsForER: List<String>.from(json['warningSignsForER'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'bodyPart': bodyPart,
      'relatedConditions': relatedConditions,
      'recommendedSpecialties': recommendedSpecialties,
      'requiresUrgentCare': requiresUrgentCare,
      'selfCareAdvice': selfCareAdvice,
      'warningSignsForER': warningSignsForER,
    };
  }
}

class SymptomCheckSession {
  final String id;
  final String patientId;
  final List<SelectedSymptom> selectedSymptoms;
  final int age;
  final String gender;
  final List<String> preExistingConditions;
  final String? additionalNotes;
  final SymptomAnalysisResult? analysisResult;
  final DateTime createdAt;

  SymptomCheckSession({
    required this.id,
    required this.patientId,
    required this.selectedSymptoms,
    required this.age,
    required this.gender,
    required this.preExistingConditions,
    this.additionalNotes,
    this.analysisResult,
    required this.createdAt,
  });

  factory SymptomCheckSession.fromJson(Map<String, dynamic> json, String id) {
    return SymptomCheckSession(
      id: id,
      patientId: json['patientId'] ?? '',
      selectedSymptoms: (json['selectedSymptoms'] as List<dynamic>?)
              ?.map((e) => SelectedSymptom.fromJson(e))
              .toList() ??
          [],
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      preExistingConditions: List<String>.from(json['preExistingConditions'] ?? []),
      additionalNotes: json['additionalNotes'],
      analysisResult: json['analysisResult'] != null
          ? SymptomAnalysisResult.fromJson(json['analysisResult'])
          : null,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'selectedSymptoms': selectedSymptoms.map((e) => e.toJson()).toList(),
      'age': age,
      'gender': gender,
      'preExistingConditions': preExistingConditions,
      'additionalNotes': additionalNotes,
      'analysisResult': analysisResult?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SelectedSymptom {
  final String symptomId;
  final String symptomName;
  final SymptomSeverity severity;
  final int durationDays;
  final String? additionalInfo;

  SelectedSymptom({
    required this.symptomId,
    required this.symptomName,
    required this.severity,
    required this.durationDays,
    this.additionalInfo,
  });

  factory SelectedSymptom.fromJson(Map<String, dynamic> json) {
    return SelectedSymptom(
      symptomId: json['symptomId'] ?? '',
      symptomName: json['symptomName'] ?? '',
      severity: SymptomSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => SymptomSeverity.mild,
      ),
      durationDays: json['durationDays'] ?? 1,
      additionalInfo: json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptomId': symptomId,
      'symptomName': symptomName,
      'severity': severity.name,
      'durationDays': durationDays,
      'additionalInfo': additionalInfo,
    };
  }

  String get severityDisplay {
    switch (severity) {
      case SymptomSeverity.mild:
        return 'Mild';
      case SymptomSeverity.moderate:
        return 'Moderate';
      case SymptomSeverity.severe:
        return 'Severe';
      case SymptomSeverity.critical:
        return 'Critical';
    }
  }

  String get severityEmoji {
    switch (severity) {
      case SymptomSeverity.mild:
        return '🟢';
      case SymptomSeverity.moderate:
        return '🟡';
      case SymptomSeverity.severe:
        return '🟠';
      case SymptomSeverity.critical:
        return '🔴';
    }
  }
}

class SymptomAnalysisResult {
  final List<PossibleCondition> possibleConditions;
  final List<String> recommendedSpecialties;
  final String urgencyLevel; // low, medium, high, emergency
  final List<String> generalAdvice;
  final bool shouldSeekImmediateCare;
  final String disclaimer;

  SymptomAnalysisResult({
    required this.possibleConditions,
    required this.recommendedSpecialties,
    required this.urgencyLevel,
    required this.generalAdvice,
    required this.shouldSeekImmediateCare,
    required this.disclaimer,
  });

  factory SymptomAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SymptomAnalysisResult(
      possibleConditions: (json['possibleConditions'] as List<dynamic>?)
              ?.map((e) => PossibleCondition.fromJson(e))
              .toList() ??
          [],
      recommendedSpecialties: List<String>.from(json['recommendedSpecialties'] ?? []),
      urgencyLevel: json['urgencyLevel'] ?? 'low',
      generalAdvice: List<String>.from(json['generalAdvice'] ?? []),
      shouldSeekImmediateCare: json['shouldSeekImmediateCare'] ?? false,
      disclaimer: json['disclaimer'] ?? 
          'This is not a medical diagnosis. Please consult a healthcare professional for accurate diagnosis and treatment.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'possibleConditions': possibleConditions.map((e) => e.toJson()).toList(),
      'recommendedSpecialties': recommendedSpecialties,
      'urgencyLevel': urgencyLevel,
      'generalAdvice': generalAdvice,
      'shouldSeekImmediateCare': shouldSeekImmediateCare,
      'disclaimer': disclaimer,
    };
  }

  String get urgencyEmoji {
    switch (urgencyLevel) {
      case 'low':
        return '🟢';
      case 'medium':
        return '🟡';
      case 'high':
        return '🟠';
      case 'emergency':
        return '🔴';
      default:
        return '⚪';
    }
  }
}

class PossibleCondition {
  final String name;
  final String description;
  final double matchScore; // 0-100
  final List<String> matchedSymptoms;

  PossibleCondition({
    required this.name,
    required this.description,
    required this.matchScore,
    required this.matchedSymptoms,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> json) {
    return PossibleCondition(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      matchScore: (json['matchScore'] ?? 0).toDouble(),
      matchedSymptoms: List<String>.from(json['matchedSymptoms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'matchScore': matchScore,
      'matchedSymptoms': matchedSymptoms,
    };
  }
}

// Common symptoms database
class CommonSymptoms {
  static const List<Map<String, dynamic>> symptoms = [
    {
      'name': 'Headache',
      'bodyPart': 'Head',
      'description': 'Pain or discomfort in the head or face area',
    },
    {
      'name': 'Fever',
      'bodyPart': 'General',
      'description': 'Elevated body temperature above normal',
    },
    {
      'name': 'Cough',
      'bodyPart': 'Chest',
      'description': 'Sudden expulsion of air from the lungs',
    },
    {
      'name': 'Fatigue',
      'bodyPart': 'General',
      'description': 'Extreme tiredness or exhaustion',
    },
    {
      'name': 'Nausea',
      'bodyPart': 'Stomach',
      'description': 'Feeling of sickness with urge to vomit',
    },
    {
      'name': 'Chest Pain',
      'bodyPart': 'Chest',
      'description': 'Pain or discomfort in the chest area',
    },
    {
      'name': 'Shortness of Breath',
      'bodyPart': 'Chest',
      'description': 'Difficulty breathing or feeling breathless',
    },
    {
      'name': 'Dizziness',
      'bodyPart': 'Head',
      'description': 'Feeling lightheaded or unsteady',
    },
    {
      'name': 'Back Pain',
      'bodyPart': 'Back',
      'description': 'Pain in the upper, middle, or lower back',
    },
    {
      'name': 'Joint Pain',
      'bodyPart': 'Joints',
      'description': 'Pain, aching, or stiffness in joints',
    },
    {
      'name': 'Sore Throat',
      'bodyPart': 'Throat',
      'description': 'Pain or irritation in the throat',
    },
    {
      'name': 'Runny Nose',
      'bodyPart': 'Nose',
      'description': 'Excess nasal discharge',
    },
    {
      'name': 'Stomach Pain',
      'bodyPart': 'Stomach',
      'description': 'Pain or cramping in the abdominal area',
    },
    {
      'name': 'Diarrhea',
      'bodyPart': 'Stomach',
      'description': 'Loose or watery bowel movements',
    },
    {
      'name': 'Constipation',
      'bodyPart': 'Stomach',
      'description': 'Difficulty passing stools',
    },
    {
      'name': 'Skin Rash',
      'bodyPart': 'Skin',
      'description': 'Change in skin color, texture, or appearance',
    },
    {
      'name': 'Muscle Pain',
      'bodyPart': 'Muscles',
      'description': 'Pain or soreness in muscles',
    },
    {
      'name': 'Anxiety',
      'bodyPart': 'Mental',
      'description': 'Feeling of worry, nervousness, or unease',
    },
    {
      'name': 'Insomnia',
      'bodyPart': 'Mental',
      'description': 'Difficulty falling or staying asleep',
    },
    {
      'name': 'Loss of Appetite',
      'bodyPart': 'General',
      'description': 'Decreased desire to eat',
    },
  ];

  static const List<String> bodyParts = [
    'Head',
    'Throat',
    'Chest',
    'Back',
    'Stomach',
    'Joints',
    'Muscles',
    'Skin',
    'Nose',
    'Eyes',
    'Ears',
    'Mental',
    'General',
  ];
}
