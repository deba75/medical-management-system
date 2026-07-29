import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../../models/diagnostic_centre_model.dart';
import '../../diagnostic_centre/diagnostic_centre_dashboard_screen.dart';
import 'diagnostic_centre_detail_screen.dart';

class DiagnosticCentresScreen extends ConsumerStatefulWidget {
  const DiagnosticCentresScreen({super.key});

  @override
  ConsumerState<DiagnosticCentresScreen> createState() =>
      _DiagnosticCentresScreenState();
}

class _DiagnosticCentresScreenState
    extends ConsumerState<DiagnosticCentresScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<DiagnosticCentreModel> _centres = [];
  List<DiagnosticCentreModel> _filteredCentres = [];

  @override
  void initState() {
    super.initState();
    _loadDiagnosticCentres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnosticCentres() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('diagnostic_centres')
          .where('status', isEqualTo: 'active')
          .get();

      if (snapshot.docs.isNotEmpty) {
        _centres = snapshot.docs
            .map((doc) => DiagnosticCentreModel.fromJson(doc.data(), doc.id))
            .toList();
      } else {
        // Load mock data if no centres in database
        _loadMockData();
      }
      
      _filteredCentres = _centres;
    } catch (e) {
      debugPrint('Error loading diagnostic centres: $e');
      _loadMockData();
    }
    
    setState(() => _isLoading = false);
  }

  void _loadMockData() {
    _centres = [
      DiagnosticCentreModel(
        centreId: '1',
        name: 'Popular Diagnostic Centre',
        address: 'House 16, Road 2, Dhanmondi',
        city: 'Dhaka',
        contactNumber: '+880 1712-345678',
        tests: [
          DiagnosticTest(testId: '1', testName: 'Complete Blood Count (CBC)', category: 'Blood Test', price: 450),
          DiagnosticTest(testId: '2', testName: 'Blood Sugar (Fasting)', category: 'Blood Test', price: 200),
          DiagnosticTest(testId: '3', testName: 'Lipid Profile', category: 'Blood Test', price: 1200),
          DiagnosticTest(testId: '4', testName: 'Liver Function Test (LFT)', category: 'Blood Test', price: 1500),
          DiagnosticTest(testId: '5', testName: 'X-Ray (Chest)', category: 'Radiology', price: 800),
          DiagnosticTest(testId: '6', testName: 'MRI (Brain)', category: 'Radiology', price: 8000),
          DiagnosticTest(testId: '7', testName: 'Ultrasound (Whole Abdomen)', category: 'Ultrasound', price: 2000),
          DiagnosticTest(testId: '8', testName: 'ECG', category: 'Cardiology', price: 500),
        ],
        status: DiagnosticCentreStatus.active,
      ),
      DiagnosticCentreModel(
        centreId: '2',
        name: 'Ibn Sina Diagnostic',
        address: 'House 48, Road 9/A, Dhanmondi',
        city: 'Dhaka',
        contactNumber: '+880 1812-345679',
        tests: [
          DiagnosticTest(testId: '11', testName: 'Complete Blood Count (CBC)', category: 'Blood Test', price: 400),
          DiagnosticTest(testId: '12', testName: 'Thyroid Profile (T3, T4, TSH)', category: 'Blood Test', price: 1800),
          DiagnosticTest(testId: '13', testName: 'HbA1c (Diabetes)', category: 'Blood Test', price: 800),
          DiagnosticTest(testId: '14', testName: 'Vitamin D', category: 'Blood Test', price: 2500),
          DiagnosticTest(testId: '15', testName: 'Endoscopy', category: 'Gastroenterology', price: 5000),
        ],
        status: DiagnosticCentreStatus.active,
      ),
      DiagnosticCentreModel(
        centreId: '3',
        name: 'Labaid Diagnostic',
        address: 'House 1, Road 4, Dhanmondi',
        city: 'Dhaka',
        contactNumber: '+880 1912-345680',
        tests: [
          DiagnosticTest(testId: '17', testName: 'Complete Blood Count (CBC)', category: 'Blood Test', price: 380),
          DiagnosticTest(testId: '18', testName: 'Urine R/E', category: 'Pathology', price: 150),
          DiagnosticTest(testId: '19', testName: 'Kidney Function Test (KFT)', category: 'Blood Test', price: 1400),
          DiagnosticTest(testId: '20', testName: 'CT Scan', category: 'Radiology', price: 6000),
        ],
        status: DiagnosticCentreStatus.active,
      ),
      DiagnosticCentreModel(
        centreId: '4',
        name: 'Square Diagnostic Centre',
        address: 'West Panthapath',
        city: 'Dhaka',
        contactNumber: '+880 1612-345681',
        tests: [
          DiagnosticTest(testId: '21', testName: 'Complete Blood Count (CBC)', category: 'Blood Test', price: 500),
          DiagnosticTest(testId: '22', testName: 'Echo Cardiogram', category: 'Cardiology', price: 3500),
          DiagnosticTest(testId: '23', testName: 'Colonoscopy', category: 'Gastroenterology', price: 7000),
          DiagnosticTest(testId: '24', testName: 'Vitamin B12', category: 'Blood Test', price: 1800),
        ],
        status: DiagnosticCentreStatus.active,
      ),
    ];
  }

  void _filterCentres(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCentres = _centres;
      } else {
        _filteredCentres = _centres.where((centre) {
          return centre.name.toLowerCase().contains(query.toLowerCase()) ||
              centre.city.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diagnostic Centres',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            tooltip: 'Diagnostic Admin Portal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DiagnosticCentreDashboardScreen(),
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCentres,
              decoration: InputDecoration(
                hintText: 'Search diagnostic centres...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCentres('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Info Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap on a centre to view available tests and prices',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Centres List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCentres.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.local_hospital_outlined,
                        title: 'No Diagnostic Centres Found',
                        subtitle: 'Try adjusting your search',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDiagnosticCentres,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCentres.length,
                          itemBuilder: (context, index) {
                            final centre = _filteredCentres[index];
                            return _buildCentreListItem(centre);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentreListItem(DiagnosticCentreModel centre) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiagnosticCentreDetailScreen(centre: centre),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.biotech,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Name and Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      centre.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${centre.address}, ${centre.city}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Tests count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${centre.tests.length} tests available',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
