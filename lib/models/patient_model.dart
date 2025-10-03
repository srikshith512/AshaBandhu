import 'package:hive/hive.dart';

part 'patient_model.g.dart';

@HiveType(typeId: 0)
class Patient extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int age;

  @HiveField(3)
  String gender;

  @HiveField(4)
  String village;

  @HiveField(5)
  String phoneNumber;

  @HiveField(6)
  DateTime? lastVisit;

  @HiveField(7)
  DateTime? nextVisit;

  @HiveField(8)
  DateTime? ancVisit;

  @HiveField(9)
  String syncStatus; // 'synced', 'pending', 'local'

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  @HiveField(12)
  String? abhaId;

  @HiveField(13)
  bool isPriority;

  @HiveField(14)
  String? riskLevel; // 'high', 'medium', 'low'

  @HiveField(15)
  Map<String, dynamic>? vitals;

  @HiveField(16)
  List<String>? conditions;

  @HiveField(17)
  String? assignedWorker;

  @HiveField(18)
  int version; // For conflict resolution

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.village,
    required this.phoneNumber,
    this.lastVisit,
    this.nextVisit,
    this.ancVisit,
    this.syncStatus = 'local',
    required this.createdAt,
    required this.updatedAt,
    this.abhaId,
    this.isPriority = false,
    this.riskLevel,
    this.vitals,
    this.conditions,
    this.assignedWorker,
    this.version = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'village': village,
      'phoneNumber': phoneNumber,
      'lastVisit': lastVisit?.toIso8601String(),
      'nextVisit': nextVisit?.toIso8601String(),
      'ancVisit': ancVisit?.toIso8601String(),
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'abhaId': abhaId,
      'isPriority': isPriority,
      'riskLevel': riskLevel,
      'vitals': vitals,
      'conditions': conditions,
      'assignedWorker': assignedWorker,
      'version': version,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      village: json['village'],
      phoneNumber: json['phoneNumber'],
      lastVisit: json['lastVisit'] != null ? DateTime.parse(json['lastVisit']) : null,
      nextVisit: json['nextVisit'] != null ? DateTime.parse(json['nextVisit']) : null,
      ancVisit: json['ancVisit'] != null ? DateTime.parse(json['ancVisit']) : null,
      syncStatus: json['syncStatus'] ?? 'local',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      abhaId: json['abhaId'],
      isPriority: json['isPriority'] ?? false,
      riskLevel: json['riskLevel'],
      vitals: json['vitals'] != null ? Map<String, dynamic>.from(json['vitals']) : null,
      conditions: json['conditions'] != null ? List<String>.from(json['conditions']) : null,
      assignedWorker: json['assignedWorker'],
      version: json['version'] ?? 1,
    );
  }

  bool get isOverdue {
    if (nextVisit == null) return false;
    return DateTime.now().isAfter(nextVisit!);
  }

  String get syncStatusLabel {
    switch (syncStatus) {
      case 'synced':
        return 'Synced';
      case 'pending':
        return 'Pending';
      case 'local':
        return 'Local';
      default:
        return 'Unknown';
    }
  }
}
