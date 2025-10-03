import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/patient_provider.dart';
import '../../models/patient_model.dart';
import '../../widgets/sync_status_badge.dart';

class PhcPatientsScreen extends StatefulWidget {
  const PhcPatientsScreen({super.key});

  @override
  State<PhcPatientsScreen> createState() => _PhcPatientsScreenState();
}

class _PhcPatientsScreenState extends State<PhcPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final patientProvider = context.read<PatientProvider>();
    setState(() {
      _filteredPatients = patientProvider.searchPatients(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final patients = _searchController.text.isEmpty
        ? patientProvider.patients
        : _filteredPatients;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Asha Bandhu', style: TextStyle(color: Colors.white, fontSize: 20)),
            Text('PHC Dashboard', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or village...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Patient List
          Expanded(
            child: patients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.iconSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No patients found'
                              : 'No matching patients',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return _PatientCard(patient: patient);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${patient.age} years • ${patient.gender}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SyncStatusBadge(status: patient.syncStatus),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Contact Info
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.iconSecondary),
                const SizedBox(width: 4),
                Text(patient.village, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            
            const SizedBox(height: 6),
            
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.iconSecondary),
                const SizedBox(width: 4),
                Text(patient.phoneNumber, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            
            // Visit Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Visit:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      patient.lastVisit != null
                          ? DateFormat('M/d/yyyy').format(patient.lastVisit!)
                          : 'Never',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Visit:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      patient.nextVisit != null
                          ? DateFormat('M/d/yyyy').format(patient.nextVisit!)
                          : '-',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // View patient details
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
