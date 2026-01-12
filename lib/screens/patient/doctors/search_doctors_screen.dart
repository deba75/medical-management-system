import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/doctor_model.dart';
import 'doctor_profile_screen.dart';

class SearchDoctorsScreen extends StatefulWidget {
  final String? initialSpecialization;

  const SearchDoctorsScreen({super.key, this.initialSpecialization});

  @override
  State<SearchDoctorsScreen> createState() => _SearchDoctorsScreenState();
}

class _SearchDoctorsScreenState extends State<SearchDoctorsScreen> {
  final _searchController = TextEditingController();
  String? _selectedSpecialization;
  String? _selectedHospital;
  List<DoctorModel> _doctors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSpecialization = widget.initialSpecialization;
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);

    // TODO: Fetch from Firestore with filters
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    _doctors = [
      DoctorModel(
        doctorId: '1',
        userId: '1',
        name: 'Dr. Sarah Johnson',
        specialization: 'Cardiologist',
        hospitals: ['City General Hospital', 'Apollo Hospital'],
        consultationFee: 500,
        rating: 4.8,
        profileBio:
            'Experienced cardiologist with 15 years of practice. Specialized in heart diseases and cardiac care.',
        photoURL: null,
      ),
      DoctorModel(
        doctorId: '2',
        userId: '2',
        name: 'Dr. Michael Chen',
        specialization: 'Dermatologist',
        hospitals: ['Medicare Hospital'],
        consultationFee: 400,
        rating: 4.6,
        profileBio:
            'Board-certified dermatologist focusing on skin care and cosmetic procedures.',
        photoURL: null,
      ),
      DoctorModel(
        doctorId: '3',
        userId: '3',
        name: 'Dr. Emily Brown',
        specialization: 'Pediatrician',
        hospitals: ['Apollo Hospital', 'City General Hospital'],
        consultationFee: 450,
        rating: 4.9,
        profileBio:
            'Caring pediatrician with expertise in child healthcare and development.',
        photoURL: null,
      ),
    ];

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    _loadDoctors();
    Navigator.pop(context);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedSpecialization = null;
                      _selectedHospital = null;
                    });
                  },
                  icon: const Text(
                    'Clear',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Specialization',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSpecialization,
              decoration: const InputDecoration(
                hintText: 'Select specialization',
              ),
              items: AppConstants.specializations
                  .map((spec) => DropdownMenuItem(
                        value: spec,
                        child: Text(spec),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSpecialization = value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Hospital',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedHospital,
              decoration: const InputDecoration(
                hintText: 'Select hospital',
              ),
              items: AppConstants.hospitals
                  .map((hospital) => DropdownMenuItem(
                        value: hospital,
                        child: Text(hospital),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedHospital = value);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, specialization...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadDoctors();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),

          // Active Filters
          if (_selectedSpecialization != null || _selectedHospital != null)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedSpecialization != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_selectedSpecialization!),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _selectedSpecialization = null);
                          _loadDoctors();
                        },
                      ),
                    ),
                  if (_selectedHospital != null)
                    Chip(
                      label: Text(_selectedHospital!),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedHospital = null);
                        _loadDoctors();
                      },
                    ),
                ],
              ),
            ),

          // Doctors List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _doctors.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.person_search,
                        title: 'No doctors found',
                        subtitle:
                            'Try adjusting your filters or search criteria',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _doctors[index];
                          return _DoctorCard(
                            doctor: doctor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DoctorProfileScreen(
                                    doctor: doctor,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const _DoctorCard({
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Doctor Avatar
              CircleAvatar(
                radius: 35,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  doctor.name.split(' ').map((e) => e[0]).take(2).join(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospital,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppTheme.secondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doctor.rating.toString(),
                                style: const TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${doctor.consultationFee}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
