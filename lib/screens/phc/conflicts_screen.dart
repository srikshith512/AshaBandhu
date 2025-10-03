import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/conflict_model.dart';

class ConflictsScreen extends StatefulWidget {
  const ConflictsScreen({super.key});

  @override
  State<ConflictsScreen> createState() => _ConflictsScreenState();
}

class _ConflictsScreenState extends State<ConflictsScreen> {
  // Real conflicts will be loaded from backend/database
  // For now, showing empty state as conflicts are rare
  final List<DataConflict> _conflicts = [];

  @override
  Widget build(BuildContext context) {
    final pendingConflicts = _conflicts.where((c) => !c.isResolved).toList();

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conflict Resolution',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            
            // Pending Conflicts Header
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pending Conflicts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (pendingConflicts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No pending conflicts'),
                ),
              )
            else
              ...pendingConflicts.map(
                (conflict) => _ConflictCard(
                  conflict: conflict,
                  onResolve: (value) {
                    setState(() {
                      conflict.isResolved = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conflict resolved')),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final DataConflict conflict;
  final Function(ConflictValue) onResolve;

  const _ConflictCard({
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conflict.patientName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Field: ${conflict.field}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Conflict Values
            Row(
              children: [
                Expanded(
                  child: _ValueOption(
                    workerLabel: 'Worker 1: ${conflict.value1.workerId}',
                    value: conflict.value1.value,
                    timestamp: conflict.value1.timestamp,
                    onChoose: () => onResolve(conflict.value1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueOption(
                    workerLabel: 'Worker 2: ${conflict.value2.workerId}',
                    value: conflict.value2.value,
                    timestamp: conflict.value2.timestamp,
                    onChoose: () => onResolve(conflict.value2),
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueOption extends StatelessWidget {
  final String workerLabel;
  final String value;
  final DateTime timestamp;
  final VoidCallback onChoose;
  final bool isSecondary;

  const _ValueOption({
    required this.workerLabel,
    required this.value,
    required this.timestamp,
    required this.onChoose,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isSecondary ? AppColors.primaryLight : AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSecondary ? AppColors.primaryLight : AppColors.primary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workerLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${timestamp.day}/${timestamp.month}/${timestamp.year}, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onChoose,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSecondary ? AppColors.primaryLight : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text('Choose Value ${isSecondary ? '2' : '1'}'),
            ),
          ),
        ],
      ),
    );
  }
}
