import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/sync_provider.dart';
import 'services/hive_service.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/asha/asha_home_screen.dart';
import 'screens/phc/phc_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive database
  await HiveService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: MaterialApp(
        title: 'ASHA Bandhu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppInitializer(),
        routes: {
          '/home': (context) => const AppInitializer(),
          '/login': (context) => const LoginScreen(role: 'asha'),
          '/register': (context) => const RegistrationScreen(role: 'asha'),
          '/asha': (context) => const AshaHomeScreen(),
          '/phc': (context) => const PhcDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle parameterized routes
          if (settings.name == '/login') {
            final role = settings.arguments as String? ?? 'asha';
            return MaterialPageRoute(
              builder: (context) => LoginScreen(role: role),
            );
          }
          if (settings.name == '/register') {
            final role = settings.arguments as String? ?? 'asha';
            return MaterialPageRoute(
              builder: (context) => RegistrationScreen(role: role),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
    
    if (authProvider.isAuthenticated) {
      final patientProvider = context.read<PatientProvider>();
      await patientProvider.loadPatients(
        assignedWorker: authProvider.currentRole == 'asha' 
            ? authProvider.currentWorker?.workerId 
            : null,
      );
    }
    
    setState(() => _isInitializing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return const RoleSelectionScreen();
    }

    // Navigate based on role
    if (authProvider.currentRole == 'asha') {
      return const AshaHomeScreen();
    } else {
      return const PhcDashboardScreen();
    }
  }
}
