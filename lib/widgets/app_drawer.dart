import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/sync_provider.dart';
import '../screens/auth/role_selection_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final syncProvider = context.watch<SyncProvider>();
    final worker = authProvider.currentWorker;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        worker?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Name
                    Text(
                      worker?.name ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Role and Village
                    Text(
                      '${worker?.role.toUpperCase() ?? 'USER'} • ${worker?.village ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Worker ID
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: ${worker?.workerId ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                
                // Patients
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('My Patients'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${patientProvider.patients.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to patients tab
                  },
                ),
                
                const Divider(),
                
                // Sync Status
                ListTile(
                  leading: Icon(
                    syncProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: syncProvider.isOnline ? AppColors.success : AppColors.error,
                  ),
                  title: Text(syncProvider.isOnline ? 'Online' : 'Offline'),
                  subtitle: Text(
                    syncProvider.isOnline 
                        ? 'Data synced successfully'
                        : 'Working offline',
                  ),
                  trailing: syncProvider.syncStatus.name == 'syncing'
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: () {
                    if (syncProvider.isOnline && syncProvider.syncStatus.name != 'syncing') {
                      syncProvider.syncData(patientProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing data...')),
                      );
                    }
                  },
                ),
                
                // Pending Sync
                if (patientProvider.pendingPatients.isNotEmpty || patientProvider.localPatients.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.sync_problem, color: AppColors.warning),
                    title: const Text('Pending Sync'),
                    subtitle: Text('${patientProvider.pendingPatients.length + patientProvider.localPatients.length} items'),
                    onTap: () async {
                      Navigator.pop(context);
                      
                      // Check if user has auth token (password login)
                      final prefs = await SharedPreferences.getInstance();
                      final hasToken = prefs.getString('auth_token') != null;
                      
                      Map<String, dynamic> result;
                      
                      if (!hasToken) {
                        // PIN login - ask for credentials to sync
                        final credentials = await _showSyncCredentialsDialog(context);
                        if (credentials == null) return; // User canceled
                        
                        // Show loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 16),
                                Text('Authenticating and syncing...'),
                              ],
                            ),
                            duration: Duration(seconds: 30),
                          ),
                        );
                        
                        result = await patientProvider.syncWithCredentials(
                          workerId: credentials['workerId']!,
                          password: credentials['password']!,
                        );
                      } else {
                        // Password login - direct sync
                        // Show loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 16),
                                Text('Syncing pending patients...'),
                              ],
                            ),
                            duration: Duration(seconds: 30),
                          ),
                        );
                        
                        result = await patientProvider.syncPendingPatients();
                      }
                      
                      // Hide loading and show result
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['success'] 
                                ? 'Synced successfully! ${result['total'] ?? result['synced']} patients loaded'
                                : 'Sync failed: ${result['message']}',
                          ),
                          backgroundColor: result['success'] ? AppColors.success : AppColors.error,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  ),
                
                const Divider(),
                
                // Settings
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon!')),
                    );
                  },
                ),
                
                // Help & Support
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpDialog(context);
                  },
                ),
                
                // About
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          
          // Logout
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPendingSyncDialog(BuildContext context) {
    final patientProvider = context.read<PatientProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Sync'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${patientProvider.pendingPatients.length} patients need to be synced.'),
            const SizedBox(height: 8),
            const Text('These changes will be uploaded when you have internet connection.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _showSyncCredentialsDialog(BuildContext context) async {
    final workerIdController = TextEditingController();
    final passwordController = TextEditingController();
    
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Credentials to Sync'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You logged in with PIN (offline mode). To sync with server, please enter your password:'),
            const SizedBox(height: 16),
            TextField(
              controller: workerIdController,
              decoration: const InputDecoration(
                labelText: 'Worker ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (workerIdController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'workerId': workerIdController.text,
                  'password': passwordController.text,
                });
              }
            },
            child: const Text('Sync'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For technical support, contact:'),
            SizedBox(height: 8),
            Text('📞 Phone: 1800-XXX-XXXX'),
            Text('📧 Email: support@ashabandhu.gov.in'),
            SizedBox(height: 16),
            Text('App Version: 1.0.0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ASHA Bandhu'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ASHA Bandhu is a digital health platform designed to support ASHA workers and PHC staff in providing better healthcare services.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Patient registration and management'),
            Text('• Offline-first data storage'),
            Text('• Visit scheduling and reminders'),
            Text('• Health data tracking'),
            Text('• Sync with central database'),
            SizedBox(height: 16),
            Text('Developed for the Ministry of Health & Family Welfare, Government of India.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
