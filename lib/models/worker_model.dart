import 'package:hive/hive.dart';

part 'worker_model.g.dart';

@HiveType(typeId: 1)
class Worker extends HiveObject {
  @HiveField(0)
  String workerId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String village;

  @HiveField(3)
  String role; // 'asha' or 'phc'

  @HiveField(4)
  String pin;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? phoneNumber;

  @HiveField(7)
  bool isActive;

  Worker({
    required this.workerId,
    required this.name,
    required this.village,
    required this.role,
    required this.pin,
    required this.createdAt,
    this.phoneNumber,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'name': name,
      'village': village,
      'role': role,
      'pin': pin,
      'createdAt': createdAt.toIso8601String(),
      'phoneNumber': phoneNumber,
      'isActive': isActive,
    };
  }

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      workerId: json['workerId'],
      name: json['name'],
      village: json['village'],
      role: json['role'],
      pin: json['pin'],
      createdAt: DateTime.parse(json['createdAt']),
      phoneNumber: json['phoneNumber'],
      isActive: json['isActive'] ?? true,
    );
  }
}
