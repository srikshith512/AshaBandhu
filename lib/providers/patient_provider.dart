import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/patient_model.dart';
import '../services/api_service.dart';

class PatientProvider with ChangeNotifier {
  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Patient> get syncedPatients => _patients.where((p) => p.syncStatus == 'synced').toList();
  List<Patient> get pendingPatients => _patients.where((p) => p.syncStatus == 'pending').toList();
  List<Patient> get localPatients => _patients.where((p) => p.syncStatus == 'local').toList();
  List<Patient> get priorityPatients => _patients.where((p) => p.isPriority).toList();
  List<Patient> get overduePatients => _patients.where((p) => p.isOverdue).toList();

  int get upcomingVisitsCount {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _patients.where((p) => 
      p.nextVisit != null && 
      p.nextVisit!.isAfter(now) && 
      p.nextVisit!.isBefore(nextWeek)
    ).length;
  }

  Future<void> loadPatients({String? assignedWorker}) async {
    _isLoading = true;
    _errorMessage = null;
    // Don't notify immediately to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final box = await Hive.openBox<Patient>('patients');
      
      // Always load local data first (works offline)
      if (assignedWorker != null) {
        _patients = box.values
            .where((p) => p.assignedWorker == assignedWorker)
            .toList();
      } else {
        _patients = box.values.toList();
      }
      
      // Try to fetch from API and merge (only if we have auth token - online mode)
      try {
        // Check if we have an auth token (means user logged in with password, not PIN)
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        final hasToken = token != null;
        
        debugPrint('🔍 Token check: ${hasToken ? "Found token: ${token!.substring(0, 20)}..." : "No token found - offline mode"}');
        
        if (hasToken) {
          final apiPatients = await _apiService.fetchPatients(assignedWorker: assignedWorker);
          
          // Merge API patients with local data (preserve local/pending patients)
          final localPendingIds = _patients
              .where((p) => p.syncStatus == 'local' || p.syncStatus == 'pending')
              .map((p) => p.id)
              .toSet();
          
          // Update synced patients from API, but keep local/pending ones
          for (final apiPatient in apiPatients) {
            if (!localPendingIds.contains(apiPatient.id)) {
              await box.put(apiPatient.id, apiPatient);
            }
          }
          
          // Reload all patients after merge
          if (assignedWorker != null) {
            _patients = box.values
                .where((p) => p.assignedWorker == assignedWorker)
                .toList();
          } else {
            _patients = box.values.toList();
          }
          
          debugPrint('✅ Loaded ${_patients.length} patients (${apiPatients.length} from API)');
        } else {
          debugPrint('📴 Offline mode (PIN login) - using local data only');
        }
      } catch (apiError) {
        debugPrint('⚠️ API fetch failed, using local data only: $apiError');
        // Already loaded local data above, so just continue
      }
      
      // Sort by updated date (most recent first)
      _patients.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      _errorMessage = 'Failed to load patients: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPatient(Patient patient) async {
    try {
      final box = await Hive.openBox<Patient>('patients');
      
      // Ensure new patients are marked as 'local' (not yet synced)
      patient.syncStatus = 'local';
      patient.updatedAt = DateTime.now();
      
      await box.put(patient.id, patient);
      _patients.insert(0, patient);
      notifyListeners();
      
      // Try to sync immediately if online
      _trySyncPatient(patient);
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add patient: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }
  
  Future<void> _trySyncPatient(Patient patient) async {
    try {
      final syncedPatient = await _apiService.createPatient(patient);
      
      // Update local patient with synced status
      final box = await Hive.openBox<Patient>('patients');
      syncedPatient.syncStatus = 'synced';
      await box.put(syncedPatient.id, syncedPatient);
      
      // Update in memory list
      final index = _patients.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        _patients[index] = syncedPatient;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Auto-sync failed: $e - Patient will sync later');
      // Patient remains as 'local' and will sync later
    }
  }

  Future<bool> updatePatient(Patient patient) async {
    try {
      final box = await Hive.openBox<Patient>('patients');
      patient.updatedAt = DateTime.now();
      patient.version += 1;
      patient.syncStatus = 'pending';
      
      await box.put(patient.id, patient);
      
      final index = _patients.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        _patients[index] = patient;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update patient: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  Future<bool> deletePatient(String patientId) async {
    try {
      final box = await Hive.openBox<Patient>('patients');
      await box.delete(patientId);
      _patients.removeWhere((p) => p.id == patientId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete patient: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }
  
  Future<Map<String, dynamic>> syncPendingPatients() async {
    try {
      final box = await Hive.openBox<Patient>('patients');
      final pendingToSync = _patients.where(
        (p) => p.syncStatus == 'local' || p.syncStatus == 'pending'
      ).toList();
      
      int syncedCount = 0;
      int failedCount = 0;
      
      debugPrint('🔄 Starting sync: ${pendingToSync.length} pending patients');
      
      // If there are pending patients, sync them first
      if (pendingToSync.isNotEmpty) {
        try {
          final result = await _apiService.syncPatients(pendingToSync);
          
          if (result['success'] == true) {
            final syncedResults = result['data']['results'] as List;
            
            for (final syncResult in syncedResults) {
              if (syncResult['status'] == 'success') {
                final patientId = syncResult['id'];
                final patient = _patients.firstWhere((p) => p.id == patientId);
                patient.syncStatus = 'synced';
                await box.put(patientId, patient);
                syncedCount++;
              } else {
                failedCount++;
              }
            }
            debugPrint('✅ Uploaded ${syncedCount} patients, ${failedCount} failed');
          } else {
            failedCount = pendingToSync.length;
            debugPrint('⚠️ Upload failed for all ${failedCount} patients');
          }
        } catch (uploadError) {
          debugPrint('⚠️ Upload error (will still try to fetch): $uploadError');
          failedCount = pendingToSync.length;
        }
      }
      
      // ALWAYS try to fetch ALL patients from server (even if upload failed)
      // This ensures we get data from other workers
      try {
        debugPrint('🔄 Fetching all patients from server...');
        final apiPatients = await _apiService.fetchPatients();
        
        debugPrint('📥 Received ${apiPatients.length} patients from server');
        
        // Merge with local data (preserve any still-pending patients)
        final stillPendingIds = _patients
            .where((p) => p.syncStatus == 'local' || p.syncStatus == 'pending')
            .map((p) => p.id)
            .toSet();
        
        // Store all API patients
        for (final apiPatient in apiPatients) {
          if (!stillPendingIds.contains(apiPatient.id)) {
            apiPatient.syncStatus = 'synced';
            await box.put(apiPatient.id, apiPatient);
          }
        }
        
        // Reload all patients from Hive
        _patients = box.values.toList();
        _patients.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        notifyListeners();
        
        debugPrint('✅ Sync complete: ${syncedCount} uploaded, ${apiPatients.length} from server, ${_patients.length} total in DB');
        
        return {
          'success': true,
          'message': 'Synced successfully! ${apiPatients.length} patients loaded',
          'synced': syncedCount,
          'failed': failedCount,
          'total': apiPatients.length,
        };
      } catch (fetchError) {
        debugPrint('❌ Could not fetch patients from server: $fetchError');
        
        // If we at least uploaded some, that's partial success
        if (syncedCount > 0) {
          _patients = box.values.toList();
          _patients.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          notifyListeners();
          
          return {
            'success': true,
            'message': 'Uploaded $syncedCount patients (could not fetch from server)',
            'synced': syncedCount,
            'failed': failedCount,
          };
        }
        
        // Complete failure
        return {
          'success': false,
          'message': 'Sync failed: $fetchError',
          'synced': 0,
          'failed': pendingToSync.length,
        };
      }
    } catch (e) {
      debugPrint('❌ Sync error: $e');
      return {
        'success': false,
        'message': 'Sync error: $e',
        'synced': 0,
        'failed': pendingPatients.length,
      };
    }
  }

  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } on StateError catch (e) {
      debugPrint('Failed to find patient by id: $e');
      return null;
    }
  }

  List<Patient> searchPatients(String query) {
    if (query.isEmpty) return _patients;
    
    final lowerQuery = query.toLowerCase();
    return _patients.where((p) =>
      p.name.toLowerCase().contains(lowerQuery) ||
      p.village.toLowerCase().contains(lowerQuery) ||
      p.phoneNumber.contains(query)
    ).toList();
  }

  Future<void> markAsSynced(List<String> patientIds) async {
    try {
      final box = await Hive.openBox<Patient>('patients');
      
      for (final id in patientIds) {
        final patient = box.get(id);
        if (patient != null) {
          patient.syncStatus = 'synced';
          await box.put(id, patient);
          
          final index = _patients.indexWhere((p) => p.id == id);
          if (index != -1) {
            _patients[index] = patient;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark as synced: $e');
    }
  }

  Future<String> generatePatientId() async {
    return const Uuid().v4();
  }
  
  // Sync with credentials (for PIN users who want to sync)
  Future<Map<String, dynamic>> syncWithCredentials({
    required String workerId,
    required String password,
  }) async {
    try {
      // First, login to get token
      debugPrint('🔐 Logging in to get auth token for sync...');
      final loginResult = await _apiService.login(
        workerId: workerId,
        password: password,
      );
      
      if (loginResult['success'] != true) {
        return {
          'success': false,
          'message': 'Login failed: ${loginResult['message']}',
          'synced': 0,
          'failed': 0,
        };
      }
      
      debugPrint('✅ Login successful, proceeding with sync...');
      
      // Now sync with the token
      return await syncPendingPatients();
    } catch (e) {
      debugPrint('❌ Sync with credentials error: $e');
      return {
        'success': false,
        'message': 'Authentication failed: $e',
        'synced': 0,
        'failed': pendingPatients.length,
      };
    }
  }
}
