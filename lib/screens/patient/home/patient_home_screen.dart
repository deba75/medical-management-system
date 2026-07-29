import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../core/widgets/health_monitor_widget.dart';
import '../../../models/hospital_model.dart';
import '../../../models/appointment_model.dart';
import '../doctors/search_doctors_screen.dart';
import '../appointments/my_appointments_screen.dart';
import '../history/medical_history_screen.dart';
import '../prescriptions/prescriptions_screen.dart';
import '../diagnostic/diagnostic_centres_screen.dart';
import '../chat/chatbot_screen.dart';
import '../medicine_reminder/medicine_reminder_screen.dart';
import '../lab_test/lab_test_booking_screen.dart';
import '../articles/health_articles_screen.dart';
import '../symptom_checker/symptom_checker_screen.dart';
import '../blood_donors/blood_donors_screen.dart';
import '../profile/family_members_screen.dart';
import '../../doctor/settings/settings_screen.dart';

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
      floatingActionButton: _selectedIndex == 0 ? _buildChatbotFAB(context) : null,
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

  Widget _buildChatbotFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const ChatbotScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
        ),
        label: const Text(
          'MediBot',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
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
  // Appointments are now managed by Riverpod provider
  
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
    final upcomingAppointments = ref.read(upcomingAppointmentsProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NotificationsSheet(appointments: upcomingAppointments),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final upcomingAppointments = ref.watch(upcomingAppointmentsProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom AppBar with gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            // Title shown when collapsed
            title: const Text(
              'MediConnect',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            // Actions shown when collapsed AND expanded
            actions: [
              _buildHeaderIconButton(
                context,
                Icons.notifications_outlined,
                upcomingAppointments.length,
                () => _showNotifications(context),
              ),
              const SizedBox(width: 4),
              _buildHeaderIconButton(
                context,
                Icons.person_outline,
                0,
                () => _showProfileMenu(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.when(
                            data: (userData) => 'Hello, ${userData?.name ?? 'Patient'} 👋',
                            loading: () => 'Hello, Patient 👋',
                            error: (_, __) => 'Hello, Patient 👋',
                          ),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        user.when(
                          data: (userData) {
                            if (userData?.patientId != null) {
                              return Row(
                                children: [
                                  Text(
                                    'Your ID: ${userData!.patientId}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.copy, size: 16, color: Colors.white.withOpacity(0.9)),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: userData.patientId!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Patient ID copied to clipboard')),
                                      );
                                    },
                                  )
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How can we help you today?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
          
          // Body Content
          SliverToBoxAdapter(
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
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.search,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search doctors, specializations...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.tune,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            size: 20,
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



            // Diagnostic Centre Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondaryColor,
                      AppTheme.secondaryColor.withOpacity(0.8),
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
                        Icons.biotech,
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
                            'Diagnostic Centres',
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
                            'Find tests & health checkups',
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
                            builder: (context) => const DiagnosticCentresScreen(),
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
                  icon: Icons.health_and_safety,
                  title: 'Symptom Checker',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SymptomCheckerScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.medication,
                  title: 'Medicine Reminder',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicineReminderScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.science,
                  title: 'Lab Tests',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LabTestBookingScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.article,
                  title: 'Health Articles',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthArticlesScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.bloodtype,
                  title: 'Blood Donors',
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodDonorsScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.family_restroom,
                  title: 'Family Members',
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyMembersScreen(),
                      ),
                    );
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
        ],
      ),
    );
  }
  
  Widget _buildHeaderIconButton(
    BuildContext context,
    IconData icon,
    int badgeCount,
    VoidCallback onPressed,
  ) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$badgeCount',
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForSpecialization(specialization),
              size: 36,
              color: Theme.of(context).colorScheme.primary,
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

  void _showHospitalDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HospitalDetailsSheet(hospital: hospital),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHospitalDetails(context),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital Image
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
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

// Hospital Details Bottom Sheet
class _HospitalDetailsSheet extends StatelessWidget {
  final Hospital hospital;

  const _HospitalDetailsSheet({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Hospital Image/Header
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.local_hospital,
                            size: 80,
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        if (hospital.isEmergencyAvailable)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.emergency, size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    '24/7 Emergency',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hospital Name
                  Text(
                    hospital.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < hospital.rating.floor()
                              ? Icons.star
                              : (index < hospital.rating ? Icons.star_half : Icons.star_border),
                          color: AppTheme.accentColor,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${hospital.rating}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        ' (${hospital.totalReviews} reviews)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (hospital.description.isNotEmpty) ...[
                    Text(
                      hospital.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Contact Info Section
                  _buildSectionTitle(context, 'Contact Information'),
                  const SizedBox(height: 12),
                  
                  // Address
                  _buildInfoRow(
                    context,
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    title: 'Address',
                    value: '${hospital.address}, ${hospital.city}',
                    onTap: hospital.latitude != null && hospital.longitude != null
                        ? () => _openMaps(context)
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  _buildInfoRow(
                    context,
                    icon: Icons.phone,
                    iconColor: Colors.green,
                    title: 'Phone',
                    value: hospital.phone,
                    onTap: () => _callPhone(context),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  if (hospital.email.isNotEmpty)
                    _buildInfoRow(
                      context,
                      icon: Icons.email,
                      iconColor: Colors.blue,
                      title: 'Email',
                      value: hospital.email,
                      onTap: () => _sendEmail(context),
                    ),
                  const SizedBox(height: 24),

                  // Specialties Section
                  if (hospital.specialties.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Specialties & Departments'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hospital.specialties.map((specialty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            specialty,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Working Hours Section
                  if (hospital.workingHours.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Working Hours'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: hospital.workingHours.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  entry.value,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callPhone(context),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call Now'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Redirecting to find doctors at this hospital...'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, color: Colors.white),
                          label: const Text('Find Doctors', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _callPhone(BuildContext context) {
    // Copy phone number to clipboard and show message
    Clipboard.setData(ClipboardData(text: hospital.phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Phone number ${hospital.phone} copied!')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _sendEmail(BuildContext context) {
    Clipboard.setData(ClipboardData(text: hospital.email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Email ${hospital.email} copied!')),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openMaps(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.map, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('Opening maps...')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
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

// Notifications Bottom Sheet with Blood Requests
class _NotificationsSheet extends StatelessWidget {
  final List<AppointmentModel> appointments;
  
  const _NotificationsSheet({required this.appointments});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
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
            'Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Blood Request Notifications
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: currentUserId)
                .where('type', whereIn: ['blood_request', 'blood_request_refused', 'appointment_pdf'])
                .snapshots(),
            builder: (context, snapshot) {
              // Handle errors
              if (snapshot.hasError) {
                debugPrint('Notification query error: ${snapshot.error}');
              }
              
              // Sort client-side to avoid needing composite index
              final allNotifications = (snapshot.data?.docs ?? [])
                ..sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime); // Descending order
                });
              
              // Separate blood requests, refusals, and appointment pdf notifications
              final pdfNotifications = allNotifications
                  .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'appointment_pdf')
                  .take(5)
                  .toList();
              final bloodRequests = allNotifications
                  .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'blood_request')
                  .take(5)
                  .toList();
              final refusals = allNotifications
                  .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'blood_request_refused')
                  .take(5)
                  .toList();
              
              if (pdfNotifications.isEmpty && bloodRequests.isEmpty && refusals.isEmpty && appointments.isEmpty) {
                return Center(
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
                          'No notifications',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Appointment PDF Receipts Section
                      if (pdfNotifications.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Appointment PDF Slips',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...pdfNotifications.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _AppointmentPdfCard(
                            data: data,
                            docId: doc.id,
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Refusal Notifications Section
                      if (refusals.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Responses',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...refusals.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _BloodRefusalCard(
                            data: data,
                            docId: doc.id,
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                      
                      // Blood Requests Section
                      if (bloodRequests.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.bloodtype, color: Colors.red[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Blood Requests',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[600],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...bloodRequests.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _BloodRequestCard(
                            data: data,
                            docId: doc.id,
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                      
                      // Appointments Section
                      if (appointments.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Upcoming Appointments',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...appointments.map((appointment) {
                          final isToday = appointment.date.day == DateTime.now().day &&
                              appointment.date.month == DateTime.now().month &&
                              appointment.date.year == DateTime.now().year;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                                          Flexible(
                                            child: Text(
                                              appointment.doctorName,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
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
                                        '${appointment.specialization} • ${appointment.timeSlot}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Blood Request Card Widget
class _BloodRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _BloodRequestCard({
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final requesterName = data['requesterName'] as String? ?? 'Someone';
    final requesterPhone = data['requesterPhone'] as String? ?? '';
    final bloodGroup = data['bloodGroup'] as String? ?? '';
    final isRead = data['read'] as bool? ?? false;
    final createdAt = data['createdAt'] as Timestamp?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bloodtype,
                  color: Colors.red[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Request - $bloodGroup',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatTime(createdAt.toDate()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$requesterName needs $bloodGroup blood.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (requesterPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  requesterPhone,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _refuseToDonate(context),
                    icon: Icon(Icons.close, size: 16, color: Colors.grey[700]),
                    label: Text(
                      'Refuse',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: requesterPhone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Phone number copied! Contact the requester.'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      // Mark as read
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(docId)
                          .update({'read': true});
                    },
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text(
                      'Help',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _refuseToDonate(BuildContext context) async {
    final requesterId = data['requesterId'] as String?;
    final bloodGroup = data['bloodGroup'] as String? ?? '';
    
    if (requesterId == null) return;

    // Get current user's name
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final donorName = userDoc.data()?['name'] ?? 'A donor';

    // Send refusal notification to the requester
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': requesterId,
      'type': 'blood_request_refused',
      'title': 'Blood Request Declined',
      'message': '$donorName is unable to donate $bloodGroup blood at this time.',
      'donorName': donorName,
      'bloodGroup': bloodGroup,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Delete or mark original notification as handled
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Response sent to requester.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Blood Refusal Card Widget - shown to requester when donor declines
class _BloodRefusalCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _BloodRefusalCard({
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final donorName = data['donorName'] as String? ?? 'A donor';
    final bloodGroup = data['bloodGroup'] as String? ?? '';
    final isRead = data['read'] as bool? ?? false;
    final createdAt = data['createdAt'] as Timestamp?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_off,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Declined',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatTime(createdAt.toDate()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$donorName is unable to donate $bloodGroup blood at this time.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Mark as read and dismiss
                FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(docId)
                    .update({'read': true});
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Dismiss',
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Appointment PDF Notification Card Widget - shown in notification drawer
class _AppointmentPdfCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _AppointmentPdfCard({
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '📄 Appointment PDF Slip Ready';
    final message = data['message'] as String? ?? 'Your appointment PDF slip is ready.';
    final isRead = data['read'] as bool? ?? false;
    final doctorName = data['doctorName'] as String? ?? 'Doctor';
    final specialization = data['specialization'] as String? ?? 'General';
    final timeSlot = data['timeSlot'] as String? ?? '10:00 AM';
    final hospitalName = data['hospitalName'] as String? ?? 'City General Hospital';
    final patientName = data['patientName'] as String? ?? 'Patient';

    DateTime date = DateTime.now();
    if (data['date'] != null) {
      date = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
    }

    final appointment = AppointmentModel(
      appointmentId: data['appointmentId'] as String? ?? docId,
      doctorId: '',
      patientId: data['userId'] as String? ?? '',
      doctorName: doctorName,
      patientName: patientName,
      specialization: specialization,
      date: date,
      timeSlotId: '',
      timeSlot: timeSlot,
      hospitalName: hospitalName,
      status: AppointmentStatus.upcoming,
      consultationFee: (data['consultationFee'] as num?)?.toDouble() ?? 500.0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: Colors.blue[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                    ),
                    Text(
                      'Dr. $doctorName • $timeSlot',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(docId)
                    .update({'read': true});
                PdfGeneratorService.showPdfPreview(context, appointment);
              },
              icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
              label: const Text('View / Download PDF Slip', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

