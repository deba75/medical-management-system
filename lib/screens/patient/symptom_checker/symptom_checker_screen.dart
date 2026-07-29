import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/symptom_checker_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/symptom_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen> {
  final _symptomService = SymptomCheckerService();
  final _patientId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  int _currentStep = 0;
  List<SymptomModel> _allSymptoms = [];
  final List<SelectedSymptom> _selectedSymptoms = [];
  String _selectedBodyPart = 'All';
  int _age = 30;
  String _gender = 'Male';
  final List<String> _preExistingConditions = [];
  final _notesController = TextEditingController();
  bool _isAnalyzing = false;
  SymptomAnalysisResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  void _loadSymptoms() async {
    final symptoms = await _symptomService.getAllSymptoms();
    setState(() => _allSymptoms = symptoms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppTheme.primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSymptomSelectionStep();
      case 1:
        return _buildPatientInfoStep();
      case 2:
        return _buildReviewStep();
      case 3:
        return _buildResultStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSymptomSelectionStep() {
    final filteredSymptoms = _selectedBodyPart == 'All'
        ? _allSymptoms
        : _allSymptoms.where((s) => s.bodyPart == _selectedBodyPart).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What symptoms are you experiencing?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Select all symptoms that apply',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: CommonSymptoms.bodyParts.length + 1,
            itemBuilder: (context, index) {
              final bodyPart = index == 0 ? 'All' : CommonSymptoms.bodyParts[index - 1];
              final isSelected = _selectedBodyPart == bodyPart;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(
                    bodyPart,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedBodyPart = bodyPart);
                  },
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSymptoms.length,
            itemBuilder: (context, index) {
              return _buildSymptomTile(filteredSymptoms[index]);
            },
          ),
        ),
        if (_selectedSymptoms.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Symptoms:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSymptoms.map((s) {
                    return Chip(
                      label: Text('${s.symptomName} (${s.severityDisplay})'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedSymptoms.removeWhere((x) => x.symptomId == s.symptomId);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSymptomTile(SymptomModel symptom) {
    final isSelected = _selectedSymptoms.any((s) => s.symptomId == symptom.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showSymptomDetailsDialog(symptom),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getBodyPartIcon(symptom.bodyPart),
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symptom.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      symptom.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primaryColor)
              else
                Icon(Icons.add_circle_outline, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showSymptomDetailsDialog(SymptomModel symptom) {
    SymptomSeverity severity = SymptomSeverity.mild;
    int duration = 1;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptom.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  symptom.description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                const Text(
                  'How severe is this symptom?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: SymptomSeverity.values.map((s) {
                    final isSelected = severity == s;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getSeverityEmoji(s)),
                          const SizedBox(width: 4),
                          Text(
                            s.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: s == SymptomSeverity.critical
                          ? Colors.red
                          : s == SymptomSeverity.severe
                              ? Colors.deepOrange
                              : s == SymptomSeverity.moderate
                                  ? Colors.amber.shade900
                                  : AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setModalState(() => severity = s);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'How long have you had this symptom?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: duration > 1
                          ? () => setModalState(() => duration--)
                          : null,
                    ),
                    Text(
                      '$duration ${duration == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setModalState(() => duration++),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Remove if already exists
                        _selectedSymptoms.removeWhere((s) => s.symptomId == symptom.id);
                        // Add with new details
                        _selectedSymptoms.add(SelectedSymptom(
                          symptomId: symptom.id,
                          symptomName: symptom.name,
                          severity: severity,
                          durationDays: duration,
                        ));
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add Symptom'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about yourself',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This helps us provide more accurate analysis',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text('Age', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _age > 1 ? () => setState(() => _age--) : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_age years',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _age++),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female', 'Other'].map((g) {
              final isSelected = _gender == g;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    g,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) => setState(() => _gender = g),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pre-existing Conditions (if any)',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Diabetes',
              'Hypertension',
              'Heart Disease',
              'Asthma',
              'Thyroid',
              'Arthritis',
            ].map((condition) {
              final isSelected = _preExistingConditions.contains(condition);
              return FilterChip(
                label: Text(
                  condition,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor,
                checkmarkColor: Colors.white,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _preExistingConditions.add(condition);
                    } else {
                      _preExistingConditions.remove(condition);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Additional Notes (optional)',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Any other information you\'d like to share...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Your Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please verify before analyzing',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Symptoms',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ..._selectedSymptoms.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(s.severityEmoji),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.symptomName),
                          ),
                          Text(
                            '${s.durationDays} ${s.durationDays == 1 ? 'day' : 'days'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Age', '$_age years'),
                  _buildInfoRow('Gender', _gender),
                  if (_preExistingConditions.isNotEmpty)
                    _buildInfoRow('Conditions', _preExistingConditions.join(', ')),
                  if (_notesController.text.isNotEmpty)
                    _buildInfoRow('Notes', _notesController.text),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This is not a medical diagnosis. Please consult a healthcare professional for accurate diagnosis and treatment.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep() {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Analyzing your symptoms...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_analysisResult == null) {
      return const Center(child: Text('No results available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: _getUrgencyColor(_analysisResult!.urgencyLevel).withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(_analysisResult!.urgencyLevel).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _analysisResult!.urgencyEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Urgency: ${_analysisResult!.urgencyLevel.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _getUrgencyColor(_analysisResult!.urgencyLevel),
                          ),
                        ),
                        if (_analysisResult!.shouldSeekImmediateCare)
                          const Text(
                            'Seek immediate medical attention',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Possible Conditions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._analysisResult!.possibleConditions.map((condition) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            condition.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${condition.matchScore.toInt()}% match',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      condition.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Recommended Specialists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _analysisResult!.recommendedSpecialties.map((specialty) {
              return Chip(
                avatar: const Icon(Icons.person, size: 18),
                label: Text(specialty),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'General Advice',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._analysisResult!.generalAdvice.map((advice) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(advice)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _analysisResult!.disclaimer,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                      _selectedSymptoms.clear();
                      _analysisResult = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start Over'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to find doctors
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Find Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_currentStep == 3) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canProceed() ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _currentStep == 2 ? 'Analyze Symptoms' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedSymptoms.isNotEmpty;
      case 1:
        return true;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() async {
    if (_currentStep == 2) {
      // Analyze symptoms
      setState(() {
        _currentStep = 3;
        _isAnalyzing = true;
      });

      try {
        final result = await _symptomService.analyzeSymptoms(
          _selectedSymptoms,
          _age,
          _gender,
          _preExistingConditions,
        );

        // Save session
        final session = SymptomCheckSession(
          id: '',
          patientId: _patientId,
          selectedSymptoms: _selectedSymptoms,
          age: _age,
          gender: _gender,
          preExistingConditions: _preExistingConditions,
          additionalNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
          analysisResult: result,
          createdAt: DateTime.now(),
        );

        await _symptomService.createSession(session);

        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      } catch (e) {
        setState(() => _isAnalyzing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      setState(() => _currentStep++);
    }
  }

  IconData _getBodyPartIcon(String bodyPart) {
    switch (bodyPart) {
      case 'Head':
        return Icons.face;
      case 'Chest':
        return Icons.favorite;
      case 'Stomach':
        return Icons.restaurant;
      case 'Back':
        return Icons.accessibility_new;
      case 'Joints':
        return Icons.sports_gymnastics;
      case 'Skin':
        return Icons.spa;
      case 'Mental':
        return Icons.psychology;
      default:
        return Icons.local_hospital;
    }
  }

  String _getSeverityEmoji(SymptomSeverity severity) {
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

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
