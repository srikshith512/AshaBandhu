import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/patient_model.dart';
import '../../providers/patient_provider.dart';
import '../../constants/app_colors.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({Key? key}) : super(key: key);

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  final _abhaIdController = TextEditingController();
  
  String _selectedGender = 'Female';
  String _selectedRiskLevel = 'low';
  bool _isPriority = false;
  DateTime? _nextVisitDate;
  DateTime? _ancVisitDate;
  List<String> _selectedConditions = [];
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _riskLevels = ['low', 'medium', 'high'];
  final List<String> _availableConditions = [
    'Hypertension',
    'Diabetes',
    'Pregnancy',
    'Anemia',
    'Malnutrition',
    'Tuberculosis',
    'Mental Health',
    'Child Development',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _abhaIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isNextVisit) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isNextVisit) {
          _nextVisitDate = picked;
        } else {
          _ancVisitDate = picked;
        }
      });
    }
  }

  void _scanAbhaId() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AbhaIdScannerScreen(
          onScanned: (String abhaId) {
            setState(() {
              _abhaIdController.text = abhaId;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current worker from AuthProvider
      final authProvider = context.read<AuthProvider>();
      final currentWorker = authProvider.currentWorker;

      if (currentWorker == null) {
        throw Exception('No worker is currently logged in.');
      }

      final patient = Patient(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        // Use the worker's village as the default or entered village
        village: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : currentWorker.village,
        phoneNumber: _phoneController.text.trim(),
        // This is the critical fix - assign the current worker's ID
        assignedWorker: currentWorker.workerId,
        nextVisit: _nextVisitDate,
        ancVisit: _ancVisitDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        abhaId: _abhaIdController.text.trim().isEmpty ? null : _abhaIdController.text.trim(),
        isPriority: _isPriority,
        riskLevel: _selectedRiskLevel,
        conditions: _selectedConditions.isEmpty ? null : _selectedConditions,
        syncStatus: 'local',
        version: 1,
      );
      
      // Debug print to see what's being sent
      debugPrint('📦 Creating patient object: ${patient.toJson()}');

      await context.read<PatientProvider>().addPatient(patient);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding patient: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePatient,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 16),
            
            _buildTextFormField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter patient name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 0 || age > 120) {
                        return 'Please enter valid age';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    value: _selectedGender,
                    label: 'Gender',
                    icon: Icons.wc,
                    items: _genderOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTextFormField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                if (value.trim().length != 10) {
                  return 'Please enter valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildTextFormField(
              controller: _villageController,
              label: 'Village/Area',
              icon: Icons.location_on,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter village/area';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // ABHA ID Section
            _buildSectionHeader('ABHA ID (Optional)'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _abhaIdController,
                    label: 'ABHA ID',
                    icon: Icons.qr_code,
                    readOnly: false,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _scanAbhaId,
                  icon: const Icon(Icons.qr_code_scanner),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Health Information Section
            _buildSectionHeader('Health Information'),
            const SizedBox(height: 16),
            
            _buildDropdownField(
              value: _selectedRiskLevel,
              label: 'Risk Level',
              icon: Icons.warning,
              items: _riskLevels,
              onChanged: (value) {
                setState(() {
                  _selectedRiskLevel = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            _buildSwitchTile(
              title: 'Priority Patient',
              subtitle: 'Mark as high priority for immediate attention',
              value: _isPriority,
              onChanged: (value) {
                setState(() {
                  _isPriority = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Conditions Section
            _buildSectionHeader('Medical Conditions'),
            const SizedBox(height: 8),
            _buildConditionsChips(),
            const SizedBox(height: 24),
            
            // Visit Scheduling Section
            _buildSectionHeader('Visit Scheduling'),
            const SizedBox(height: 16),
            
            _buildDateField(
              label: 'Next Visit Date',
              icon: Icons.calendar_today,
              date: _nextVisitDate,
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),
            
            if (_selectedGender == 'Female')
              _buildDateField(
                label: 'ANC Visit Date (if pregnant)',
                icon: Icons.pregnant_woman,
                date: _ancVisitDate,
                onTap: () => _selectDate(context, false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Select date',
          style: TextStyle(
            color: date != null ? AppColors.textPrimary : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildConditionsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableConditions.map((condition) {
        final isSelected = _selectedConditions.contains(condition);
        return FilterChip(
          label: Text(condition),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedConditions.add(condition);
              } else {
                _selectedConditions.remove(condition);
              }
            });
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }
}

class AbhaIdScannerScreen extends StatefulWidget {
  final Function(String) onScanned;

  const AbhaIdScannerScreen({Key? key, required this.onScanned}) : super(key: key);

  @override
  State<AbhaIdScannerScreen> createState() => _AbhaIdScannerScreenState();
}

class _AbhaIdScannerScreenState extends State<AbhaIdScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan ABHA ID'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flash_on),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.cameraswitch),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              widget.onScanned(barcode.rawValue!);
              break;
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
