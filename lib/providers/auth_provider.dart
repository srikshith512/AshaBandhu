import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/worker_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  Worker? _currentWorker;
  bool _isAuthenticated = false;
  final ApiService _apiService = ApiService();

  Worker? get currentWorker => _currentWorker;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentRole => _currentWorker?.role;

  Future<void> initialize() async {
    // Check if user is already logged in
    final box = await Hive.openBox('auth');
    final workerId = box.get('currentWorkerId');
    
    if (workerId != null) {
      final workersBox = await Hive.openBox<Worker>('workers');
      _currentWorker = workersBox.get(workerId);
      _isAuthenticated = _currentWorker != null;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String workerId,
    required String password,
    required String name,
    required String village,
    required String pin,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      // Try to register with the backend API first
      final response = await _apiService.register(
        workerId: workerId,
        password: password,
        name: name,
        village: village,
        role: role,
        pin: pin,
        phoneNumber: phoneNumber,
      );

      if (response['success'] == true) {
        final workerData = response['data']['worker'];
        final token = response['data']['token'];
        
        debugPrint('✅ Registration successful, token received: ${token?.substring(0, 20)}...');
        
        final worker = Worker(
          workerId: workerData['worker_id'],
          name: workerData['name'],
          village: workerData['village'],
          role: workerData['role'],
          pin: pin, // Store locally for offline access
          phoneNumber: workerData['phone_number'],
          createdAt: DateTime.parse(workerData['created_at']),
        );

        // Store worker locally for offline access
        final workersBox = await Hive.openBox<Worker>('workers');
        await workersBox.put(workerId, worker);

        // Store auth info
        final authBox = await Hive.openBox('auth');
        await authBox.put('currentWorkerId', workerId);

        _currentWorker = worker;
        _isAuthenticated = true;
        
        notifyListeners();
        debugPrint('✅ Registration complete - online mode enabled');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      
      // Fallback to local registration if API fails
      try {
        final workersBox = await Hive.openBox<Worker>('workers');
        
        // Check if worker ID already exists locally
        if (workersBox.containsKey(workerId)) {
          return false;
        }

        final worker = Worker(
          workerId: workerId,
          name: name,
          village: village,
          role: role,
          pin: pin,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
        );

        await workersBox.put(workerId, worker);

        // Store auth info locally
        final authBox = await Hive.openBox('auth');
        await authBox.put('pwd_$workerId', password);
        await authBox.put('currentWorkerId', workerId);

        _currentWorker = worker;
        _isAuthenticated = true;
        
        notifyListeners();
        return true;
      } catch (localError) {
        debugPrint('Local registration error: $localError');
        return false;
      }
    }
  }

  Future<bool> login({
    required String workerId,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting API login for: $workerId');
      
      // Try to login with the backend API first
      final response = await _apiService.login(
        workerId: workerId,
        password: password,
      );

      debugPrint('📡 API login response: ${response['success']}');

      if (response['success'] == true) {
        final workerData = response['data']['worker'];
        final token = response['data']['token'];
        
        debugPrint('✅ API login successful, token received: ${token?.substring(0, 20)}...');
        
        final worker = Worker(
          workerId: workerData['worker_id'],
          name: workerData['name'],
          village: workerData['village'],
          role: workerData['role'],
          pin: '', // PIN not returned from API for security
          phoneNumber: workerData['phone_number'],
          createdAt: DateTime.parse(workerData['created_at']),
        );

        // Store worker locally for offline access
        final workersBox = await Hive.openBox<Worker>('workers');
        await workersBox.put(workerId, worker);

        // Store auth info
        final authBox = await Hive.openBox('auth');
        await authBox.put('currentWorkerId', workerId);

        _currentWorker = worker;
        _isAuthenticated = true;
        
        notifyListeners();
        debugPrint('✅ Password login complete - online mode enabled');
        return true;
      }
      
      debugPrint('❌ API login failed: ${response['message']}');
      return false;
    } catch (e) {
      debugPrint('❌ API login error: $e');
      
      // Fallback to local login if API fails
      try {
        final workersBox = await Hive.openBox<Worker>('workers');
        final worker = workersBox.get(workerId);

        if (worker == null) {
          return false;
        }

        final authBox = await Hive.openBox('auth');
        final storedPassword = authBox.get('pwd_$workerId');

        if (storedPassword != password) {
          return false;
        }

        _currentWorker = worker;
        _isAuthenticated = true;
        await authBox.put('currentWorkerId', workerId);
        
        notifyListeners();
        return true;
      } catch (localError) {
        debugPrint('Local login error: $localError');
        return false;
      }
    }
  }

  Future<bool> loginWithPin({
    required String workerId,
    required String pin,
  }) async {
    try {
      // PIN login is offline-first, uses local Hive data
      final workersBox = await Hive.openBox<Worker>('workers');
      final worker = workersBox.get(workerId);

      if (worker == null) {
        return false;
      }

      // Verify PIN matches
      if (worker.pin != pin) {
        return false;
      }

      _currentWorker = worker;
      _isAuthenticated = true;
      
      final authBox = await Hive.openBox('auth');
      await authBox.put('currentWorkerId', workerId);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PIN login error: $e');
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (_currentWorker == null) return false;
    return _currentWorker!.pin == pin;
  }

  Future<void> logout() async {
    try {
      // Logout from API (clear token)
      await _apiService.logout();
    } catch (e) {
      debugPrint('API logout error: $e');
    }
    
    // Clear local auth data
    final authBox = await Hive.openBox('auth');
    await authBox.delete('currentWorkerId');
    
    _currentWorker = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateWorkerProfile({
    String? name,
    String? village,
    String? phoneNumber,
  }) async {
    if (_currentWorker == null) return;

    final workersBox = await Hive.openBox<Worker>('workers');
    final updatedWorker = Worker(
      workerId: _currentWorker!.workerId,
      name: name ?? _currentWorker!.name,
      village: village ?? _currentWorker!.village,
      role: _currentWorker!.role,
      pin: _currentWorker!.pin,
      createdAt: _currentWorker!.createdAt,
      phoneNumber: phoneNumber ?? _currentWorker!.phoneNumber,
      isActive: _currentWorker!.isActive,
    );

    await workersBox.put(_currentWorker!.workerId, updatedWorker);
    _currentWorker = updatedWorker;
    notifyListeners();
  }
}
