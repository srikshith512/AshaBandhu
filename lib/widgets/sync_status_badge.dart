import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SyncStatusBadge extends StatelessWidget {
  final String status;

  const SyncStatusBadge({
    super.key,
    required this.status,
  });

  Color get _backgroundColor {
    switch (status.toLowerCase()) {
      case 'synced':
        return AppColors.synced;
      case 'pending':
        return AppColors.pending;
      case 'local':
        return AppColors.local;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'synced':
        return 'Synced';
      case 'pending':
        return 'Pending';
      case 'local':
        return 'Local';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _backgroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
