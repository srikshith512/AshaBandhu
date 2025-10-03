import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/sync_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final syncProvider = context.watch<SyncProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Section
            _SettingsSection(
              icon: Icons.language,
              title: 'Language',
              children: [
                const Text('Select Language', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('English'),
                      Icon(Icons.arrow_drop_down, color: AppColors.iconSecondary),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Connectivity Section
            _SettingsSection(
              icon: Icons.sync,
              title: 'Connectivity',
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status:', style: TextStyle(fontSize: 14)),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: syncProvider.isOnline ? AppColors.success : AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          syncProvider.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: syncProvider.isOnline ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: syncProvider.syncStatus == SyncStatus.syncing
                        ? null
                        : () {
                            syncProvider.syncData(patientProvider);
                          },
                    icon: syncProvider.syncStatus == SyncStatus.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      syncProvider.syncStatus == SyncStatus.syncing
                          ? 'Syncing...'
                          : 'Sync Data Now',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (syncProvider.lastSyncTime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last synced: ${DateFormat('MMM d, h:mm a').format(syncProvider.lastSyncTime!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Data Storage Section
            _SettingsSection(
              icon: Icons.storage,
              title: 'Data Storage',
              children: [
                _DataStorageRow(
                  label: 'Total Patient Records:',
                  value: patientProvider.patients.length.toString(),
                ),
                const SizedBox(height: 8),
                _DataStorageRow(
                  label: 'Synced Records:',
                  value: patientProvider.syncedPatients.length.toString(),
                ),
                const SizedBox(height: 8),
                _DataStorageRow(
                  label: 'Pending Sync:',
                  value: patientProvider.pendingPatients.length.toString(),
                ),
                const SizedBox(height: 8),
                _DataStorageRow(
                  label: 'Local Only Records:',
                  value: patientProvider.localPatients.length.toString(),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context, authProvider);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
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
              authProvider.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DataStorageRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataStorageRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
