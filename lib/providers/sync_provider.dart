import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import 'patient_provider.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncProvider with ChangeNotifier {
  SyncStatus _syncStatus = SyncStatus.idle;
  bool _isOnline = false;
  DateTime? _lastSyncTime;
  String? _errorMessage;

  SyncStatus get syncStatus => _syncStatus;
  bool get isOnline => _isOnline;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;

  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();

  SyncProvider() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  Future<void> syncData(PatientProvider patientProvider) async {
    if (!_isOnline) {
      _errorMessage = 'No internet connection';
      notifyListeners();
      return;
    }

    if (_syncStatus == SyncStatus.syncing) {
      return; // Already syncing
    }

    _syncStatus = SyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get pending patients
      final pendingPatients = patientProvider.pendingPatients;
      final localPatients = patientProvider.localPatients;
      
      final patientsToSync = [...pendingPatients, ...localPatients];

      if (patientsToSync.isEmpty) {
        _syncStatus = SyncStatus.success;
        _lastSyncTime = DateTime.now();
        notifyListeners();
        return;
      }

      // Simulate API sync (replace with actual API call)
      await Future.delayed(const Duration(seconds: 2));
      
      // In production, call actual API
      // final response = await _apiService.syncPatients(patientsToSync);
      
      // Mark patients as synced
      final syncedIds = patientsToSync.map((p) => p.id).toList();
      await patientProvider.markAsSynced(syncedIds);

      _syncStatus = SyncStatus.success;
      _lastSyncTime = DateTime.now();
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _errorMessage = 'Sync failed: $e';
      debugPrint(_errorMessage);
    } finally {
      notifyListeners();
    }
  }

  Future<void> downloadData(PatientProvider patientProvider) async {
    if (!_isOnline) {
      _errorMessage = 'No internet connection';
      notifyListeners();
      return;
    }

    try {
      // In production, fetch data from server
      // final patients = await _apiService.fetchPatients();
      // Update local database with server data
      
      _lastSyncTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Download failed: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }
}
