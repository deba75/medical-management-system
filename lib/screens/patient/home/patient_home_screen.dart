import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/health_monitor_widget.dart';
import '../../../models/hospital_model.dart';
import '../../../models/appointment_model.dart';
import '../doctors/search_doctors_screen.dart';
import '../appointments/my_appointments_screen.dart';
import '../history/medical_history_screen.dart';
import '../prescriptions/prescriptions_screen.dart';
import '../ambulance/book_ambulance_screen.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const MyAppointmentsScreen(),
    const MedicalHistoryScreen(),
    const PrescriptionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_information_outlined),
            selectedIcon: Icon(Icons.medical_information),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined),
            selectedIcon: Icon(Icons.receipt),
            label: 'Prescriptions',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  List<AppointmentModel> _upcomingAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadUpcomingAppointments();
  }

  Future<void> _loadUpcomingAppointments() async {
    // TODO: Fetch from Firestore
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock upcoming appointments
    setState(() {
      _upcomingAppointments = [
        AppointmentModel(
          appointmentId: '1',
          doctorId: 'doc1',
          patientId: 'current_patient',
          doctorName: 'Dr. Sarah Johnson',
          patientName: 'Current Patient',
          specialization: 'Cardiologist',
          date: DateTime.now().add(const Duration(hours: 2)),
          timeSlotId: '1',
          timeSlot: '14:00 - 14:30',
          status: AppointmentStatus.upcoming,
          reason: 'Regular checkup',
        ),
        AppointmentModel(
          appointmentId: '2',
          doctorId: 'doc2',
          patientId: 'current_patient',
          doctorName: 'Dr. Michael Chen',
          patientName: 'Current Patient',
          specialization: 'Dentist',
          date: DateTime.now().add(const Duration(days: 1)),
          timeSlotId: '2',
          timeSlot: '10:00 - 10:30',
          status: AppointmentStatus.upcoming,
          reason: 'Dental cleaning',
        ),
      ];
    });
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProfileMenuSheet(),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NotificationsSheet(appointments: _upcomingAppointments),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.when(
                data: (userData) => 'Hello, ${userData?.name ?? 'Patient'}',
                loading: () => 'Hello, Patient',
                error: (_, __) => 'Hello, Patient',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'How can we help you today?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotifications(context),
              ),
              if (_upcomingAppointments.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_upcomingAppointments.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _showProfileMenu(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchDoctorsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search doctors, specializations...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Health Monitor Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HealthMonitorWidget(),
            ),
            const SizedBox(height: 24),

            // Emergency Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.errorColor,
                      AppTheme.errorColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Book an ambulance now',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookAmbulanceScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _QuickActionCard(
                  icon: Icons.person_search,
                  title: 'Find Doctors',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchDoctorsScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.calendar_today,
                  title: 'My Appointments',
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    // Switch to appointments tab
                  },
                ),
                _QuickActionCard(
                  icon: Icons.receipt_long,
                  title: 'Prescriptions',
                  color: AppTheme.accentColor,
                  onTap: () {
                    // Switch to prescriptions tab
                  },
                ),
                _QuickActionCard(
                  icon: Icons.medical_information,
                  title: 'Medical History',
                  color: Colors.purple,
                  onTap: () {
                    // Switch to history tab
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Popular Specializations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Popular Specializations',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AppConstants.specializations.length,
                itemBuilder: (context, index) {
                  final specialization = AppConstants.specializations[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _SpecializationCard(
                      specialization: specialization,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchDoctorsScreen(
                              initialSpecialization: specialization,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Nearby Hospitals
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Hospitals',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all hospitals
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _mockHospitals.length,
                itemBuilder: (context, index) {
                  final hospital = _mockHospitals[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _HospitalCard(hospital: hospital),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Mock data for hospitals
final List<Hospital> _mockHospitals = [
  Hospital(
    id: '1',
    name: 'City General Hospital',
    address: '123 Main Street',
    city: 'Dhaka',
    phone: '+880 1234-567890',
    email: 'info@citygeneral.com',
    imageUrl: 'https://via.placeholder.com/300x200',
    rating: 4.5,
    totalReviews: 1250,
    specialties: ['Emergency', 'Cardiology', 'Neurology', 'Pediatrics'],
    isEmergencyAvailable: true,
    description: 'Leading multi-specialty hospital with 24/7 emergency services',
  ),
  Hospital(
    id: '2',
    name: 'Medicare Center',
    address: '456 Park Avenue',
    city: 'Dhaka',
    phone: '+880 1234-567891',
    email: 'contact@medicare.com',
    imageUrl: 'https://via.placeholder.com/300x200',
    rating: 4.3,
    totalReviews: 890,
    specialties: ['Orthopedics', 'General Surgery', 'ICU'],
    isEmergencyAvailable: true,
    description: 'Specialized care with modern facilities',
  ),
  Hospital(
    id: '3',
    name: 'Hope Medical Center',
    address: '789 Health Lane',
    city: 'Dhaka',
    phone: '+880 1234-567892',
    email: 'info@hopemedical.com',
    imageUrl: 'https://via.placeholder.com/300x200',
    rating: 4.7,
    totalReviews: 1560,
    specialties: ['Cancer Care', 'Radiology', 'Pathology'],
    isEmergencyAvailable: false,
    description: 'Advanced diagnostic and treatment center',
  ),
  Hospital(
    id: '4',
    name: 'Green Valley Hospital',
    address: '321 Wellness Road',
    city: 'Dhaka',
    phone: '+880 1234-567893',
    email: 'contact@greenvalley.com',
    imageUrl: 'https://via.placeholder.com/300x200',
    rating: 4.4,
    totalReviews: 1020,
    specialties: ['Maternity', 'Pediatrics', 'Women\'s Health'],
    isEmergencyAvailable: true,
    description: 'Family-focused healthcare with compassionate care',
  ),
];

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecializationCard extends StatelessWidget {
  final String specialization;
  final VoidCallback onTap;

  const _SpecializationCard({
    required this.specialization,
    required this.onTap,
  });

  IconData _getIconForSpecialization(String specialization) {
    switch (specialization) {
      case 'Cardiologist':
        return Icons.favorite;
      case 'Dermatologist':
        return Icons.face;
      case 'Neurologist':
        return Icons.psychology;
      case 'Orthopedic':
        return Icons.accessibility_new;
      case 'Pediatrician':
        return Icons.child_care;
      case 'Psychiatrist':
        return Icons.mood;
      case 'General Physician':
        return Icons.medical_services;
      case 'ENT Specialist':
        return Icons.hearing;
      case 'Ophthalmologist':
        return Icons.remove_red_eye;
      case 'Dentist':
        return Icons.medical_information;
      default:
        return Icons.local_hospital;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForSpecialization(specialization),
              size: 36,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              specialization,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;

  const _HospitalCard({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to hospital details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View ${hospital.name} details')),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital Image
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.local_hospital,
                      size: 48,
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  if (hospital.isEmergencyAvailable)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emergency,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '24/7',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Hospital Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hospital.city,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hospital.rating.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: hospital.specialties.take(2).map((specialty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          specialty,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Menu Bottom Sheet
class _ProfileMenuSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeNotifier = ref.watch(themeModeProvider.notifier);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Profile Section
          user.when(
            data: (userData) => Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    userData?.name.substring(0, 1).toUpperCase() ?? 'P',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userData?.name ?? 'Patient',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  userData?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Icon(Icons.error),
          ),
          const SizedBox(height: 24),
          
          // Theme Toggle
          ListTile(
            leading: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                themeNotifier.toggleTheme();
              },
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).colorScheme.surface,
          ),
          const SizedBox(height: 12),
          
          // Profile Settings
          ListTile(
            leading: const Icon(Icons.settings, color: AppTheme.primaryColor),
            title: const Text('Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).colorScheme.surface,
          ),
          const SizedBox(height: 12),
          
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (shouldLogout == true && context.mounted) {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                }
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: AppTheme.errorColor.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Notifications Bottom Sheet
class _NotificationsSheet extends StatelessWidget {
  final List<AppointmentModel> appointments;
  
  const _NotificationsSheet({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Upcoming Appointments',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Appointments List
          if (appointments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No upcoming appointments',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final isToday = appointment.date.day == DateTime.now().day &&
                    appointment.date.month == DateTime.now().month &&
                    appointment.date.year == DateTime.now().year;
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  appointment.doctorName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Today',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment.specialization,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.timeSlot,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
