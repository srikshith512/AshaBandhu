import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/stat_card.dart';
import 'patients_list_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';
import 'add_patient_screen.dart';
import 'qr_scanner_screen.dart';
import '../../widgets/app_drawer.dart';

class AshaHomeScreen extends StatefulWidget {
  const AshaHomeScreen({super.key});

  @override
  State<AshaHomeScreen> createState() => _AshaHomeScreenState();
}

class _AshaHomeScreenState extends State<AshaHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const PatientsListScreen(),
    const AlertsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final syncProvider = context.watch<SyncProvider>();
    final worker = authProvider.currentWorker;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASHA Bandhu',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              worker?.name ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              syncProvider.isOnline ? Icons.wifi : Icons.wifi_off,
              color: syncProvider.isOnline ? Colors.white : Colors.white70,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    syncProvider.isOnline 
                        ? 'Connected to internet' 
                        : 'No internet connection',
                  ),
                  backgroundColor: syncProvider.isOnline 
                      ? AppColors.success 
                      : AppColors.error,
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPatientScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final patientProvider = context.read<PatientProvider>();
    await patientProvider.loadPatients(
      assignedWorker: authProvider.currentWorker?.workerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final worker = authProvider.currentWorker;

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome, ${worker?.name.split(' ')[0] ?? 'User'}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Today\'s Overview',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 24),
              
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Patients',
                      value: patientProvider.patients.length.toString(),
                      icon: Icons.people_outline,
                      iconColor: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Upcoming Visits',
                      value: patientProvider.upcomingVisitsCount.toString(),
                      icon: Icons.calendar_today_outlined,
                      iconColor: AppColors.warning,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Pending Sync',
                      value: patientProvider.pendingPatients.length.toString(),
                      icon: Icons.sync_problem_outlined,
                      iconColor: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Priority Cases',
                      value: patientProvider.priorityPatients.length.toString(),
                      icon: Icons.warning_amber_outlined,
                      iconColor: AppColors.error,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: 16),
              
              _QuickActionButton(
                label: 'Add New Patient',
                icon: Icons.person_add,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPatientScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _QuickActionButton(
                label: 'Scan QR / Aadhaar',
                icon: Icons.qr_code_scanner,
                color: Colors.white,
                textColor: AppColors.textPrimary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRScannerScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _QuickActionButton(
                label: 'View Reminders',
                icon: null,
                color: Colors.white,
                textColor: AppColors.textPrimary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AlertsScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full activity list
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              if (patientProvider.patients.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No recent activity'),
                  ),
                )
              else
                ...patientProvider.patients.take(3).map(
                  (patient) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(patient.name),
                      subtitle: Text('Last visit: ${patient.lastVisit != null ? _formatDate(patient.lastVisit!) : 'Never'}'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.iconSecondary,
                      ),
                      onTap: () {
                        // Navigate to patient details
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    this.icon,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor ?? Colors.white,
          elevation: color == Colors.white ? 0 : 2,
          side: color == Colors.white
              ? const BorderSide(color: AppColors.border)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
