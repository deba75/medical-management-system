import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/doctor_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/doctor_model.dart';
import 'doctor_profile_screen.dart';

class SearchDoctorsScreen extends ConsumerStatefulWidget {
  final String? initialSpecialization;

  const SearchDoctorsScreen({super.key, this.initialSpecialization});

  @override
  ConsumerState<SearchDoctorsScreen> createState() => _SearchDoctorsScreenState();
}

class _SearchDoctorsScreenState extends ConsumerState<SearchDoctorsScreen> {
  final _searchController = TextEditingController();
  String? _selectedSpecialization;
  String? _selectedHospital;

  @override
  void initState() {
    super.initState();
    _selectedSpecialization = widget.initialSpecialization;
    if (widget.initialSpecialization != null) {
      // Set initial search query if specialization is provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(doctorSearchQueryProvider.notifier).state =
            widget.initialSpecialization ?? '';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    // Combine specialization with current search
    String query = _searchController.text;
    if (_selectedSpecialization != null) {
      query = _selectedSpecialization!;
    }
    ref.read(doctorSearchQueryProvider.notifier).state = query;
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
    final doctorsAsync = ref.watch(searchedDoctorsProvider);

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
                          ref.read(doctorSearchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(doctorSearchQueryProvider.notifier).state = value;
                setState(() {});
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
                          ref.read(doctorSearchQueryProvider.notifier).state = 
                              _searchController.text;
                        },
                      ),
                    ),
                  if (_selectedHospital != null)
                    Chip(
                      label: Text(_selectedHospital!),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedHospital = null);
                      },
                    ),
                ],
              ),
            ),

          // Doctors List
          Expanded(
            child: doctorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(searchedDoctorsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (doctors) => doctors.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.person_search,
                      title: 'No doctors found',
                      subtitle: 'Try adjusting your filters or search criteria',
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.refresh(searchedDoctorsProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];
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
