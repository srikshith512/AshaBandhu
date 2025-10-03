class DataConflict {
  final String id;
  final String patientId;
  final String patientName;
  final String field;
  final ConflictValue value1;
  final ConflictValue value2;
  final DateTime createdAt;
  bool isResolved;

  DataConflict({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.field,
    required this.value1,
    required this.value2,
    required this.createdAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'field': field,
      'value1': value1.toJson(),
      'value2': value2.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
    };
  }

  factory DataConflict.fromJson(Map<String, dynamic> json) {
    return DataConflict(
      id: json['id'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      field: json['field'],
      value1: ConflictValue.fromJson(json['value1']),
      value2: ConflictValue.fromJson(json['value2']),
      createdAt: DateTime.parse(json['createdAt']),
      isResolved: json['isResolved'] ?? false,
    );
  }
}

class ConflictValue {
  final String workerId;
  final String value;
  final DateTime timestamp;

  ConflictValue({
    required this.workerId,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'workerId': workerId,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConflictValue.fromJson(Map<String, dynamic> json) {
    return ConflictValue(
      workerId: json['workerId'],
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
