import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/prescription_template_model.dart';

class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _prescriptionTemplates = 'prescription_templates';
  final String _responseTemplates = 'quick_response_templates';

  // ==================== PRESCRIPTION TEMPLATES ====================

  // Create prescription template
  Future<String> createPrescriptionTemplate(PrescriptionTemplateModel template) async {
    try {
      final docRef = await _firestore.collection(_prescriptionTemplates).add(template.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create prescription template: $e');
    }
  }

  // Get doctor's prescription templates
  Stream<List<PrescriptionTemplateModel>> getPrescriptionTemplates(String doctorId) {
    return _firestore
        .collection(_prescriptionTemplates)
        .where('doctorId', isEqualTo: doctorId)
        .where('isActive', isEqualTo: true)
        .orderBy('usageCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrescriptionTemplateModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get prescription template by ID
  Future<PrescriptionTemplateModel?> getPrescriptionTemplateById(String templateId) async {
    try {
      final doc = await _firestore.collection(_prescriptionTemplates).doc(templateId).get();
      if (doc.exists) {
        return PrescriptionTemplateModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch prescription template: $e');
    }
  }

  // Update prescription template
  Future<void> updatePrescriptionTemplate(String templateId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection(_prescriptionTemplates).doc(templateId).update(updates);
    } catch (e) {
      throw Exception('Failed to update prescription template: $e');
    }
  }

  // Delete prescription template (soft delete)
  Future<void> deletePrescriptionTemplate(String templateId) async {
    try {
      await _firestore.collection(_prescriptionTemplates).doc(templateId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to delete prescription template: $e');
    }
  }

  // Increment usage count
  Future<void> incrementPrescriptionUsage(String templateId) async {
    try {
      await _firestore.collection(_prescriptionTemplates).doc(templateId).update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Search prescription templates by condition
  Future<List<PrescriptionTemplateModel>> searchPrescriptionTemplates(
    String doctorId,
    String query,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_prescriptionTemplates)
          .where('doctorId', isEqualTo: doctorId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => PrescriptionTemplateModel.fromJson(doc.data(), doc.id))
          .where((template) =>
              template.templateName.toLowerCase().contains(query.toLowerCase()) ||
              (template.condition?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    } catch (e) {
      throw Exception('Failed to search prescription templates: $e');
    }
  }

  // ==================== QUICK RESPONSE TEMPLATES ====================

  // Create quick response template
  Future<String> createResponseTemplate(QuickResponseTemplateModel template) async {
    try {
      final docRef = await _firestore.collection(_responseTemplates).add(template.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create response template: $e');
    }
  }

  // Get doctor's response templates
  Stream<List<QuickResponseTemplateModel>> getResponseTemplates(String doctorId) {
    return _firestore
        .collection(_responseTemplates)
        .where('doctorId', isEqualTo: doctorId)
        .where('isActive', isEqualTo: true)
        .orderBy('usageCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuickResponseTemplateModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Alias for getResponseTemplates
  Stream<List<QuickResponseTemplateModel>> getQuickResponses(String doctorId) {
    return getResponseTemplates(doctorId);
  }

  // Alias for createResponseTemplate
  Future<String> createQuickResponse(QuickResponseTemplateModel template) {
    return createResponseTemplate(template);
  }

  // Alias for updateResponseTemplate
  Future<void> updateQuickResponse(String templateId, Map<String, dynamic> updates) {
    return updateResponseTemplate(templateId, updates);
  }

  // Alias for deleteResponseTemplate
  Future<void> deleteQuickResponse(String templateId) {
    return deleteResponseTemplate(templateId);
  }

  // Get response templates by category
  Stream<List<QuickResponseTemplateModel>> getResponseTemplatesByCategory(
    String doctorId,
    String category,
  ) {
    return _firestore
        .collection(_responseTemplates)
        .where('doctorId', isEqualTo: doctorId)
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuickResponseTemplateModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Update response template
  Future<void> updateResponseTemplate(String templateId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_responseTemplates).doc(templateId).update(updates);
    } catch (e) {
      throw Exception('Failed to update response template: $e');
    }
  }

  // Delete response template (soft delete)
  Future<void> deleteResponseTemplate(String templateId) async {
    try {
      await _firestore.collection(_responseTemplates).doc(templateId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to delete response template: $e');
    }
  }

  // Increment response template usage
  Future<void> incrementResponseUsage(String templateId) async {
    try {
      await _firestore.collection(_responseTemplates).doc(templateId).update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Search response templates
  Future<List<QuickResponseTemplateModel>> searchResponseTemplates(
    String doctorId,
    String query,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_responseTemplates)
          .where('doctorId', isEqualTo: doctorId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => QuickResponseTemplateModel.fromJson(doc.data(), doc.id))
          .where((template) =>
              template.title.toLowerCase().contains(query.toLowerCase()) ||
              template.content.toLowerCase().contains(query.toLowerCase()) ||
              template.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      throw Exception('Failed to search response templates: $e');
    }
  }

  // Get default templates (seed data)
  List<Map<String, dynamic>> getDefaultResponseTemplates(String doctorId) {
    return [
      {
        'doctorId': doctorId,
        'title': 'Greeting',
        'content': 'Hello! Thank you for reaching out. How can I help you today?',
        'category': 'greeting',
        'tags': ['greeting', 'welcome'],
        'usageCount': 0,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'doctorId': doctorId,
        'title': 'Follow-up Reminder',
        'content': 'Please remember to follow up with me in 1 week to monitor your progress. If symptoms worsen before then, contact me immediately.',
        'category': 'followup',
        'tags': ['followup', 'reminder'],
        'usageCount': 0,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'doctorId': doctorId,
        'title': 'Rest Advice',
        'content': 'I recommend taking complete rest for the next few days. Ensure adequate hydration and avoid strenuous activities.',
        'category': 'advice',
        'tags': ['rest', 'advice', 'recovery'],
        'usageCount': 0,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'doctorId': doctorId,
        'title': 'Lab Test Required',
        'content': 'Based on your symptoms, I recommend getting some lab tests done. Please visit a diagnostic center at your convenience.',
        'category': 'lab',
        'tags': ['lab', 'test', 'diagnosis'],
        'usageCount': 0,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
  }

  // Seed default templates for a new doctor
  Future<void> seedDefaultTemplates(String doctorId) async {
    final templates = getDefaultResponseTemplates(doctorId);
    for (var template in templates) {
      await _firestore.collection(_responseTemplates).add(template);
    }
  }
}
