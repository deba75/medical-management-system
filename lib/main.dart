import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/patient/home/patient_home_screen.dart';
import 'screens/patient/profile/patient_profile_screen.dart';
import 'screens/doctor/home/doctor_home_screen.dart';
import 'screens/doctor/verification/doctor_verification_screen.dart';
import 'screens/diagnostic_centre/diagnostic_centre_dashboard_screen.dart';
import 'screens/diagnostic_centre/verification/diagnostic_centre_verification_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/admin/admin_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'MediConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/patient-home': (context) => const PatientHomeScreen(),
        '/patient-profile': (context) => const PatientProfileScreen(),
        '/doctor-home': (context) => const DoctorHomeScreen(),
        '/doctor-verification': (context) => const DoctorVerificationScreen(),
        '/diagnostic-centre-home': (context) => const DiagnosticCentreDashboardScreen(),
        '/diagnostic-centre-verification': (context) => const DiagnosticCentreVerificationScreen(),
        '/admin-verification': (context) => const AdminVerificationScreen(),
      },
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final authService = ref.read(authServiceProvider);
        final userData = await authService.getUserData(user.uid);
        if (mounted) {
          if (userData?.role == UserRole.doctor) {
            Navigator.pushReplacementNamed(context, '/doctor-home');
          } else if (userData?.role == UserRole.diagnosticCentre) {
            Navigator.pushReplacementNamed(context, '/diagnostic-centre-home');
          } else if (userData?.role == UserRole.admin) {
            Navigator.pushReplacementNamed(context, '/admin-verification');
          } else {
            if (!user.emailVerified) {
              Navigator.pushReplacementNamed(context, '/email-verification');
            } else {
              Navigator.pushReplacementNamed(context, '/patient-home');
            }
          }
          return;
        }
      } catch (e) {
        debugPrint('Error checking active user session on splash: $e');
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'MediConnect',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Healthcare at your fingertips',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
