import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_model.dart';
import '../models/worker_model.dart';

class HiveService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(PatientAdapter());
    Hive.registerAdapter(WorkerAdapter());
    
    // Open boxes
    await Hive.openBox<Patient>('patients');
    await Hive.openBox<Worker>('workers');
    await Hive.openBox('auth');
    await Hive.openBox('settings');
  }

  static Future<void> clearAllData() async {
    await Hive.box<Patient>('patients').clear();
    await Hive.box('settings').clear();
    // Keep auth and workers boxes for login
  }

  static Future<void> closeAll() async {
    await Hive.close();
  }
}
