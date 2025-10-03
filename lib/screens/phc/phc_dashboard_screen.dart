import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/stat_card.dart';
import 'phc_patients_screen.dart';
import 'conflicts_screen.dart';
import 'phc_alerts_screen.dart';
import 'phc_settings_screen.dart';
import '../../widgets/app_drawer.dart';

class PhcDashboardScreen extends StatefulWidget {
  const PhcDashboardScreen({super.key});

  @override
  State<PhcDashboardScreen> createState() => _PhcDashboardScreenState();
}

class _PhcDashboardScreenState extends State<PhcDashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    _DashboardTab(onNavigate: (index) => setState(() => _selectedIndex = index)),
    const PhcPatientsScreen(),
    const ConflictsScreen(),
    const PhcAlertsScreen(),
    const PhcSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ASHA Bandhu',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'PHC Dashboard',
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
            icon: Icon(Icons.report_problem_outlined),
            activeIcon: Icon(Icons.report_problem),
            label: 'Conflicts',
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

class _DashboardTab extends StatefulWidget {
  final Function(int) onNavigate;
  
  const _DashboardTab({required this.onNavigate});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final patientProvider = context.read<PatientProvider>();
    await patientProvider.loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();

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
              // Title
              Text(
                'PHC Dashboard',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Overview & Analytics',
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
                      title: 'Priority Cases',
                      value: patientProvider.priorityPatients.length.toString(),
                      icon: Icons.warning_amber_outlined,
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
                      title: 'Pending Conflicts',
                      value: '0', // Real conflicts will be implemented with backend conflict detection
                      icon: Icons.warning_outlined,
                      iconColor: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Synced Today',
                      value: patientProvider.syncedPatients.length.toString(),
                      icon: Icons.cloud_done_outlined,
                      iconColor: AppColors.success,
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
                label: 'Resolve Conflicts',
                icon: Icons.warning_amber_outlined,
                badge: null, // No conflicts currently
                onTap: () {
                  widget.onNavigate(2);
                },
              ),
              
              const SizedBox(height: 12),
              
              _QuickActionButton(
                label: 'View All',
                icon: Icons.list,
                onTap: () {
                  widget.onNavigate(1);
                },
              ),
              
              const SizedBox(height: 32),
              
              // System Integrations
              Text(
                'System Integrations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _IntegrationRow(
                      label: 'ABDM Integration',
                      status: 'Connected',
                      isConnected: true,
                    ),
                    const SizedBox(height: 12),
                    _IntegrationRow(
                      label: 'FHIR Compliance',
                      status: 'Active',
                      isConnected: true,
                    ),
                    const SizedBox(height: 12),
                    _IntegrationRow(
                      label: 'Data Sync',
                      status: 'Running',
                      isConnected: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.iconPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  final String label;
  final String status;
  final bool isConnected;

  const _IntegrationRow({
    required this.label,
    required this.status,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isConnected ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                color: isConnected ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
