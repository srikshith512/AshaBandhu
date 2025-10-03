import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../models/worker_model.dart';

class ApiService {
  // Backend server URL - change this to your server's IP/domain
  static const String baseUrl = 'http://10.0.2.2:3000';

  // API endpoints
  static const String syncEndpoint = '/api/sync';
  static const String patientsEndpoint = '/api/patients';
  static const String authEndpoint = '/api/auth';
  static const String workersEndpoint = '/api/workers';

  // Get stored auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Authentication methods
  Future<Map<String, dynamic>> register({
    required String workerId,
    required String password,
    required String name,
    required String village,
    required String role,
    required String pin,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authEndpoint/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workerId': workerId,
          'password': password,
          'name': name,
          'village': village,
          'role': role,
          'pin': pin,
          'phoneNumber': phoneNumber,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Store auth token
        if (data['data']['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['data']['token']);
        }
        return data;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String workerId,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authEndpoint/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workerId': workerId,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Store auth token
        if (data['data'] != null && data['data']['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['data']['token']);
          debugPrint('✅ Auth token stored: ${data['data']['token'].substring(0, 20)}...');
        } else {
          debugPrint('⚠️ No token in response: $data');
        }
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<bool> verifyPin({
    required String workerId,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authEndpoint/verify-pin'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'workerId': workerId,
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data']['valid'] ?? false;
      } else {
        throw Exception(data['message'] ?? 'PIN verification failed');
      }
    } catch (e) {
      throw Exception('PIN verification error: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Patient sync methods
  Future<Map<String, dynamic>> syncPatients(List<Patient> patients) async {
    try {
      final patientsData = patients
          .map((p) => {
                'id': p.id,
                'action': p.syncStatus == 'local' ? 'create' : 'update',
                'data': {
                  'name': p.name,
                  'age': p.age,
                  'gender': p.gender,
                  'phone': p.phoneNumber,
                  'village': p.village,
                  'abhaId': p.abhaId,
                  'riskLevel': p.riskLevel,
                  'isPriority': p.isPriority,
                  'medicalConditions': p.conditions,
                  'nextVisitDate': p.nextVisit?.toIso8601String(),
                  'ancVisitDate': p.ancVisit?.toIso8601String(),
                  'assignedWorker': p.assignedWorker,
                }
              })
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl$syncEndpoint/patients'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'patients': patientsData,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to sync patients');
      }
    } catch (e) {
      throw Exception('Sync error: $e');
    }
  }

  Future<List<Patient>> fetchPatients({String? assignedWorker}) async {
    try {
      final uri = assignedWorker != null
          ? Uri.parse(
              '$baseUrl$patientsEndpoint?assignedWorker=$assignedWorker')
          : Uri.parse('$baseUrl$patientsEndpoint');

      final response = await http.get(
        uri,
        headers: await _getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> patientsJson = data['data']['patients'];
        return patientsJson.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch patients');
      }
    } catch (e) {
      throw Exception('Fetch error: $e');
    }
  }

  Future<Patient> createPatient(Patient patient) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$patientsEndpoint'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'name': patient.name,
          'age': patient.age,
          'gender': patient.gender,
          'phone': patient.phoneNumber,
          'village': patient.village,
          'abhaId': patient.abhaId,
          'riskLevel': patient.riskLevel,
          'isPriority': patient.isPriority,
          'medicalConditions': patient.conditions,
          'nextVisitDate': patient.nextVisit?.toIso8601String(),
          'ancVisitDate': patient.ancVisit?.toIso8601String(),
          'assignedWorker': patient.assignedWorker,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return Patient.fromJson(data['data']['patient']);
      } else {
        throw Exception(data['message'] ?? 'Failed to create patient');
      }
    } catch (e) {
      throw Exception('Create patient error: $e');
    }
  }

  Future<Patient> updatePatient(Patient patient) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$patientsEndpoint/${patient.id}'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'name': patient.name,
          'age': patient.age,
          'gender': patient.gender,
          'phone': patient.phoneNumber,
          'village': patient.village,
          'abhaId': patient.abhaId,
          'riskLevel': patient.riskLevel,
          'isPriority': patient.isPriority,
          'medicalConditions': patient.conditions,
          'nextVisitDate': patient.nextVisit?.toIso8601String(),
          'ancVisitDate': patient.ancVisit?.toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Patient.fromJson(data['data']['patient']);
      } else {
        throw Exception(data['message'] ?? 'Failed to update patient');
      }
    } catch (e) {
      throw Exception('Update patient error: $e');
    }
  }

  Future<void> deletePatient(String patientId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$patientsEndpoint/$patientId'),
        headers: await _getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Failed to delete patient');
      }
    } catch (e) {
      throw Exception('Delete patient error: $e');
    }
  }

  Future<List<Patient>> fetchSyncUpdates({DateTime? lastSync}) async {
    try {
      final uri = lastSync != null
          ? Uri.parse(
              '$baseUrl$syncEndpoint/patients?lastSync=${lastSync.toIso8601String()}')
          : Uri.parse('$baseUrl$syncEndpoint/patients');

      final response = await http.get(
        uri,
        headers: await _getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> patientsJson = data['data']['patients'];
        return patientsJson.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch sync updates');
      }
    } catch (e) {
      throw Exception('Sync fetch error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyAbhaId(String abhaId) async {
    try {
      // For now, return a mock response since ABHA API integration is not implemented
      // In production, this would connect to the actual ABHA verification service
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay

      return {
        'success': true,
        'data': {
          'valid': abhaId.length == 14 && RegExp(r'^\d{14}$').hasMatch(abhaId),
          'abhaId': abhaId,
        }
      };
    } catch (e) {
      throw Exception('ABHA verification error: $e');
    }
  }
}
