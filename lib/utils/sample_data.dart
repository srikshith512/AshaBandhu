import 'package:uuid/uuid.dart';
import '../models/patient_model.dart';

class SampleData {
  static List<Patient> generateSamplePatients() {
    const uuid = Uuid();
    final now = DateTime.now();

    return [
      Patient(
        id: uuid.v4(),
        name: 'Sunita Devi',
        age: 28,
        gender: 'female',
        village: 'Rampur',
        phoneNumber: '9876543210',
        lastVisit: DateTime(2024, 9, 15),
        nextVisit: DateTime(2024, 10, 15),
        ancVisit: DateTime(2024, 10, 15),
        syncStatus: 'synced',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 2)),
        assignedWorker: 'ASHA001',
        isPriority: false,
        version: 3,
      ),
      Patient(
        id: uuid.v4(),
        name: 'Rajesh Kumar',
        age: 45,
        gender: 'male',
        village: 'Maheshpur',
        phoneNumber: '9876543211',
        lastVisit: DateTime(2024, 9, 20),
        nextVisit: DateTime(2024, 11, 20),
        syncStatus: 'pending',
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 1)),
        assignedWorker: 'ASHA001',
        isPriority: false,
        version: 2,
      ),
      Patient(
        id: uuid.v4(),
        name: 'Rajesh',
        age: 52,
        gender: 'male',
        village: 'Maheshpur',
        phoneNumber: '9876543212',
        syncStatus: 'local',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        assignedWorker: 'ASHA001',
        isPriority: false,
        version: 1,
      ),
    ];
  }
}
